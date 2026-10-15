#include "Hooks.h"

#include "FaceAnimator.h"
#include "Thread.h"

namespace Thread::Hooks
{
    namespace
    {
        struct FrameUpdateHook
        {
            static void Install()
            {
                auto& trampoline = SKSE::GetTrampoline();
                const auto address = RELOCATION_ID(35565, 36564).address();
                const auto offset = OFFSET(0x748, 0xC26);

                original = trampoline.write_call<5>(address + offset, Thunk);
                logger::info("Installed frame hook");
            }

            static void Thunk()
            {
                static REL::Relocation<float*> deltaTime{ RELOCATION_ID(523660, 410199) };
                Instance::UpdateAnimations(*deltaTime);
                FaceAnimator::Update(Util::IsGamePausedOrFrozen() ? 0.0f : *deltaTime);
                original();
            }

            static inline REL::Relocation<decltype(Thunk)> original;
        };

        struct DrawWeaponHook
        {
            static void Install()
            {
                REL::Relocation<std::uintptr_t> vtable{ RE::VTABLE_PlayerCharacter[0] };
                constexpr std::size_t slot = 0xA6;

                original = vtable.write_vfunc(slot, Thunk);
                logger::info("Installed player draw weapon hook");
            }

			// This is called when either a mod, or the player tries to unsheathe their weapon
            static void Thunk(RE::PlayerCharacter* a_player, bool a_draw)
            {
                if (!a_draw || !blockDraw.load(std::memory_order_relaxed)) {
                    original(a_player, a_draw);
                }
            }

            static inline std::atomic_bool blockDraw{ false };
            static inline REL::Relocation<decltype(Thunk)> original;
        };
    }

    void Install()
    {
        FrameUpdateHook::Install();
        DrawWeaponHook::Install();
    }

    void SetWeaponDrawBlocked(bool a_blocked) noexcept
    {
        DrawWeaponHook::blockDraw.store(a_blocked, std::memory_order_relaxed);
    }
}
