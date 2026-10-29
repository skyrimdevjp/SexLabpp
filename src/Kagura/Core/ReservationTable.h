#pragma once

#include "Kagura/Core/Types.h"

#include <chrono>
#include <optional>
#include <vector>

namespace Kagura::Core
{
    // v3 §9.3: 互換枠 15 と Actor 占有。P1 S1。ゲームスレッドから呼ぶ想定。
    class ReservationTable
    {
      public:
        static ReservationTable& GetSingleton();

        void ResetForLoad();

        // 互換 NewThread: Actor 未定で枠だけ取る。空きがなければ kInvalidCompatThreadId。
        CompatThreadId TryAcquireCompatSlot(SceneHandle scene, std::uint32_t generation, RequestId request);

        void ReleaseCompatSlot(CompatThreadId tid);

        // AddActor 相当: 即時検証は呼び出し側。ここは占有のみ。成功 false = 既に予約済み等。
        bool TryReserveActor(RE::Actor* actor, SceneHandle scene, std::uint32_t generation, EntryKind entry,
            CompatThreadId compatThreadId);

        void ReleaseActor(RE::FormID actorFormId);

        void ReleaseScene(SceneHandle scene, std::uint32_t generation);

        std::optional<ActorReservation> FindActor(RE::FormID actorFormId) const;

        bool IsActorReservedByOther(RE::FormID actorFormId, SceneHandle scene, std::uint32_t generation) const;

        void TickExpirations();

      private:
        ReservationTable() = default;

        static std::chrono::milliseconds ReservationTimeout();

        std::array<CompatSlot, kCompatSlotCount> _compatSlots{};
        std::vector<ActorReservation> _actors;
    };
}
