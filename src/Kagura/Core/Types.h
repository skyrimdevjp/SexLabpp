#pragma once

#include <cstdint>

namespace Kagura::Core
{
    // シーン・要求ハンドルは v3 §9.5 のとおり 31bit 正の整数を想定。0 は無効。
    using SceneHandle = std::uint32_t;
    using RequestId = std::uint32_t;
    using CompatThreadId = int;

    constexpr SceneHandle kInvalidSceneHandle = 0;
    constexpr RequestId kInvalidRequestId = 0;
    constexpr CompatThreadId kCompatSlotCount = 15;
    constexpr CompatThreadId kInvalidCompatThreadId = -1;

    enum class EntryKind : std::uint8_t
    {
        None = 0,
        CompatApi,
        NativeApi,
    };

    struct ActorReservation
    {
        RE::FormID actorFormId{ 0 };
        SceneHandle ownerScene{ kInvalidSceneHandle };
        std::uint32_t ownerGeneration{ 0 };
        EntryKind entry{ EntryKind::None };
        CompatThreadId compatThreadId{ kInvalidCompatThreadId };
    };

    struct CompatSlot
    {
        bool inUse{ false };
        SceneHandle ownerScene{ kInvalidSceneHandle };
        std::uint32_t ownerGeneration{ 0 };
        RequestId ownerRequest{ kInvalidRequestId };
        std::chrono::steady_clock::time_point expiresAt{};
    };
}
