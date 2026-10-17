#include "Compat/XxsCoreLog.h"

#include "Compat/XxsBridge.h"
#include "Registry/Util/Scale.h"
#include "UserData/Settings.h"

namespace Compat
{
    void LogXxsCoreStatus()
    {
        auto* handler = RE::TESDataHandler::GetSingleton();
        const bool xxsLoaded = handler && handler->LookupModByName("xxsUtility.esm"sv) != nullptr;

        logger::info("[xxs Core] Phase A: xxsUtility.esm {}",
            xxsLoaded ? "loaded" : "NOT loaded");
        logger::info("[xxs Core] SexLabpp bridge: {} (IsChild/ATF use xxsIsChild when esm loaded)",
            xxsLoaded ? "active" : "inactive (no esm)");

        if (!xxsLoaded) {
            logger::warn("[xxs Core] Install xxsUtility-Core-SexLabpp with xxsUtility.esm from the full xxsUtility 2020.3 archive.");
            return;
        }

        const auto* player = RE::PlayerCharacter::GetSingleton();
        if (!player) {
            logger::warn("[xxs Core] PlayerCharacter not available at log time.");
            return;
        }

        const auto scale = Registry::Scale::GetSingleton()->GetScale(const_cast<RE::Actor*>(player->As<RE::Actor>()));
        const auto* actor = player->As<RE::Actor>();
        logger::info("[xxs Core] Player {:X}: bridge xxsChild={} engine IsChild={} Registry scale={:.3f}",
            player->GetFormID(),
            Compat::IsXxsChild(const_cast<RE::Actor*>(actor), true),
            player->IsChild(),
            scale);
    }
}
