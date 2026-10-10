#include "Animation.h"

#include "Registry/Define/RaceKey.h"
#include "Registry/Util/Decode.h"

// Reads a SLAL animation pack (Data\SLAnims\json\*.json) as a SexLab p+ package.
//
// The json is translated into the binary .slr format (version 4) in memory and then parsed like any other .slr,
// so a SLAL pack goes through the same validation as a regular package. The mapping follows the SLAL import of
// SexLab Scene Builder (Apache-2.0):
//  - Each SLAL animation becomes one scene with a linear chain of stages. The last stage is the climax stage
//  - Animation events are the SLAL stage ids as is (no hash prefix), so the FNIS lists shipped with the pack can be used unchanged
//  - "strap_on" on a human position allows futas on it. Creature positions take their race from "race" or "creature_race"
//  - Stage offsets: side -> x, forward -> y, up -> z, rotate (degrees) -> rotation
//  - "timer" of the animation's "stages" entries (1-based "number", seconds) becomes the fixed length of that stage
// Data SLAL has no field for (furniture, submissive positions, branching) uses default values.
// SLAL-only data (sound, silent, open_mouth, sos, add_cum) is ignored.

namespace Registry
{
    namespace
    {
        using Json = glz::generic;

        constexpr uint8_t SLR_VERSION = 4;

        const Json* Find(const Json& a_obj, std::string_view a_key)
        {
            if (!a_obj.is_object())
                return nullptr;
            const auto& obj = a_obj.get_object();
            const auto it = obj.find(a_key);
            return it == obj.end() ? nullptr : &it->second;
        }

        std::string GetString(const Json& a_obj, std::string_view a_key)
        {
            const auto value = Find(a_obj, a_key);
            return value && value->is_string() ? value->get_string() : std::string{};
        }

        float GetFloat(const Json& a_obj, std::string_view a_key)
        {
            const auto value = Find(a_obj, a_key);
            if (!value)
                return 0.0f;
            if (value->is_number())
                return value->as<float>();
            if (value->is_string()) {
                try {
                    return std::stof(value->get_string());
                } catch (...) {
                }
            }
            return 0.0f;
        }

        // Booleans are sometimes written as strings ("True") or numbers in SLAL files
        bool GetBool(const Json& a_obj, std::string_view a_key)
        {
            const auto value = Find(a_obj, a_key);
            if (!value)
                return false;
            if (value->is_boolean())
                return value->get_boolean();
            if (value->is_number())
                return value->as<double>() != 0.0;
            if (value->is_string())
                return _stricmp(value->get_string().c_str(), "true") == 0;
            return false;
        }

        const Json::array_t* GetArray(const Json& a_obj, std::string_view a_key)
        {
            const auto value = Find(a_obj, a_key);
            return value && value->is_array() ? &value->get_array() : nullptr;
        }

        std::string ToLower(std::string_view a_str)
        {
            std::string ret{ a_str };
            std::ranges::transform(ret, ret.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
            return ret;
        }

        /// @brief Deterministic id of a_length alphanumeric characters, so scene ids stay the same across game sessions
        std::string MakeId(std::string_view a_seed, size_t a_length)
        {
            constexpr std::string_view ALPHABET{ "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" };
            uint64_t fnv = 14695981039346656037ull;
            for (const unsigned char c : a_seed) {
                fnv ^= static_cast<uint64_t>(std::tolower(c));
                fnv *= 1099511628211ull;
            }
            std::string ret{};
            ret.reserve(a_length);
            for (size_t i = 0; i < a_length; i++) {
                ret.push_back(ALPHABET[fnv % ALPHABET.size()]);
                fnv /= ALPHABET.size();
            }
            return ret;
        }

        /// @brief Writes data in the (big endian) layout read by Registry/Util/Decode.h
        class Encoder
        {
          public:
            void U8(uint8_t a_value) { buffer.push_back(static_cast<char>(a_value)); }
            void U32(uint32_t a_value) { WriteBE(a_value); }
            void U64(uint64_t a_value) { WriteBE(a_value); }
            void F32(float a_value) { WriteBE(static_cast<uint32_t>(static_cast<int32_t>(std::lround(a_value * 1000.0f)))); }
            void Str(std::string_view a_value)
            {
                U64(a_value.size());
                buffer.append(a_value);
            }
            // Fixed size fields (ids, hash) have no length prefix
            void Fixed(std::string_view a_value, size_t a_size)
            {
                if (a_value.size() != a_size)
                    throw std::logic_error(std::format("Invalid field size: '{}' (expected {})", a_value, a_size));
                buffer.append(a_value);
            }
            void Append(const Encoder& a_other) { buffer.append(a_other.buffer); }

            std::string Release() { return std::move(buffer); }

          private:
            template <class T>
            void WriteBE(T a_value)
            {
                for (int i = sizeof(T) - 1; i >= 0; i--) {
                    buffer.push_back(static_cast<char>((a_value >> (i * 8)) & 0xFF));
                }
            }

            std::string buffer;
        };

        struct SlalPosition
        {
            RaceKey race;
            REX::EnumSet<Sex> sex;
            const Json::array_t* stages;
        };

        std::vector<SlalPosition> ReadPositions(const Json& a_animation)
        {
            const auto actors = GetArray(a_animation, "actors");
            if (!actors || actors->empty())
                throw std::runtime_error("Missing actors");
            if (actors->size() > ActorFragment::MAX_ACTOR_COUNT)
                throw std::runtime_error(std::format("Too many actors: {} (max {})", actors->size(), ActorFragment::MAX_ACTOR_COUNT));

            const auto creatureRace = GetString(a_animation, "creature_race");
            std::vector<SlalPosition> ret{};
            ret.reserve(actors->size());
            for (size_t n = 0; n < actors->size(); n++) {
                const auto& actor = (*actors)[n];
                auto& position = ret.emplace_back();
                position.stages = GetArray(actor, "stages");
                if (!position.stages || position.stages->empty())
                    throw std::runtime_error(std::format("Actor {} has no stages", n + 1));

                const auto type = ToLower(GetString(actor, "type"));
                if (type.empty() || type == "male" || type == "type") {
                    position.race = RaceKey::Human;
                    position.sex = Sex::Male;
                } else if (type == "female") {
                    position.race = RaceKey::Human;
                    position.sex = Sex::Female;
                } else if (type == "creaturemale" || type == "creaturefemale") {
                    auto raceStr = GetString(actor, "race");
                    if (raceStr.empty())
                        raceStr = creatureRace;
                    position.race = RaceKey{ RE::BSFixedString{ raceStr } };
                    if (!position.race.IsValid() || position.race.Is(RaceKey::Human))
                        throw std::runtime_error(std::format("Actor {}: unrecognized creature race '{}'", n + 1, raceStr));
                    position.sex = type == "creaturemale" ? Sex::Male : Sex::Female;
                } else {
                    throw std::runtime_error(std::format("Actor {}: unrecognized type '{}'", n + 1, type));
                }
                if (position.race.Is(RaceKey::Human)) {
                    const auto strapOn = std::ranges::any_of(*position.stages, [](const Json& stage) { return GetBool(stage, "strap_on"); });
                    if (strapOn)
                        position.sex.set(Sex::Futa);
                }
                if (position.stages->size() != ret.front().stages->size())
                    throw std::runtime_error(std::format("Actor {} has {} stages, but actor 1 has {}", n + 1, position.stages->size(), ret.front().stages->size()));
            }
            return ret;
        }

        std::vector<std::string> ReadTags(const Json& a_animation)
        {
            std::vector<std::string> ret{};
            const auto tags = GetString(a_animation, "tags");
            for (auto&& part : std::views::split(tags, ',')) {
                std::string tag{};
                for (const unsigned char c : part) {
                    if (!std::isspace(c))
                        tag.push_back(static_cast<char>(std::tolower(c)));
                }
                if (!tag.empty() && !std::ranges::contains(ret, tag))
                    ret.push_back(std::move(tag));
            }
            return ret;
        }

        /// @brief Fixed length (ms) of each stage, from the "timer" (s) of the animation's "stages" entries
        std::vector<float> ReadFixedLengths(const Json& a_animation, size_t a_stageCount)
        {
            std::vector<float> ret(a_stageCount, 0.0f);
            const auto extra = GetArray(a_animation, "stages");
            if (!extra)
                return ret;
            for (const auto& it : *extra) {
                const auto number = static_cast<int64_t>(GetFloat(it, "number"));
                const auto timer = GetFloat(it, "timer");
                if (number >= 1 && static_cast<size_t>(number) <= a_stageCount && timer > 0.0f) {
                    ret[number - 1] = timer * 1000.0f;
                }
            }
            return ret;
        }

        std::string MakeStageId(size_t a_index)
        {
            return std::format("Stage{:03}", a_index + 1);
        }

        void WriteScene(Encoder& a_out, const Json& a_animation, std::string_view a_sceneId)
        {
            const auto positions = ReadPositions(a_animation);
            const auto tags = ReadTags(a_animation);
            const auto stageCount = positions.front().stages->size();
            const auto fixedLengths = ReadFixedLengths(a_animation, stageCount);
            static_assert(Decode::ID_SIZE == 8);
            if (stageCount > 999)
                throw std::runtime_error("Too many stages");

            auto name = GetString(a_animation, "name");
            if (name.empty())
                name = GetString(a_animation, "id");

            a_out.Fixed(a_sceneId, Decode::ID_SIZE);
            a_out.Str(name);
            // --- Position Infos
            a_out.U64(positions.size());
            for (auto&& position : positions) {
                a_out.U8(position.race.value);
                a_out.U8(static_cast<uint8_t>(position.sex.underlying()));
                a_out.F32(1.0f);  // scale
                a_out.U8(0);      // extra: submissive, vampire, unconscious
            }
            // --- Stages
            a_out.U64(stageCount);
            for (size_t i = 0; i < stageCount; i++) {
                a_out.Fixed(MakeStageId(i), Decode::ID_SIZE);
                a_out.U64(positions.size());
                for (size_t n = 0; n < positions.size(); n++) {
                    const auto& stage = (*positions[n].stages)[i];
                    const auto event = GetString(stage, "id");
                    if (event.empty())
                        throw std::runtime_error(std::format("Actor {} stage {} has no id", n + 1, i + 1));
                    a_out.Str(event);
                    a_out.U8(i + 1 == stageCount);  // climax
                    a_out.F32(GetFloat(stage, "side"));
                    a_out.F32(GetFloat(stage, "forward"));
                    a_out.F32(GetFloat(stage, "up"));
                    a_out.F32(glm::radians(GetFloat(stage, "rotate")));
                    a_out.U8(static_cast<uint8_t>(Position::StripData::Default));
                    a_out.U64(0);  // position tags
                }
                a_out.F32(fixedLengths[i]);
                a_out.Str("");  // navtext
                a_out.U64(tags.size());
                for (auto&& tag : tags) {
                    a_out.Str(tag);
                }
            }
            // --- Graph: a linear chain
            a_out.U64(stageCount);
            for (size_t i = 0; i < stageCount; i++) {
                a_out.Fixed(MakeStageId(i), Decode::ID_SIZE);
                if (i + 1 < stageCount) {
                    a_out.U64(1);
                    a_out.Fixed(MakeStageId(i + 1), Decode::ID_SIZE);
                } else {
                    a_out.U64(0);
                }
            }
            // --- Misc
            // Old SexLab used animations on beds unless they were standing or furniture animations
            const bool allowBed = std::ranges::none_of(tags, [](const std::string& tag) { return tag == "standing" || tag == "furniture"; });
            a_out.U32(FurnitureType::None);
            a_out.U8(allowBed);
            for (size_t i = 0; i < 4; i++) {
                a_out.F32(0.0f);  // furniture offset
            }
            a_out.U8(0);  // private
        }
    }

    std::unique_ptr<AnimPackage> AnimPackage::FromSlal(const fs::path& a_file)
    {
        std::string buffer{};
        {
            std::ifstream file(a_file, std::ios::binary);
            if (!file)
                throw std::runtime_error("Unable to open file");
            buffer.assign(std::istreambuf_iterator<char>{ file }, std::istreambuf_iterator<char>{});
        }
        Json root{};
        if (const auto error = glz::read_json(root, buffer); error) {
            throw std::runtime_error(glz::format_error(error, buffer));
        }
        const auto animations = GetArray(root, "animations");
        if (!animations)
            throw std::runtime_error("Missing animations");

        const auto stem = a_file.stem().string();
        auto name = GetString(root, "name");
        if (name.empty())
            name = stem;
        const auto filename = ToLower(a_file.filename().string());

        Encoder body{};
        uint64_t sceneCount = 0;
        std::set<std::string> usedIds{};
        for (size_t i = 0; i < animations->size(); i++) {
            const auto& animation = (*animations)[i];
            auto key = GetString(animation, "id");
            if (key.empty())
                key = GetString(animation, "name");
            auto sceneId = MakeId(std::format("SLAL:{}:{}", filename, key), Decode::ID_SIZE);
            for (size_t salt = 1; usedIds.contains(sceneId); salt++) {
                sceneId = MakeId(std::format("SLAL:{}:{}:{}", filename, key, salt), Decode::ID_SIZE);
            }
            Encoder scene{};
            try {
                WriteScene(scene, animation, sceneId);
            } catch (const std::exception& e) {
                logger::error("SLAL {}: Skipping animation {} ('{}'): {}", stem, i + 1, key, e.what());
                continue;
            }
            usedIds.insert(sceneId);
            body.Append(scene);
            sceneCount++;
        }

        Encoder slr{};
        slr.U8(SLR_VERSION);
        slr.Str(name);
        slr.Str("SLAL");  // author
        slr.Fixed(MakeId(std::format("SLAL:{}", filename), Decode::HASH_SIZE), Decode::HASH_SIZE);
        slr.U64(sceneCount);
        slr.Append(body);

        std::istringstream stream{ slr.Release(), std::ios::binary };
        return std::make_unique<AnimPackage>(stream, false);
    }

}  // namespace Registry
