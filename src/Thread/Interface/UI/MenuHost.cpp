#include "MenuHost.h"

#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <d3d11.h>
#include <dxgi.h>

#include <imgui_impl_dx11.h>

#include <chrono>
#include <functional>
#include <mutex>

// Overview
//  - Rendering: the game's swap chain Present() is hooked through its vtable. Each frame, if any registered
//    window is open, an ImGui frame is built from the open windows' render callbacks and drawn onto the
//    back buffer before the original Present() runs.
//  - Input: InputEvents from BSInputDeviceManager are translated into ImGui IO events. Keyboard and text
//    input are forwarded while any window is open; mouse input only while a window blocks user input.
//    Blocking windows also disable the game's controls through ControlMap and show ImGui's own cursor.
//  - Fonts: the body font and named fonts (used through SKSEMenuFramework::PushFont) are loaded from
//    Data/SKSE/SexLab/Fonts. Missing fonts fall back to the default font.

namespace Thread::Interface::UI::MenuHost
{
    namespace
    {
        using WindowInterface = SKSEMenuFramework::Model::WindowInterface;
        using RenderFunction = SKSEMenuFramework::Model::RenderFunction;
        using PresentFunc = HRESULT(__stdcall*)(IDXGISwapChain*, UINT, UINT);

        constexpr auto kFontDirectory = "Data\\SKSE\\SexLab\\Fonts"sv;
        constexpr auto kBodyFontFile = "ui.ttf"sv;
        constexpr float kFontSize = 26.0f;  // UI code scales text down via SetWindowFontScale
        constexpr std::size_t kPresentIndex = 8;

        // Controls disabled while a window blocks user input
        constexpr auto kBlockedControls = std::to_underlying(RE::UserEvents::USER_EVENT_FLAG::kMovement) |
                                          std::to_underlying(RE::UserEvents::USER_EVENT_FLAG::kLooking) |
                                          std::to_underlying(RE::UserEvents::USER_EVENT_FLAG::kActivate) |
                                          std::to_underlying(RE::UserEvents::USER_EVENT_FLAG::kMenu) |
                                          std::to_underlying(RE::UserEvents::USER_EVENT_FLAG::kPOVSwitch) |
                                          std::to_underlying(RE::UserEvents::USER_EVENT_FLAG::kFighting) |
                                          std::to_underlying(RE::UserEvents::USER_EVENT_FLAG::kSneaking) |
                                          std::to_underlying(RE::UserEvents::USER_EVENT_FLAG::kWheelZoom) |
                                          std::to_underlying(RE::UserEvents::USER_EVENT_FLAG::kJumping);

        struct RegisteredWindow
        {
            RenderFunction render;
            WindowInterface* handle;
        };

        // --- Windows

        std::mutex windowLock;
        std::vector<RegisteredWindow> windows;

        // --- Renderer state (render thread only)

        PresentFunc originalPresent{ nullptr };
        bool initialized{ false };
        bool failed{ false };
        ID3D11Device* device{ nullptr };
        ID3D11DeviceContext* context{ nullptr };
        ID3D11RenderTargetView* backBufferView{ nullptr };
        ID3D11Texture2D* backBufferViewSource{ nullptr };  // identity only, not owned
        float displayWidth{ 0.0f };
        float displayHeight{ 0.0f };
        std::chrono::steady_clock::time_point lastFrame{};
        std::unordered_map<std::string, ImFont*> namedFonts;

        // --- Shared state between input and render

        std::atomic<bool> anyWindowOpen{ false };
        std::atomic<bool> inputBlocked{ false };
        std::mutex inputLock;
        std::vector<std::function<void(ImGuiIO&)>> pendingInput;
        float mouseX{ 0.0f };
        float mouseY{ 0.0f };

        // --- Control blocking (main thread only, via task interface)

        bool controlsBlocked{ false };
        std::uint32_t controlsDisabledByUs{ 0 };

        void QueueInput(std::function<void(ImGuiIO&)> a_event)
        {
            std::scoped_lock lk{ inputLock };
            pendingInput.push_back(std::move(a_event));
        }

        void SetControlsBlocked(bool a_block)
        {
            if (controlsBlocked == a_block)
                return;
            const auto controlMap = RE::ControlMap::GetSingleton();
            if (!controlMap)
                return;
            using UEFlag = RE::UserEvents::USER_EVENT_FLAG;
            if (a_block) {
                // Only touch controls which are currently enabled, so the restore does not override other mods
                controlsDisabledByUs = controlMap->enabledControls.underlying() & kBlockedControls;
                if (controlsDisabledByUs)
                    controlMap->ToggleControls(static_cast<UEFlag>(controlsDisabledByUs), false, false);
            } else if (controlsDisabledByUs) {
                controlMap->ToggleControls(static_cast<UEFlag>(controlsDisabledByUs), true, false);
                controlsDisabledByUs = 0;
            }
            controlsBlocked = a_block;
        }

        // --- Input translation

        // DirectInput scan code -> ImGuiKey (keys the UI uses plus common text editing keys)
        ImGuiKey TranslateKey(std::uint32_t a_scanCode)
        {
            switch (a_scanCode) {
            case 0x01: return ImGuiKey_Escape;
            case 0x0E: return ImGuiKey_Backspace;
            case 0x0F: return ImGuiKey_Tab;
            case 0x1C: return ImGuiKey_Enter;
            case 0x9C: return ImGuiKey_KeypadEnter;
            case 0x39: return ImGuiKey_Space;
            case 0x1D: return ImGuiKey_LeftCtrl;
            case 0x9D: return ImGuiKey_RightCtrl;
            case 0x2A: return ImGuiKey_LeftShift;
            case 0x36: return ImGuiKey_RightShift;
            case 0x38: return ImGuiKey_LeftAlt;
            case 0xB8: return ImGuiKey_RightAlt;
            case 0xC7: return ImGuiKey_Home;
            case 0xC8: return ImGuiKey_UpArrow;
            case 0xC9: return ImGuiKey_PageUp;
            case 0xCB: return ImGuiKey_LeftArrow;
            case 0xCD: return ImGuiKey_RightArrow;
            case 0xCF: return ImGuiKey_End;
            case 0xD0: return ImGuiKey_DownArrow;
            case 0xD1: return ImGuiKey_PageDown;
            case 0xD2: return ImGuiKey_Insert;
            case 0xD3: return ImGuiKey_Delete;
            case 0x02: return ImGuiKey_1;
            case 0x03: return ImGuiKey_2;
            case 0x04: return ImGuiKey_3;
            case 0x05: return ImGuiKey_4;
            case 0x06: return ImGuiKey_5;
            case 0x07: return ImGuiKey_6;
            case 0x08: return ImGuiKey_7;
            case 0x09: return ImGuiKey_8;
            case 0x0A: return ImGuiKey_9;
            case 0x0B: return ImGuiKey_0;
            case 0x1E: return ImGuiKey_A;
            case 0x30: return ImGuiKey_B;
            case 0x2E: return ImGuiKey_C;
            case 0x20: return ImGuiKey_D;
            case 0x12: return ImGuiKey_E;
            case 0x21: return ImGuiKey_F;
            case 0x22: return ImGuiKey_G;
            case 0x23: return ImGuiKey_H;
            case 0x17: return ImGuiKey_I;
            case 0x24: return ImGuiKey_J;
            case 0x25: return ImGuiKey_K;
            case 0x26: return ImGuiKey_L;
            case 0x32: return ImGuiKey_M;
            case 0x31: return ImGuiKey_N;
            case 0x18: return ImGuiKey_O;
            case 0x19: return ImGuiKey_P;
            case 0x10: return ImGuiKey_Q;
            case 0x13: return ImGuiKey_R;
            case 0x1F: return ImGuiKey_S;
            case 0x14: return ImGuiKey_T;
            case 0x16: return ImGuiKey_U;
            case 0x2F: return ImGuiKey_V;
            case 0x11: return ImGuiKey_W;
            case 0x2D: return ImGuiKey_X;
            case 0x15: return ImGuiKey_Y;
            case 0x2C: return ImGuiKey_Z;
            default: return ImGuiKey_None;
            }
        }

        ImGuiKey ModifierFor(ImGuiKey a_key)
        {
            switch (a_key) {
            case ImGuiKey_LeftCtrl:
            case ImGuiKey_RightCtrl:
                return ImGuiMod_Ctrl;
            case ImGuiKey_LeftShift:
            case ImGuiKey_RightShift:
                return ImGuiMod_Shift;
            case ImGuiKey_LeftAlt:
            case ImGuiKey_RightAlt:
                return ImGuiMod_Alt;
            default:
                return ImGuiKey_None;
            }
        }

        class InputSink final : public RE::BSTEventSink<RE::InputEvent*>
        {
          public:
            static InputSink* GetSingleton()
            {
                static InputSink singleton;
                return &singleton;
            }

            RE::BSEventNotifyControl ProcessEvent(RE::InputEvent* const* a_event, RE::BSTEventSource<RE::InputEvent*>*) override
            {
                if (!a_event || !anyWindowOpen.load())
                    return RE::BSEventNotifyControl::kContinue;

                const bool mouseActive = inputBlocked.load();
                for (auto event = *a_event; event; event = event->next) {
                    switch (event->GetEventType()) {
                    case RE::INPUT_EVENT_TYPE::kMouseMove:
                        if (mouseActive) {
                            const auto move = event->AsMouseMoveEvent();
                            mouseX = std::clamp(mouseX + static_cast<float>(move->mouseInputX), 0.0f, std::max(displayWidth - 1.0f, 0.0f));
                            mouseY = std::clamp(mouseY + static_cast<float>(move->mouseInputY), 0.0f, std::max(displayHeight - 1.0f, 0.0f));
                            QueueInput([x = mouseX, y = mouseY](ImGuiIO& io) { io.AddMousePosEvent(x, y); });
                        }
                        break;
                    case RE::INPUT_EVENT_TYPE::kChar:
                        {
                            const auto code = event->AsCharEvent()->keyCode;
                            if (code >= 0x20 && code != 0x7F)
                                QueueInput([code](ImGuiIO& io) { io.AddInputCharacter(code); });
                        }
                        break;
                    case RE::INPUT_EVENT_TYPE::kButton:
                        HandleButton(event->AsButtonEvent(), mouseActive);
                        break;
                    default:
                        break;
                    }
                }
                return RE::BSEventNotifyControl::kContinue;
            }

          private:
            static void HandleButton(const RE::ButtonEvent* a_button, bool a_mouseActive)
            {
                // Only state changes; held repeats carry no new information for ImGui
                if (!a_button || (!a_button->IsDown() && !a_button->IsUp()))
                    return;
                const bool pressed = a_button->IsPressed();
                const auto code = a_button->GetIDCode();
                switch (a_button->GetDevice()) {
                case RE::INPUT_DEVICE::kKeyboard:
                    {
                        const auto key = TranslateKey(code);
                        if (key == ImGuiKey_None)
                            return;
                        const auto mod = ModifierFor(key);
                        QueueInput([key, mod, pressed](ImGuiIO& io) {
                            if (mod != ImGuiKey_None)
                                io.AddKeyEvent(mod, pressed);
                            io.AddKeyEvent(key, pressed);
                        });
                    }
                    break;
                case RE::INPUT_DEVICE::kMouse:
                    if (!a_mouseActive)
                        return;
                    if (code <= 2) {
                        // 0 left, 1 right, 2 middle; ImGui uses the same order
                        QueueInput([button = static_cast<int>(code), pressed](ImGuiIO& io) { io.AddMouseButtonEvent(button, pressed); });
                    } else if (pressed && (code == RE::BSWin32MouseDevice::Key::kWheelUp || code == RE::BSWin32MouseDevice::Key::kWheelDown)) {
                        const float wheel = code == RE::BSWin32MouseDevice::Key::kWheelUp ? 1.0f : -1.0f;
                        QueueInput([wheel](ImGuiIO& io) { io.AddMouseWheelEvent(0.0f, wheel); });
                    }
                    break;
                default:
                    break;
                }
            }
        };

        // --- Rendering

        void LoadFonts(ImGuiIO& a_io)
        {
            const fs::path directory{ kFontDirectory };
            std::vector<fs::path> bodyCandidates{ directory / kBodyFontFile };
            wchar_t windowsDirectory[MAX_PATH]{};
            if (const auto length = ::GetWindowsDirectoryW(windowsDirectory, MAX_PATH); length > 0 && length < MAX_PATH) {
                bodyCandidates.push_back(fs::path{ windowsDirectory } / "Fonts" / "segoeui.ttf");
            }

            ImFont* body = nullptr;
            for (const auto& candidate : bodyCandidates) {
                std::error_code ec;
                if (!fs::exists(candidate, ec))
                    continue;
                body = a_io.Fonts->AddFontFromFileTTF(candidate.string().c_str(), kFontSize, nullptr, a_io.Fonts->GetGlyphRangesDefault());
                if (body) {
                    logger::info("MenuHost: Body font {}", candidate.string());
                    break;
                }
            }
            if (!body) {
                ImFontConfig config{};
                config.SizePixels = kFontSize;
                body = a_io.Fonts->AddFontDefault(&config);
                logger::info("MenuHost: Using built-in default font");
            }
            a_io.FontDefault = body;

            // Every other font file in the directory is registered under its file name (without extension).
            // Icon fonts use code points in the Unicode private use area
            static constexpr ImWchar kNamedFontRanges[] = { 0x0020, 0x00FF, 0xE000, 0xF8FF, 0 };
            std::error_code ec;
            if (!fs::is_directory(directory, ec))
                return;
            for (const auto& entry : fs::directory_iterator(directory, ec)) {
                const auto& path = entry.path();
                auto extension = path.extension().string();
                std::ranges::transform(extension, extension.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
                if (!entry.is_regular_file() || (extension != ".ttf" && extension != ".otf") || path.filename() == fs::path{ kBodyFontFile })
                    continue;
                if (const auto font = a_io.Fonts->AddFontFromFileTTF(path.string().c_str(), kFontSize, nullptr, kNamedFontRanges)) {
                    namedFonts[path.stem().string()] = font;
                    logger::info("MenuHost: Registered font '{}'", path.stem().string());
                }
            }
        }

        bool Initialize(IDXGISwapChain* a_swapChain)
        {
            if (FAILED(a_swapChain->GetDevice(__uuidof(ID3D11Device), reinterpret_cast<void**>(&device))) || !device) {
                logger::error("MenuHost: Unable to get D3D11 device from swap chain");
                return false;
            }
            device->GetImmediateContext(&context);

            IMGUI_CHECKVERSION();
            ImGui::CreateContext();
            auto& io = ImGui::GetIO();
            io.IniFilename = nullptr;
            io.LogFilename = nullptr;
            io.ConfigFlags |= ImGuiConfigFlags_NoMouseCursorChange;
            LoadFonts(io);
            if (!ImGui_ImplDX11_Init(device, context)) {
                logger::error("MenuHost: ImGui DX11 backend failed to initialize");
                return false;
            }
            lastFrame = std::chrono::steady_clock::now();
            logger::info("MenuHost: Initialized (ImGui {})", IMGUI_VERSION);
            return true;
        }

        bool UpdateBackBufferView(IDXGISwapChain* a_swapChain)
        {
            ID3D11Texture2D* backBuffer = nullptr;
            if (FAILED(a_swapChain->GetBuffer(0, __uuidof(ID3D11Texture2D), reinterpret_cast<void**>(&backBuffer))) || !backBuffer)
                return false;
            if (backBuffer != backBufferViewSource || !backBufferView) {
                if (backBufferView) {
                    backBufferView->Release();
                    backBufferView = nullptr;
                }
                if (FAILED(device->CreateRenderTargetView(backBuffer, nullptr, &backBufferView))) {
                    backBuffer->Release();
                    backBufferViewSource = nullptr;
                    return false;
                }
                backBufferViewSource = backBuffer;
            }
            D3D11_TEXTURE2D_DESC desc{};
            backBuffer->GetDesc(&desc);
            displayWidth = static_cast<float>(desc.Width);
            displayHeight = static_cast<float>(desc.Height);
            backBuffer->Release();
            return true;
        }

        void RenderFrame(IDXGISwapChain* a_swapChain)
        {
            std::vector<RegisteredWindow> open;
            bool block = false;
            {
                std::scoped_lock lk{ windowLock };
                for (const auto& window : windows) {
                    if (window.handle->IsOpen.load()) {
                        open.push_back(window);
                        block |= window.handle->BlockUserInput.load();
                    }
                }
            }
            anyWindowOpen = !open.empty();
            if (inputBlocked.exchange(block) != block) {
                if (block) {
                    // Start the cursor in the middle of the screen
                    mouseX = displayWidth * 0.5f;
                    mouseY = displayHeight * 0.5f;
                    QueueInput([x = mouseX, y = mouseY](ImGuiIO& io) { io.AddMousePosEvent(x, y); });
                } else {
                    QueueInput([](ImGuiIO& io) { io.AddMousePosEvent(-FLT_MAX, -FLT_MAX); });
                }
                SKSE::GetTaskInterface()->AddTask([block]() { SetControlsBlocked(block); });
            }

            const auto now = std::chrono::steady_clock::now();
            const float delta = std::chrono::duration<float>(now - lastFrame).count();
            lastFrame = now;
            if (open.empty()) {
                std::scoped_lock lk{ inputLock };
                pendingInput.clear();
                return;
            }
            if (!UpdateBackBufferView(a_swapChain))
                return;

            auto& io = ImGui::GetIO();
            io.DisplaySize = ImVec2{ displayWidth, displayHeight };
            io.DeltaTime = std::max(delta, 1.0f / 1000.0f);
            io.MouseDrawCursor = block;
            {
                std::scoped_lock lk{ inputLock };
                for (auto& event : pendingInput) {
                    event(io);
                }
                pendingInput.clear();
            }

            ImGui_ImplDX11_NewFrame();
            ImGui::NewFrame();
            for (const auto& window : open) {
                window.render();
            }
            ImGui::Render();

            ID3D11RenderTargetView* previousView = nullptr;
            ID3D11DepthStencilView* previousDepth = nullptr;
            context->OMGetRenderTargets(1, &previousView, &previousDepth);
            context->OMSetRenderTargets(1, &backBufferView, nullptr);
            ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());
            context->OMSetRenderTargets(1, &previousView, previousDepth);
            if (previousView)
                previousView->Release();
            if (previousDepth)
                previousDepth->Release();
        }

        HRESULT __stdcall Present(IDXGISwapChain* a_swapChain, UINT a_syncInterval, UINT a_flags)
        {
            if (!failed) {
                if (!initialized) {
                    initialized = Initialize(a_swapChain);
                    failed = !initialized;
                }
                if (initialized) {
                    RenderFrame(a_swapChain);
                }
            }
            return originalPresent(a_swapChain, a_syncInterval, a_flags);
        }
    }

    void Install()
    {
        static bool installed = false;
        if (installed)
            return;
        const auto renderWindow = RE::BSGraphics::Renderer::GetCurrentRenderWindow();
        const auto swapChain = renderWindow ? reinterpret_cast<IDXGISwapChain*>(renderWindow->swapChain) : nullptr;
        if (!swapChain) {
            logger::error("MenuHost: Swap chain not available, scene UI disabled");
            return;
        }
        REL::Relocation<std::uintptr_t> vtable{ *reinterpret_cast<std::uintptr_t*>(swapChain) };
        originalPresent = reinterpret_cast<PresentFunc>(vtable.write_vfunc(kPresentIndex, reinterpret_cast<std::uintptr_t>(&Present)));

        if (const auto inputManager = RE::BSInputDeviceManager::GetSingleton()) {
            inputManager->AddEventSink<RE::InputEvent*>(InputSink::GetSingleton());
        } else {
            logger::warn("MenuHost: Input device manager not available, scene UI will not receive input");
        }
        installed = true;
        logger::info("MenuHost: Installed");
    }
}

namespace SKSEMenuFramework
{
    Model::WindowInterface* AddWindow(Model::RenderFunction a_renderer, bool a_blocksInput)
    {
        if (!a_renderer)
            return nullptr;
        using namespace Thread::Interface::UI::MenuHost;
        auto handle = new Model::WindowInterface{};  // lives for the whole process, like the windows using it
        handle->BlockUserInput = a_blocksInput;
        std::scoped_lock lk{ windowLock };
        windows.push_back({ a_renderer, handle });
        return handle;
    }

    void PushFont(const char* a_name)
    {
        using namespace Thread::Interface::UI::MenuHost;
        ImFont* font = nullptr;
        if (a_name) {
            if (const auto it = namedFonts.find(a_name); it != namedFonts.end())
                font = it->second;
        }
        ::ImGui::PushFont(font ? font : ::ImGui::GetIO().FontDefault);
    }
}
