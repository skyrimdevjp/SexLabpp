#include "Kagura/Core/ReservationTable.h"

namespace Kagura::Core
{
    ReservationTable& ReservationTable::GetSingleton()
    {
        static ReservationTable table;
        return table;
    }

    std::chrono::milliseconds ReservationTable::ReservationTimeout()
    {
        // P+ Making 30 秒。設定化は P2 以降。
        return std::chrono::seconds(30);
    }

    void ReservationTable::ResetForLoad()
    {
        _compatSlots = {};
        _actors.clear();
    }

    CompatThreadId ReservationTable::TryAcquireCompatSlot(SceneHandle scene, std::uint32_t generation, RequestId request)
    {
        const auto now = std::chrono::steady_clock::now();
        TickExpirations();

        for (CompatThreadId i = 0; i < kCompatSlotCount; ++i) {
            auto& slot = _compatSlots[static_cast<std::size_t>(i)];
            if (slot.inUse)
                continue;
            slot.inUse = true;
            slot.ownerScene = scene;
            slot.ownerGeneration = generation;
            slot.ownerRequest = request;
            slot.expiresAt = now + ReservationTimeout();
            return i;
        }
        return kInvalidCompatThreadId;
    }

    void ReservationTable::ReleaseCompatSlot(CompatThreadId tid)
    {
        if (tid < 0 || tid >= kCompatSlotCount)
            return;
        _compatSlots[static_cast<std::size_t>(tid)] = {};
    }

    bool ReservationTable::TryReserveActor(RE::Actor* actor, SceneHandle scene, std::uint32_t generation, EntryKind entry,
        CompatThreadId compatThreadId)
    {
        if (!actor)
            return false;
        const auto formId = actor->GetFormID();
        if (IsActorReservedByOther(formId, scene, generation))
            return false;

        for (auto& row : _actors) {
            if (row.actorFormId != formId)
                continue;
            row.ownerScene = scene;
            row.ownerGeneration = generation;
            row.entry = entry;
            row.compatThreadId = compatThreadId;
            return true;
        }

        _actors.push_back(ActorReservation{
            .actorFormId = formId,
            .ownerScene = scene,
            .ownerGeneration = generation,
            .entry = entry,
            .compatThreadId = compatThreadId,
        });
        return true;
    }

    void ReservationTable::ReleaseActor(RE::FormID actorFormId)
    {
        std::erase_if(_actors, [actorFormId](const ActorReservation& row) { return row.actorFormId == actorFormId; });
    }

    void ReservationTable::ReleaseScene(SceneHandle scene, std::uint32_t generation)
    {
        for (CompatThreadId i = 0; i < kCompatSlotCount; ++i) {
            auto& slot = _compatSlots[static_cast<std::size_t>(i)];
            if (slot.inUse && slot.ownerScene == scene && slot.ownerGeneration == generation)
                slot = {};
        }
        std::erase_if(_actors, [scene, generation](const ActorReservation& row) {
            return row.ownerScene == scene && row.ownerGeneration == generation;
        });
    }

    std::optional<ActorReservation> ReservationTable::FindActor(RE::FormID actorFormId) const
    {
        for (const auto& row : _actors) {
            if (row.actorFormId == actorFormId)
                return row;
        }
        return std::nullopt;
    }

    bool ReservationTable::IsActorReservedByOther(RE::FormID actorFormId, SceneHandle scene, std::uint32_t generation) const
    {
        const auto found = FindActor(actorFormId);
        if (!found)
            return false;
        return found->ownerScene != scene || found->ownerGeneration != generation;
    }

    void ReservationTable::TickExpirations()
    {
        const auto now = std::chrono::steady_clock::now();
        for (auto& slot : _compatSlots) {
            if (!slot.inUse)
                continue;
            if (now < slot.expiresAt)
                continue;
            logger::warn("Kagura: compat slot expired (scene {} gen {} request {})", slot.ownerScene, slot.ownerGeneration,
                slot.ownerRequest);
            ReleaseScene(slot.ownerScene, slot.ownerGeneration);
        }
    }
}
