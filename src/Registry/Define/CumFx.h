#pragma once

#include "RaceKey.h"
#include "Sex.h"

// Cum FX sets
//
// Textures live in Data\Textures\SexLab\CumFx\<Type>\<Set>\1.dds, 2.dds, ...; a set name is the folder name.
// Optional config files (Data\SKSE\SexLab\CumFx\*.yaml|*.yml|*.json) group sets and restrict them to actors by
// race and sex, with weights for the random pick. Folders that no config file mentions are still available to
// every actor (one config with one profile per folder, weight 1), which is the behaviour before config files existed.
namespace Registry::CumFx
{
    enum class Type : uint8_t
    {
        Vaginal = 0,
        Anal,
        Oral,
    };
    inline constexpr size_t NUM_TYPES = magic_enum::enum_count<Type>();

    // Number of texture layers per FX type (0 = the set has no textures for that type)
    using Counts = std::array<uint8_t, NUM_TYPES>;

    // Which actors a config or profile applies to. Empty lists mean "any"
    struct ActorFilter
    {
        std::vector<RaceKey> raceKeys;                // SexLab race keys, e.g. Human, Canine
        std::vector<std::string> raceEditorIDs;       // race EditorIDs, e.g. KhajiitRace (also matched against the armor race)
        std::underlying_type_t<Sex> sexes{ 0 };       // bitmask of Registry::Sex, 0 = any

        // Read "races" and "sexes" from a config node. Unknown names are logged and ignored
        void Parse(const YAML::Node& a_node, std::string_view a_where);
        _NODISCARD bool Matches(RE::Actor* a_actor) const;
    };

    struct FxProfile
    {
        RE::BSFixedString name;   // texture folder name (returned by PickRandomFxSet)
        Counts counts{};          // layers per FX type
        std::array<bool, NUM_TYPES> countGiven{};  // count set explicitly in the config (0 then disables the type)
        ActorFilter filter;
        uint32_t weight{ 1 };     // weight inside the config, 0 = never picked
    };

    struct FxConfig
    {
        RE::BSFixedString id;
        RE::BSFixedString displayName;
        std::vector<FxProfile> profiles;
        ActorFilter filter;       // applies to every profile of the config
        uint32_t weight{ 1 };     // weight between configs, 0 = never picked
        std::string source;       // file the config was read from (empty for folders without a config)

        // Build from a config file. Throws std::exception on malformed content
        _NODISCARD static FxConfig FromYaml(const YAML::Node& a_root, const std::string& a_source);
        // Build the default config for a texture folder that no config file mentions
        _NODISCARD static FxConfig FromFolder(const RE::BSFixedString& a_name, const Counts& a_counts);
    };
}  // namespace Registry::CumFx
