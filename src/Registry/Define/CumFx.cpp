#include "CumFx.h"

namespace Registry::CumFx
{
    namespace
    {
        bool EqualsIgnoreCase(std::string_view a_lhs, std::string_view a_rhs)
        {
            return a_lhs.size() == a_rhs.size() &&
                   std::ranges::equal(a_lhs, a_rhs, [](char a, char b) { return std::tolower(static_cast<unsigned char>(a)) == std::tolower(static_cast<unsigned char>(b)); });
        }

        // Accepts a single scalar or a sequence of scalars
        std::vector<std::string> ReadStringList(const YAML::Node& a_node)
        {
            std::vector<std::string> ret{};
            if (!a_node || a_node.IsNull()) {
                return ret;
            }
            if (a_node.IsScalar()) {
                ret.push_back(a_node.as<std::string>());
            } else if (a_node.IsSequence()) {
                for (const auto& it : a_node) {
                    ret.push_back(it.as<std::string>());
                }
            } else {
                throw std::runtime_error("expected a name or a list of names");
            }
            return ret;
        }

        uint32_t ReadWeight(const YAML::Node& a_node)
        {
            if (!a_node || a_node.IsNull()) {
                return 1;
            }
            const auto weight = a_node.as<int64_t>();
            if (weight < 0) {
                throw std::runtime_error("weight must not be negative");
            }
            return static_cast<uint32_t>(std::min<int64_t>(weight, std::numeric_limits<uint32_t>::max()));
        }

        bool RaceMatches(const RE::TESRace* a_race, const std::string& a_editorID)
        {
            if (!a_race) {
                return false;
            }
            const char* editorID = a_race->GetFormEditorID();
            return editorID && EqualsIgnoreCase(editorID, a_editorID);
        }
    }

    void ActorFilter::Parse(const YAML::Node& a_node, std::string_view a_where)
    {
        for (const auto& race : ReadStringList(a_node["races"])) {
            const RaceKey key{ RE::BSFixedString{ race } };
            if (key.IsValid()) {
                raceKeys.push_back(key);
            } else {
                // Not a SexLab race key: treat it as a race EditorID (e.g. KhajiitRace or a custom race)
                raceEditorIDs.push_back(race);
            }
        }
        for (const auto& sexName : ReadStringList(a_node["sexes"])) {
            const auto sex = magic_enum::enum_cast<Sex>(sexName, magic_enum::case_insensitive);
            if (!sex || *sex == Sex::None) {
                logger::warn("CumFx: {}: unknown sex '{}' (expected Male, Female or Futa), ignored", a_where, sexName);
                continue;
            }
            sexes |= std::to_underlying(*sex);
        }
    }

    bool ActorFilter::Matches(RE::Actor* a_actor) const
    {
        if (!a_actor) {
            return true;
        }
        if (sexes != 0 && (sexes & std::to_underlying(GetSex(a_actor))) == 0) {
            return false;
        }
        if (raceKeys.empty() && raceEditorIDs.empty()) {
            return true;
        }
        if (!raceKeys.empty()) {
            const RaceKey key{ a_actor };
            if (std::ranges::any_of(raceKeys, [&](const RaceKey& a_key) { return a_key.Is(key); })) {
                return true;
            }
        }
        const auto race = a_actor->GetRace();
        // armorParentRace: custom (follower) races usually point to the vanilla race their body is based on
        const auto armorRace = race ? race->armorParentRace : nullptr;
        return std::ranges::any_of(raceEditorIDs, [&](const std::string& id) {
            return RaceMatches(race, id) || RaceMatches(armorRace, id);
        });
    }

    FxConfig FxConfig::FromYaml(const YAML::Node& a_root, const std::string& a_source)
    {
        if (!a_root.IsMap()) {
            throw std::runtime_error("the file does not contain a map");
        }
        FxConfig config{};
        config.source = a_source;
        const auto idNode = a_root["id"];
        if (!idNode || !idNode.IsScalar() || idNode.as<std::string>().empty()) {
            throw std::runtime_error("'id' is missing");
        }
        config.id = idNode.as<std::string>();
        if (const auto displayName = a_root["displayName"]; displayName && displayName.IsScalar()) {
            config.displayName = displayName.as<std::string>();
        }
        config.weight = ReadWeight(a_root["weight"]);
        config.filter.Parse(a_root, std::format("{} ({})", config.id.c_str(), a_source));

        const auto profilesNode = a_root["profiles"];
        if (!profilesNode || !profilesNode.IsSequence() || profilesNode.size() == 0) {
            throw std::runtime_error("'profiles' is missing or empty");
        }
        for (const auto& node : profilesNode) {
            FxProfile profile{};
            const auto nameNode = node["name"] ? node["name"] : node["id"];
            if (!nameNode || !nameNode.IsScalar() || nameNode.as<std::string>().empty()) {
                throw std::runtime_error("a profile has no 'name'");
            }
            profile.name = nameNode.as<std::string>();
            profile.weight = ReadWeight(node["weight"]);
            profile.filter.Parse(node, std::format("{}/{} ({})", config.id.c_str(), profile.name.c_str(), a_source));
            // counts: optional per type override; types not listed use the number of textures in the folder.
            // Stored as 0 here and resolved against the texture folders by the Library
            if (const auto countsNode = node["counts"]; countsNode && countsNode.IsMap()) {
                for (const auto& it : countsNode) {
                    const auto typeName = it.first.as<std::string>();
                    const auto type = magic_enum::enum_cast<Type>(typeName, magic_enum::case_insensitive);
                    if (!type) {
                        throw std::runtime_error(std::format("unknown FX type '{}' in counts (expected Vaginal, Anal or Oral)", typeName));
                    }
                    const auto count = it.second.as<int>();
                    if (count < 0 || count > std::numeric_limits<uint8_t>::max()) {
                        throw std::runtime_error(std::format("count for {} is out of range (0-255)", typeName));
                    }
                    profile.counts[std::to_underlying(*type)] = static_cast<uint8_t>(count);
                    profile.countGiven[std::to_underlying(*type)] = true;
                }
            }
            config.profiles.push_back(std::move(profile));
        }
        return config;
    }

    FxConfig FxConfig::FromFolder(const RE::BSFixedString& a_name, const Counts& a_counts)
    {
        FxConfig config{};
        config.id = a_name;
        config.displayName = a_name;
        FxProfile profile{};
        profile.name = a_name;
        profile.counts = a_counts;
        config.profiles.push_back(std::move(profile));
        return config;
    }
}  // namespace Registry::CumFx
