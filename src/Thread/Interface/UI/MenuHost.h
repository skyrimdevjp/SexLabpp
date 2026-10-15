#pragma once

// In-process ImGui host for the scene UI.
//
// Replaces the dependency on an external menu framework DLL: Dear ImGui (MIT) is compiled into this
// plugin and rendered from a hook on the game's swap chain. The namespaces below provide the small API
// surface the UI code (Thread/Interface) is written against and map it onto plain Dear ImGui.

#include <imgui.h>

#include <atomic>
#include <utility>

// ImGui API as used by the UI code. Types, enums and most functions are Dear ImGui's own; only the
// accessors that the UI code expects in pointer form and the object helpers are adapted here.
namespace ImGuiMCP
{
    using namespace ::ImGui;

    using ::ImDrawFlags;
    using ::ImDrawList;
    using ::ImFont;
    using ::ImGuiIO;
    using ::ImGuiKey;
    using ::ImGuiSelectableFlags;
    using ::ImGuiStyle;
    using ::ImGuiViewport;
    using ::ImU32;
    using ::ImVec2;
    using ::ImVec4;

    using enum ::ImDrawFlags_;
    using enum ::ImGuiChildFlags_;
    using enum ::ImGuiCol_;
    using enum ::ImGuiColorEditFlags_;
    using enum ::ImGuiCond_;
    using enum ::ImGuiHoveredFlags_;
    using enum ::ImGuiInputTextFlags_;
    using enum ::ImGuiKey;
    using enum ::ImGuiMouseButton_;
    using enum ::ImGuiSelectableFlags_;
    using enum ::ImGuiStyleVar_;
    using enum ::ImGuiTreeNodeFlags_;
    using enum ::ImGuiWindowFlags_;

    inline ImGuiIO* GetIO() { return &::ImGui::GetIO(); }
    inline ImGuiStyle* GetStyle() { return &::ImGui::GetStyle(); }

    // Draw list helpers: free functions taking the draw list as first argument.
    // Parameters mirror the ImDrawList members so braced arguments ({ x, y }) keep working
    namespace ImDrawListManager
    {
        inline void AddLine(ImDrawList* a_dl, const ImVec2& a_p1, const ImVec2& a_p2, ImU32 a_col, float a_thickness = 1.0f)
        {
            a_dl->AddLine(a_p1, a_p2, a_col, a_thickness);
        }
        inline void AddRect(ImDrawList* a_dl, const ImVec2& a_min, const ImVec2& a_max, ImU32 a_col, float a_rounding = 0.0f, ImDrawFlags a_flags = 0, float a_thickness = 1.0f)
        {
            a_dl->AddRect(a_min, a_max, a_col, a_rounding, a_flags, a_thickness);
        }
        inline void AddRectFilled(ImDrawList* a_dl, const ImVec2& a_min, const ImVec2& a_max, ImU32 a_col, float a_rounding = 0.0f, ImDrawFlags a_flags = 0)
        {
            a_dl->AddRectFilled(a_min, a_max, a_col, a_rounding, a_flags);
        }
        inline void AddRectFilledMultiColor(ImDrawList* a_dl, const ImVec2& a_min, const ImVec2& a_max, ImU32 a_upperLeft, ImU32 a_upperRight, ImU32 a_lowerRight, ImU32 a_lowerLeft)
        {
            a_dl->AddRectFilledMultiColor(a_min, a_max, a_upperLeft, a_upperRight, a_lowerRight, a_lowerLeft);
        }
        inline void AddTriangleFilled(ImDrawList* a_dl, const ImVec2& a_p1, const ImVec2& a_p2, const ImVec2& a_p3, ImU32 a_col)
        {
            a_dl->AddTriangleFilled(a_p1, a_p2, a_p3, a_col);
        }
        inline void AddCircleFilled(ImDrawList* a_dl, const ImVec2& a_center, float a_radius, ImU32 a_col, int a_segments = 0)
        {
            a_dl->AddCircleFilled(a_center, a_radius, a_col, a_segments);
        }
        inline void AddConcavePolyFilled(ImDrawList* a_dl, const ImVec2* a_points, int a_count, ImU32 a_col)
        {
            a_dl->AddConcavePolyFilled(a_points, a_count, a_col);
        }
        inline void AddText(ImDrawList* a_dl, const ImVec2& a_pos, ImU32 a_col, const char* a_begin, const char* a_end = nullptr)
        {
            a_dl->AddText(a_pos, a_col, a_begin, a_end);
        }
        inline void AddText(ImDrawList* a_dl, ImFont* a_font, float a_size, const ImVec2& a_pos, ImU32 a_col, const char* a_begin, const char* a_end = nullptr, float a_wrapWidth = 0.0f, const ImVec4* a_clip = nullptr)
        {
            a_dl->AddText(a_font, a_size, a_pos, a_col, a_begin, a_end, a_wrapWidth, a_clip);
        }
        inline void PushClipRect(ImDrawList* a_dl, const ImVec2& a_min, const ImVec2& a_max, bool a_intersect = false)
        {
            a_dl->PushClipRect(a_min, a_max, a_intersect);
        }
        inline void PopClipRect(ImDrawList* a_dl) { a_dl->PopClipRect(); }
        inline void ChannelsSplit(ImDrawList* a_dl, int a_count) { a_dl->ChannelsSplit(a_count); }
        inline void ChannelsMerge(ImDrawList* a_dl) { a_dl->ChannelsMerge(); }
        inline void ChannelsSetCurrent(ImDrawList* a_dl, int a_channel) { a_dl->ChannelsSetCurrent(a_channel); }
    }

    namespace ImFontManger
    {
        inline ImVec2 CalcTextSizeA(ImFont* a_font, float a_size, float a_maxWidth, float a_wrapWidth, const char* a_begin, const char* a_end = nullptr, const char** a_remaining = nullptr)
        {
            return a_font->CalcTextSizeA(a_size, a_maxWidth, a_wrapWidth, a_begin, a_end, a_remaining);
        }
    }

    namespace ImGuiViewportManager
    {
        inline ImVec2 GetCenter(const ImGuiViewport* a_viewport) { return a_viewport->GetCenter(); }
    }
}

namespace FontAwesome
{
    // Counterpart of SKSEMenuFramework::PushFont
    inline void Pop() { ::ImGui::PopFont(); }
}

// Window registry of the in-process host
namespace SKSEMenuFramework
{
    namespace Model
    {
        using RenderFunction = void(__stdcall*)();

        struct WindowInterface
        {
            std::atomic<bool> IsOpen{ false };
            std::atomic<bool> BlockUserInput{ false };
        };
    }

    // The host is part of this plugin, so it is always available
    inline bool IsInstalled() { return true; }

    // Register a render callback; the callback is invoked every frame while the window is open.
    // The returned handle stays valid for the lifetime of the process
    Model::WindowInterface* AddWindow(Model::RenderFunction a_renderer, bool a_blocksInput);

    // Push a font registered under the given name (file name without extension).
    // Falls back to the default font if the name is unknown, so PushFont/Pop stay balanced
    void PushFont(const char* a_name);
}

namespace Thread::Interface::UI::MenuHost
{
    // Hook the swap chain and the input event source. Call once the renderer exists (kDataLoaded)
    void Install();
}
