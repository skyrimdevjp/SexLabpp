#include "Compat/XxsBridge.h"

#include "RE/B/BGSKeyword.h"
#include "RE/F/FunctionArguments.h"
#include "RE/T/TESGlobal.h"
#include "Registry/Util/RayCast/Offsets.h"
#include "Registry/Util/Scale.h"
#include "UserData/Settings.h"
#include "Util/Script.h"

#include <SKSE/API.h>

#include <cmath>
#include <future>

namespace Compat
{
    namespace detail
    {
        thread_local int g_papyrusNativeDepth = 0;

        bool SyncPapyrusAllowed()
        {
            return g_papyrusNativeDepth == 0;
        }

        template <class T>
        struct SyncCallback final : RE::BSScript::IStackCallbackFunctor
        {
            T           value{};
            bool        finished{ false };

            void operator()(RE::BSScript::Variable a_result) override
            {
                if constexpr (std::is_same_v<T, bool>) {
                    value = RE::BSScript::UnpackValue<bool>(&a_result);
                } else if constexpr (std::is_same_v<T, std::string>) {
                    const RE::BSFixedString s = RE::BSScript::UnpackValue<RE::BSFixedString>(&a_result);
                    value = s.empty() ? ""s : std::string(s.c_str());
                }
                finished = true;
            }

            void SetObject(const RE::BSTSmartPointer<RE::BSScript::Object>&) override {}
        };

        bool IsGameThread()
        {
            const auto notOnGameThread = reinterpret_cast<bool (*)()>(Offsets::NotOnGameThread.address());
            return notOnGameThread && !notOnGameThread();
        }

        template <class T>
        std::optional<T> RunSyncStaticImpl(const RE::BSFixedString& a_class, const RE::BSFixedString& a_fn, RE::BSScript::IFunctionArguments* a_args)
        {
            auto* vm = RE::BSScript::Internal::VirtualMachine::GetSingleton();
            if (!vm || !a_args) {
                return std::nullopt;
            }
            auto typedCallback = RE::BSTSmartPointer<SyncCallback<T>>(new SyncCallback<T>());
            RE::BSTSmartPointer<RE::BSScript::IStackCallbackFunctor> callback = typedCallback;
            if (!vm->DispatchStaticCall(a_class, a_fn, a_args, callback)) {
                logger::warn("[xxs Bridge] SyncStaticCall dispatch failed: {}.{}", a_class.c_str(), a_fn.c_str());
                return std::nullopt;
            }
            for (int i = 0; i < 8000 && !typedCallback->finished; ++i) {
                vm->Update(1.0f);
                vm->UpdateTasklets(1.0f);
            }
            if (!typedCallback->finished) {
                logger::warn("[xxs Bridge] SyncStaticCall timeout: {}.{}", a_class.c_str(), a_fn.c_str());
                return std::nullopt;
            }
            return typedCallback->value;
        }

        template <class T>
        std::optional<T> RunSyncStatic(const RE::BSFixedString& a_class, const RE::BSFixedString& a_fn, RE::BSScript::IFunctionArguments* a_args)
        {
            if (!SyncPapyrusAllowed() || !a_args) {
                return std::nullopt;
            }
            const auto run = [&]() -> std::optional<T> {
                return RunSyncStaticImpl<T>(a_class, a_fn, a_args);
            };
            if (IsGameThread()) {
                return run();
            }
            std::optional<T>    result;
            std::promise<void>  done;
            auto                future = done.get_future();
            const auto*         task = SKSE::GetTaskInterface();
            if (!task) {
                logger::warn("[xxs Bridge] SyncStaticCall skipped (no task interface): {}.{}", a_class.c_str(), a_fn.c_str());
                return std::nullopt;
            }
            task->AddTask([&]() {
                result = run();
                done.set_value();
            });
            future.wait();
            return result;
        }

        RE::TESFaction* XxsUtilityFaction()
        {
            static RE::TESFaction* faction = []() -> RE::TESFaction* {
                auto* handler = RE::TESDataHandler::GetSingleton();
                if (!handler) {
                    return nullptr;
                }
                return handler->LookupForm<RE::TESFaction>(RE::FormID{ 0x00000803 }, "xxsUtility.esm"sv);
            }();
            return faction;
        }

        bool XxsGlobalBool(RE::FormID a_localId, bool a_default)
        {
            auto* handler = RE::TESDataHandler::GetSingleton();
            if (!handler) {
                return a_default;
            }
            auto* global = handler->LookupForm<RE::TESGlobal>(a_localId, "xxsUtility.esm"sv);
            if (!global) {
                return a_default;
            }
            return global->value >= 1.0f;
        }

        std::optional<bool> FactionCachedIsChild(RE::Actor* a_actor)
        {
            const auto* faction = XxsUtilityFaction();
            if (!faction || !a_actor->IsInFaction(faction)) {
                return std::nullopt;
            }
            return a_actor->GetFactionRank(const_cast<RE::TESFaction*>(faction), a_actor->IsPlayerRef()) != 0;
        }

        int GetAgeAsInt(RE::Actor* a_actor)
        {
            const auto* faction = XxsUtilityFaction();
            if (faction && a_actor->IsInFaction(faction)) {
                return a_actor->GetFactionRank(const_cast<RE::TESFaction*>(faction), a_actor->IsPlayerRef());
            }
            return 0;
        }

        float XxsGetHeightApprox(RE::Actor* a_actor)
        {
            return Registry::Scale::GetSingleton()->GetScale(a_actor);
        }

        std::string RaceEditorId(RE::Actor* a_actor)
        {
            auto*       base = a_actor->GetActorBase();
            const auto* race = base ? base->GetRace() : nullptr;
            if (!race) {
                return "";
            }
            const char* id = race->GetFormEditorID();
            return id ? std::string(id) : std::string();
        }

        bool IsCreatureActor(RE::Actor* a_actor)
        {
            static RE::BGSKeyword* npcKeyword = []() -> RE::BGSKeyword* {
                return RE::TESForm::LookupByEditorID<RE::BGSKeyword>("ActorTypeNPC");
            }();
            return npcKeyword && !a_actor->HasKeyword(npcKeyword);
        }

        bool HasChildVoice(RE::Actor* a_actor)
        {
            auto* base = a_actor->GetActorBase();
            if (!base) {
                return false;
            }
            auto* voice = base->GetVoiceType();
            if (!voice) {
                return false;
            }
            static const RE::FormID kMaleChild = 0x00013ae8;
            static const RE::FormID kFemaleChild = 0x00013ae9;
            const auto id = voice->GetFormID();
            return id == kMaleChild || id == kFemaleChild;
        }

        bool IsXxsChildNoSync(RE::Actor* a_actor, bool a_skipScale)
        {
            (void)a_skipScale;
            if (const auto cached = FactionCachedIsChild(a_actor)) {
                return *cached;
            }
            auto*       base = a_actor->GetActorBase();
            const auto* race = base ? base->GetRace() : nullptr;
            if (race && race->IsChildRace()) {
                return true;
            }
            if (a_actor->IsChild()) {
                return true;
            }
            if (HasChildVoice(a_actor)) {
                return true;
            }
            return false;
        }

        std::string BuildSexLabActorKeyNative(RE::Actor* a_actor)
        {
            if (!XxsGlobalBool(0x81D, true)) {
                return RaceEditorId(a_actor);
            }
            auto* base = a_actor->GetActorBase();
            if (!base) {
                return "";
            }
            const bool isFemale = base->GetSex() == RE::SEX::kFemale;
            const bool creature = IsCreatureActor(a_actor);
            const std::string raceId = RaceEditorId(a_actor);

            if (IsXxsChildNoSync(a_actor, true)) {
                std::string key = "child";
                key += isFemale ? "F" : "M";
                int xxsAge = 0;
                int xxsScale = 0;
                if (XxsGlobalBool(0x81E, false)) {
                    xxsAge = GetAgeAsInt(a_actor);
                } else if (XxsGlobalBool(0x81F, true)) {
                    xxsScale = static_cast<int>(std::lround(XxsGetHeightApprox(a_actor) * 20.0f));
                }
                if (xxsAge > 0) {
                    key += std::to_string(xxsAge);
                } else if (xxsScale > 0) {
                    key += "S" + std::to_string(xxsScale);
                }
                if (creature) {
                    key = raceId + key;
                }
                return key;
            }

            const int xxsScale = static_cast<int>(std::lround(XxsGetHeightApprox(a_actor) * 20.0f));
            if (creature) {
                std::string key = raceId + "C";
                if (XxsGlobalBool(0x81F, true) && xxsScale != 20) {
                    key += "S" + std::to_string(xxsScale);
                }
                return key;
            }

            std::string key = "adult";
            key += isFemale ? "F" : "M";
            if (XxsGlobalBool(0x81F, true) && xxsScale != 20) {
                key += "S" + std::to_string(xxsScale);
            }
            return key;
        }
    }  // namespace detail

    PapyrusNativeScope::PapyrusNativeScope()
    {
        ++detail::g_papyrusNativeDepth;
    }

    PapyrusNativeScope::~PapyrusNativeScope()
    {
        --detail::g_papyrusNativeDepth;
    }

    bool IsXxsUtilityLoaded()
    {
        auto* handler = RE::TESDataHandler::GetSingleton();
        return handler && handler->LookupModByName("xxsUtility.esm"sv) != nullptr;
    }

    bool IsXxsChild(RE::Actor* a_actor, bool a_skipScale)
    {
        if (!a_actor) {
            return false;
        }
        if (!IsXxsUtilityLoaded()) {
            if (a_actor->IsChild()) {
                return true;
            }
            const auto scale = Registry::Scale::GetSingleton()->GetScale(a_actor);
            return !a_skipScale && scale < Settings::fMinScale;
        }
        if (const auto cached = detail::FactionCachedIsChild(a_actor)) {
            return *cached;
        }
        if (detail::SyncPapyrusAllowed()) {
            const auto args = RE::MakeFunctionArguments(RE::VMHandle{ Script::GetHandle(a_actor) }, bool{ a_skipScale });
            if (const auto result = detail::RunSyncStatic<bool>("xxsUtility"sv, "xxsIsChild"sv, args)) {
                return *result;
            }
        }
        return detail::IsXxsChildNoSync(a_actor, a_skipScale);
    }

    bool IsPetiteForAtf(RE::Actor* a_actor)
    {
        if (!a_actor) {
            return false;
        }
        if (IsXxsUtilityLoaded()) {
            if (IsXxsChild(a_actor, true)) {
                return true;
            }
            // xxs 未判定の小柄成人（カスタム種族・スケールのみ）も ATF の petite 対象。
            return Registry::Scale::GetSingleton()->GetScale(a_actor) <= Settings::fMinScale;
        }
        if (a_actor->IsChild()) {
            return true;
        }
        return Registry::Scale::GetSingleton()->GetScale(a_actor) <= Settings::fMinScale;
    }

    void AppendAtfDisallowTags(std::vector<std::string_view>& a_tags, uint8_t a_petite_female, uint8_t a_petite_male, size_t a_actor_count)
    {
        if (a_petite_female + a_petite_male == a_actor_count && a_actor_count > 0) {
            a_tags.push_back("-loli");
            a_tags.push_back("-shota");
        } else if (a_petite_female || a_petite_male) {
            if (a_petite_female) {
                a_tags.push_back("-shota");
            } else if (a_petite_male) {
                a_tags.push_back("-loli");
            }
        }
    }

    std::string GetSexLabActorKey(RE::Actor* a_actor)
    {
        if (!a_actor || !IsXxsUtilityLoaded()) {
            return "";
        }
        return detail::BuildSexLabActorKeyNative(a_actor);
    }

    bool GetXxsFlag_SexlabUseMeForChildVoice()
    {
        if (!IsXxsUtilityLoaded()) {
            return false;
        }
        return detail::XxsGlobalBool(0x823, true);
    }
}
