#include "Library.h"

#include "Util/Combinatorics.h"
#include "Util/StringUtil.h"

namespace Registry
{
    void Library::Initialize() noexcept
    {
        logger::info("Loading Library");
        const auto tStart = std::chrono::high_resolution_clock::now();
#ifndef SKYRIMVR
        std::array threads{
            std::thread{ [this]() { InitializeScenes(); } },
            std::thread{ [this]() { InitializeVoice(); } },
            std::thread{ [this]() { InitializeExpressions(); } },
            std::thread{ [this]() { InitializeFurnitures(); } },
            std::thread{ [this]() { InitializeCumFx(); } }
        };
        for (auto& thread : threads) {
            thread.join();
        }
#else
        InitializeScenes();
        InitializeVoice();
        InitializeExpressions();
        InitializeFurnitures();
#endif

        const auto tEnd = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double, std::milli> ms = tEnd - tStart;
        logger::info("Loaded {} Packages ({} scenes | {} categories)", packages.size(), GetSceneCount(), scenes.size());
        logger::info("Loaded {} Voices", voices.size());
        logger::info("Loaded {} VoiceType-Pitches", savedPitches.size());
        logger::info("Loaded {} Cached Voices", savedVoices.size());
        logger::info("Loaded {} Expressions", expressions.size());
        logger::info("Loaded {} CumFx Sets ({} configs)", std::accumulate(fxSets.begin(), fxSets.end(), 0ull,
                                                     [](auto acc, auto&& it) { return acc + it.profiles.size(); }), fxSets.size());
        logger::info("Loaded {} Furnitures", furnitures.size());
        logger::info("Library loaded in {}ms", ms.count());
    }

    bool Library::FolderExists(const char* path, bool notifyUser) const noexcept
    {
        std::error_code ec{};
        if (!fs::exists(path, ec) || fs::is_empty(path, ec)) {
            const auto msg = ec ? std::format("An error occured while initializing {}: {}", path, ec.message()) :
                                  std::format("Unable to open {}. Folder is empty or does not exist.", path);
            if (notifyUser) {
                logger::critical("{}", msg);
                const auto msgBox = std::format("{}\n\nExit game now?", msg);
                if (REX::W32::MessageBoxA(nullptr, msgBox.c_str(), "SexLab p+ Registry", 0x00000004) == 6) {
                    std::_Exit(EXIT_FAILURE);
                }
            } else {
                logger::warn("{}", msg);
            }
            return false;
        }
        return true;
    }

    void Library::InitializeScenes() noexcept
    {
        // SLAL packs are read as well, so a missing Registry folder is only an error if there are none of them either
        std::error_code ec{};
        const bool hasSlal = fs::is_directory(SLAL_PATH, ec) && !fs::is_empty(SLAL_PATH, ec);
        if (FolderExists(SCENE_PATH, !hasSlal)) {
            std::vector<fs::path> files{};
            for (auto& file : fs::recursive_directory_iterator{ SCENE_PATH }) {
                if (file.path().extension() == ".slr")
                    files.push_back(file.path());
            }
            InitializeScenesImpl(files, [](const fs::path& a_file) { return std::make_unique<AnimPackage>(a_file); });
        }
        // After the .slr files, so a pack that was converted to .slr is not loaded twice
        if (hasSlal) {
            std::vector<fs::path> files{};
            for (auto& file : fs::directory_iterator{ SLAL_PATH, ec }) {
                if (file.is_regular_file() && _stricmp(file.path().extension().string().c_str(), ".json") == 0)
                    files.push_back(file.path());
            }
            InitializeScenesImpl(files, [](const fs::path& a_file) { return AnimPackage::FromSlal(a_file); });
        }
        InitializeSceneSettings();
    }

    void Library::InitializeScenesImpl(const std::vector<fs::path>& a_files, std::unique_ptr<AnimPackage> (*a_load)(const fs::path&)) noexcept
    {
#ifndef SKYRIMVR
        std::vector<std::thread> threads;
#endif
        for (auto& file : a_files) {
#ifndef SKYRIMVR
            threads.emplace_back([this, file, a_load]() {
#endif
                const auto filename = file.filename().string();
                try {
                    auto package = a_load(file);
                    if (package->IsSlal()) {
                        const std::shared_lock lock{ _mScenes };
                        const auto converted = std::ranges::find_if(packages, [&](const auto& it) { return !it->IsSlal() && it->GetName() == package->GetName(); });
                        if (converted != packages.end()) {
                            throw std::runtime_error("A package of the same name is already loaded from .slr (converted pack). Skipping this SLAL pack");
                        }
                    }
                    for (auto&& scene : package->scenes) {
                        auto positionFragments = std::ranges::fold_left(scene->positions, std::vector<std::vector<ActorFragment>>{}, [](auto acc, const auto& pos) {
                            acc.push_back(pos.data.Split());
                            return std::move(acc);
                        });
                        Combinatorics::ForEachCombination<ActorFragment>(positionFragments, [&](const std::vector<std::vector<ActorFragment>::const_iterator>& it) {
                            std::vector<ActorFragment> argFragment{};
                            argFragment.reserve(it.size());
                            for (auto&& itF : it) {
                                argFragment.emplace_back(*itF);
                            }
                            const auto key = ActorFragment::MakeFragmentHash(argFragment);
                            const std::unique_lock lock{ _mScenes };
                            auto& vec = scenes[key];
                            if (!std::ranges::contains(vec, scene.get())) {
                                vec.push_back(scene.get());
                            }
                            return Combinatorics::CResult::Next;
                        });
                        const std::unique_lock lock{ _mScenes };
                        sceneMap[scene->id] = scene.get();
                    }
                    logger::info("InitializeScenes: Finished parsing file {} ({} scenes{})", filename, package->scenes.size(), package->IsSlal() ? ", SLAL" : "");
                    const std::unique_lock lock{ _mScenes };
                    packages.push_back(std::move(package));
                } catch (const std::exception& e) {
                    logger::error("InitializeScenes: Failed to load {}: {}", filename, e.what());
                }
#ifndef SKYRIMVR
            });
        }
        for (auto& thread : threads) {
            thread.join();
#endif
        }
    }

    void Library::InitializeSceneSettings() noexcept
    {
        if (!FolderExists(SCENE_USER_CONFIG, false))
            return;
        std::unique_lock lock{ _mScenes };
        for (auto& file : fs::directory_iterator{ SCENE_USER_CONFIG }) {
            if (const auto ext = file.path().extension(); ext != ".yaml" && ext != ".yml")
                continue;
            const auto filename = file.path().filename().string();
            try {
                const auto root = YAML::LoadFile(file.path().string());
                for (auto&& [key, scene] : sceneMap) {
                    const auto node = root[scene->id];
                    if (!node.IsDefined())
                        continue;
                    scene->Load(node);
                }
                logger::info("InitializeScenes: Finished parsing file {}", filename);
            } catch (const std::exception& e) {
                logger::error("InitializeScenes: Failed to load {}: {}", filename, e.what());
            }
        }
    }

    void Library::InitializeFurnitures() noexcept
    {
        if (!FolderExists(FURNITURE_PATH, false))
            return;
        const std::unique_lock lock{ _mFurniture };
        for (auto& file : fs::recursive_directory_iterator{ FURNITURE_PATH }) {
            if (auto ext = file.path().extension(); ext != ".yml" && ext != ".yaml") {
                continue;
            }
            const auto filename = file.path().filename().string();
            try {
                YAML::Node root = YAML::LoadFile(file.path().string());
                for (auto&& it : root) {
                    furnitures.emplace(
                        RE::BSFixedString(it.first.as<std::string>()),
                        std::make_unique<FurnitureDetails>(it.second));
                }
                logger::info("RegisterFurniture: Finished parsing file {}", filename);
            } catch (const std::exception& e) {
                logger::error("RegisterFurniture: Failed to load {}: {}", filename, e.what());
            }
        }
    }

    void Library::InitializeExpressions() noexcept
    {
        std::unique_lock lock{ _mExpressions };
        // NOTE: Intialization happens in stages, beginning with default (P+) expressions, then legacy & default.
        // This is to ensure that default expressions are always available, even if the user has not installed any custom expressions yet.
        // Further if the user has installed legacy expressions, they will be converted to the new format iff they have not been converted already.
        InitializeExpressionsImpl();
        InitializeExpressionsLegacy();
        constexpr auto arr = magic_enum::enum_entries<Expression::DefaultExpression>();
        for (auto&& [value, name] : arr) {
            if (expressions.contains(name)) {
                continue;
            }
            expressions.emplace(name, Expression{ value });
            logger::info("InitializeExpressions: Added default expression {}", name);
        }
    }

    void Library::InitializeExpressionsImpl() noexcept
    {
        if (!FolderExists(EXPRESSION_PATH, false))
            return;
        for (auto& file : fs::recursive_directory_iterator{ EXPRESSION_PATH }) {
            const auto extension = file.path().extension();
            if (extension != ".yaml" && extension != ".yml")
                continue;
            const auto filename = file.path().filename().string();
            try {
                const auto yaml = YAML::LoadFile(file.path().string());
                auto profile = Expression{ yaml };
                if (expressions.emplace(profile.GetId(), std::move(profile)).second) {
                    logger::info("InitializeExpressions: Added expression {}", filename);
                } else {
                    logger::warn("InitializeExpressions: Expression {} already exists, skipping", filename);
                }
            } catch (const std::exception& e) {
                logger::error("InitializeExpressions: Failed to load {}: {}", filename, e.what());
            }
        }
    }

    void Library::InitializeExpressionsLegacy() noexcept
    {
        if (!FolderExists(EXPRESSION_LEGACY_CONFIG, false))
            return;
        for (auto& file : fs::directory_iterator{ EXPRESSION_LEGACY_CONFIG }) {
            auto filename = file.path().filename().string();
            Util::ToLower(filename);
            if (!filename.starts_with("expression"))
                continue;
            try {
                auto profile = Expression::FromLegacyFile(file.path());
                auto succ = expressions.emplace(profile.GetId(), std::move(profile));
                if (succ.second) {
                    succ.first->second.Save(EXPRESSION_PATH, true);
                    logger::info("InitializeExpressions: Added legacy expression {}. This file may now be deleted", filename);
                }
            } catch (const std::exception& e) {
                logger::error("InitializeExpressions: Failed to load {}: {}", filename, e.what());
            }
        }
    }

    void Library::InitializeVoice() noexcept
    {
        std::unique_lock lock{ _mVoice };
        InitializeVoiceImpl();
        InitializeVoicePitches();
        InitializeVoiceSettings();
        InitializeVoiceCache();
    }

    void Library::InitializeVoiceImpl() noexcept
    {
        if (!FolderExists(VOICE_PATH, true))
            return;
        for (auto& file : fs::recursive_directory_iterator{ VOICE_PATH }) {
            if (const auto ext = file.path().extension(); ext != ".yaml" && ext != ".yml")
                continue;
            const auto filename = file.path().filename().string();
            try {
                const auto root = YAML::LoadFile(file.path().string());
                auto voice = Voice{ root };
                if (voices.emplace(voice.GetId(), std::move(voice)).second) {
                    logger::info("InitializeVoice: Added voice {}", filename);
                } else {
                    logger::warn("InitializeVoice: Voice {} already exists, skipping", filename);
                }
            } catch (const std::exception& e) {
                logger::error("InitializeVoice: Error while loading scene settings from file {}: {}", filename, e.what());
            }
        }
    }

    void Library::InitializeVoicePitches() noexcept
    {
        if (!FolderExists(VOICE_PATH_PITCH, false))
            return;
        for (auto& file : fs::recursive_directory_iterator{ VOICE_PATH_PITCH }) {
            if (const auto ext = file.path().extension(); ext != ".yaml" && ext != ".yml")
                continue;
            const auto filename = file.path().filename().string();
            try {
                const auto root = YAML::LoadFile(file.path().string());
                for (auto&& it : root) {
                    auto formIdStr = it.first.as<std::string>();
                    auto id = Util::FormFromString(formIdStr);
                    if (id == 0) {
                        logger::error("InitializeVoicePitches: Invalid form ID: {} in file {}", formIdStr, filename);
                        continue;
                    }
                    const auto pitchStr = it.second.as<std::string>();
                    auto pitch = magic_enum::enum_cast<Pitch>(pitchStr);
                    if (!pitch.has_value()) {
                        auto voice = voices.find(pitchStr);
                        if (voice == voices.end()) {
                            logger::error("InitializeVoicePitches: Unknown Pitch {} in file {}", pitchStr, filename);
                            continue;
                        }
                        savedPitches.insert_or_assign(id, &voice->second);
                    } else {
                        savedPitches.insert_or_assign(id, pitch.value());
                    }
                }
                logger::info("InitializeVoicePitches: Finished parsing file {}", filename);
            } catch (const std::exception& e) {
                logger::error("InitializeVoicePitches: Error while loading voice pitches from file {}: {}", filename, e.what());
            }
        }
    }

    void Library::InitializeVoiceSettings() noexcept
    {
        if (!FolderExists(VOICE_SETTING_PATH, false))
            return;
        try {
            const auto root = YAML::LoadFile(VOICE_SETTING_PATH);
            for (auto&& it : root) {
                const RE::BSFixedString voiceId = it.first.as<std::string>();
                const auto voice = voices.find(voiceId);
                if (voice == voices.end()) {
                    logger::error("InitializeVoice: Unknown voice {} in settings file", voiceId);
                    continue;
                }
                voice->second.Load(it.second);
            }
            logger::info("InitializeVoice: Loaded Voice Settings");
        } catch (const std::exception& e) {
            logger::error("InitializeVoice: Error while loading voice settings: {}", e.what());
        }
    }

    void Library::InitializeVoiceCache() noexcept
    {
        if (!FolderExists(VOICE_SETTINGS_CACHES_PATH, false))
            return;
        try {
            const auto root = YAML::LoadFile(VOICE_SETTINGS_CACHES_PATH);
            for (auto&& it : root) {
                const auto npcIdStr = it.first.as<std::string>();
                const auto id = Util::FormFromString(npcIdStr);
                if (id == 0)
                    continue;
                const auto voiceStr = it.second.as<std::string>();
                const auto voice = voices.find(voiceStr);
                if (voice == voices.end()) {
                    logger::error("InitializeVoice: Actor {:X} uses unknown Voice {}", id, voiceStr);
                    continue;
                }
                const auto& v = voice->second;
                savedVoices.insert_or_assign(id, &v);
            }
        } catch (const std::exception& e) {
            logger::error("InitializeVoice: Error while loading cached voices: {}", e.what());
        }
    }

    void Library::InitializeCumFx() noexcept
    {
        std::unique_lock lock{ _mCumFx };
        fxSets.clear();
        if (!FolderExists(CUM_FX_PATH, true))
            return;

        // 1) Texture folders: <Type>\<Set>\1.dds ... -> number of layers per type and set
        std::map<RE::BSFixedString, CumFx::Counts, FixedStringCompare> folders{};
        const auto fxTypes = magic_enum::enum_entries<Registry::Library::FxType>();
        for (auto&& [value, name] : fxTypes) {
            logger::info("Initializing FX type: {}", name);
            const auto path = std::format("{}{}", CUM_FX_PATH, name);
            if (fs::exists(path) && !fs::is_empty(path)) {
                for (auto& profileEntry : fs::directory_iterator(path)) {
                    if (!profileEntry.is_directory())
                        continue;
                    const auto typeCount = InitializeCumFxType(profileEntry);
                    if (typeCount == 0) {
                        logger::error("Failed to parse profile: {}", profileEntry.path().string());
                        continue;
                    }
                    const RE::BSFixedString profileName{ profileEntry.path().filename().string() };
                    folders[profileName][static_cast<size_t>(value)] = typeCount;
                    logger::info("Loaded profile: {}", profileName.c_str());
                }
            }
        }

        // 2) Config files: group sets and restrict them by race/sex. A config may only use existing texture folders
        std::set<RE::BSFixedString, FixedStringCompare> configured{};
        if (fs::exists(CUM_FX_CONFIG_PATH)) {
            for (const auto& file : fs::directory_iterator(CUM_FX_CONFIG_PATH)) {
                auto extension = file.path().extension().string();
                std::ranges::transform(extension, extension.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
                if (!file.is_regular_file() || (extension != ".yaml" && extension != ".yml" && extension != ".json")) {
                    continue;
                }
                const auto filePath = file.path().string();
                try {
                    // yaml-cpp also reads JSON (JSON is a subset of YAML)
                    auto config = CumFx::FxConfig::FromYaml(YAML::LoadFile(filePath), filePath);
                    std::erase_if(config.profiles, [&](CumFx::FxProfile& a_profile) {
                        const auto folder = folders.find(a_profile.name);
                        if (folder == folders.end()) {
                            logger::error("CumFx: {}: profile '{}' has no texture folder in {}<Type>\\, ignored", filePath, a_profile.name.c_str(), CUM_FX_PATH);
                            return true;
                        }
                        for (size_t i = 0; i < NUM_FX_TYPES; i++) {
                            const auto available = folder->second[i];
                            auto& count = a_profile.counts[i];
                            if (!a_profile.countGiven[i]) {
                                count = available;  // not given in the config: use all textures of the folder
                            } else if (count > available) {
                                logger::warn("CumFx: {}: profile '{}' asks for {} {} layers but the folder has {}, using {}",
                                    filePath, a_profile.name.c_str(), count, magic_enum::enum_name(static_cast<FxType>(i)), available, available);
                                count = available;
                            }
                        }
                        configured.insert(a_profile.name);
                        return false;
                    });
                    if (config.profiles.empty()) {
                        logger::error("CumFx: {}: no usable profile, config ignored", filePath);
                        continue;
                    }
                    logger::info("CumFx: Loaded config '{}' ({} profiles, weight {}) from {}", config.id.c_str(), config.profiles.size(), config.weight, filePath);
                    fxSets.push_back(std::move(config));
                } catch (const std::exception& e) {
                    // The folders this file would have described stay available as plain sets (step 3)
                    logger::error("CumFx: Failed to read config {}: {}. Its texture folders are loaded as plain sets instead", filePath, e.what());
                }
            }
        }

        // 3) Folders no config mentions: one plain set each, usable by every actor (behaviour without config files)
        for (const auto& [name, counts] : folders) {
            if (!configured.contains(name)) {
                fxSets.push_back(CumFx::FxConfig::FromFolder(name, counts));
            }
        }

        for (auto&& [value, name] : fxTypes) {
            const auto idx = static_cast<size_t>(value);
            const bool any = std::ranges::any_of(fxSets, [&](const auto& a_config) {
                return std::ranges::any_of(a_config.profiles, [&](const auto& a_profile) { return a_profile.counts[idx] > 0; });
            });
            if (!any) {
                logger::error("No valid FX profiles found for type: {}", name);
            }
        }
    }

    uint8_t Library::InitializeCumFxType(const fs::directory_entry& a_typePath) const noexcept
    {
        std::vector<uint8_t> fxFiles;
        for (const auto& file : fs::directory_iterator(a_typePath.path())) {
            if (!file.is_regular_file() || file.path().extension() != ".dds") {
                logger::warn("Invalid file type: {}. Expected .dds", file.path().string());
                continue;
            }
            std::string fileName = file.path().filename().string();
            size_t dotPos = fileName.find_last_of('.');
            std::string numberPart = fileName.substr(0, dotPos);
            try {
                size_t number = std::stoul(numberPart);
                if (number > std::numeric_limits<uint8_t>::max()) {
                    logger::warn("File number {} exceeds maximum value of 255", number);
                    continue;
                }
                fxFiles.push_back(static_cast<uint8_t>(number));
            } catch (const std::exception& e) {
                logger::warn("Invalid number in file name: {}. Error: {}", numberPart, e.what());
                continue;
            }
        }
        if (fxFiles.empty()) {
            logger::error("No valid files found in directory: {}", a_typePath.path().string());
            return 0;
        }
        std::sort(fxFiles.begin(), fxFiles.end());
        if (fxFiles.front() != 1) {
            logger::error("First file number is not 1 in directory: {}", a_typePath.path().string());
            return 0;
        }
        uint8_t expectedFileNumber = 1;
        for (const auto fileNumber : fxFiles) {
            if (fileNumber != expectedFileNumber) {
                logger::error("Missing file number {} in directory: {}", expectedFileNumber, a_typePath.path().string());
                return 0;
            }
            ++expectedFileNumber;
        }
        return static_cast<uint8_t>(fxFiles.size());
    }

    void Library::Save() const noexcept
    {
        SaveScenes();
        SaveExpressions();
        SaveVoices();
        logger::info("Finished saving registry settings");
    }

    void Library::SaveScenes() const noexcept
    {
        std::shared_lock lock{ _mScenes };
        std::vector<std::thread> threads{};
        for (auto&& p : packages) {
            threads.emplace_back([&]() {
                YAML::Node data{};
                for (auto&& scene : p->scenes) {
                    auto node = data[scene->id];
                    scene->Save(node);
                }
                const auto filepath = std::format("{}\\{}_{}.yaml", SCENE_USER_CONFIG, p->GetName().data(), p->GetHash());
                std::ofstream fout(filepath);
                fout << data;
            });
        }
        for (auto&& thread : threads) {
            thread.join();
        }
        logger::info("Saved scenes");
    }

    void Library::SaveExpressions() const noexcept
    {
        std::shared_lock lock{ _mExpressions };
        for (auto&& [id, expression] : expressions) {
            expression.Save(EXPRESSION_PATH, false);
        }
        logger::info("Saved expressions");
    }

    void Library::SaveVoices() const noexcept
    {
        const auto getSavefile = [](auto path) -> YAML::Node {
            try {
                if (fs::exists(path))
                    return YAML::LoadFile(path);
            } catch (const std::exception& e) {
                logger::error("Error while loading voice settings {}: {}. The file will be re-generated", path, e.what());
            }
            return YAML::Node{};
        };
        auto settings = getSavefile(VOICE_SETTING_PATH);
        for (auto&& [name, voice] : voices) {
            auto voiceNode = settings[name.data()];
            voice.Save(voiceNode);
        }
        std::ofstream fout_settings(VOICE_SETTING_PATH);
        fout_settings << settings;

        auto cache = getSavefile(VOICE_SETTINGS_CACHES_PATH);
        for (auto&& [id, voice] : savedVoices) {
            auto form = RE::TESForm::LookupByID<RE::Actor>(id);
            if (!form)
                continue;
            if (auto base = form->GetActorBase()) {
                if (!base->IsUnique())
                    continue;
            }
            auto str = Util::FormToString(form);
            cache[str] = voice->GetId().data();
        }
        std::ofstream fout_caches(VOICE_SETTINGS_CACHES_PATH);
        fout_caches << cache;
        logger::info("Saved voices");
    }

}  // namespace Registry
