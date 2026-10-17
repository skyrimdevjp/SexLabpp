#pragma once

namespace RE
{
    class Actor;
}

namespace Compat
{
    bool IsXxsUtilityLoaded();

    /// Calls xxsUtility.xxsIsChild when esm is loaded; otherwise engine IsChild + scale threshold.
    bool IsXxsChild(RE::Actor* a_actor, bool a_skipScale = true);

    /// Petite participant for ATF / scene lookup (xxs child when integrated, else legacy threshold).
    bool IsPetiteForAtf(RE::Actor* a_actor);

    void AppendAtfDisallowTags(std::vector<std::string_view>& a_tags, uint8_t a_petite_female, uint8_t a_petite_male, size_t a_actor_count);

    std::string GetSexLabActorKey(RE::Actor* a_actor);

    bool GetXxsFlag_SexlabUseMeForChildVoice();
}
