#include "Compat/XxsBridge.h"

#include "RE/F/FunctionArguments.h"
#include "Registry/Util/Scale.h"
#include "UserData/Settings.h"
#include "Util/Script.h"

namespace Compat
{
    namespace detail
    {
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

        template <class T>
        std::optional<T> RunSyncStatic(const RE::BSFixedString& a_class, const RE::BSFixedString& a_fn, RE::BSScript::IFunctionArguments* a_args)
        {
            auto* vm = RE::BSScript::Internal::VirtualMachine::GetSingleton();
            if (!vm || !a_args) {
                return std::nullopt;
            }
            auto typedCallback = RE::BSTSmartPointer<SyncCallback<T>>(new SyncCallback<T>());
            RE::BSTSmartPointer<RE::BSScript::IStackCallbackFunctor> callback = typedCallback;
            if (!vm->DispatchStaticCall(a_class, a_fn, a_args, callback)) {
                return std::nullopt;
            }
            for (int i = 0; i < 2000 && !typedCallback->finished; ++i) {
                vm->Update(1.0f);
                vm->UpdateTasklets(1.0f);
            }
            if (!typedCallback->finished) {
                logger::warn("[xxs Bridge] SyncStaticCall timeout: {}.{}", a_class.c_str(), a_fn.c_str());
                return std::nullopt;
            }
            return typedCallback->value;
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

        std::optional<bool> FactionCachedIsChild(RE::Actor* a_actor)
        {
            const auto* faction = XxsUtilityFaction();
            if (!faction || !a_actor->IsInFaction(faction)) {
                return std::nullopt;
            }
            return a_actor->GetFactionRank(const_cast<RE::TESFaction*>(faction), a_actor->IsPlayerRef()) != 0;
        }
    }  // namespace detail

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
            return scale < Settings::fMinScale;
        }
        if (const auto cached = detail::FactionCachedIsChild(a_actor)) {
            return *cached;
        }
        const auto args = RE::MakeFunctionArguments(RE::VMHandle{ Script::GetHandle(a_actor) }, bool{ a_skipScale });
        if (const auto result = detail::RunSyncStatic<bool>("xxsUtility"sv, "xxsIsChild"sv, args)) {
            return *result;
        }
        logger::warn("[xxs Bridge] xxsIsChild call failed for {:X}, using fallback", a_actor->GetFormID());
        if (a_actor->IsChild()) {
            return true;
        }
        const auto scale = Registry::Scale::GetSingleton()->GetScale(a_actor);
        return scale < Settings::fMinScale;
    }

    bool IsPetiteForAtf(RE::Actor* a_actor)
    {
        if (!a_actor) {
            return false;
        }
        if (IsXxsUtilityLoaded()) {
            return IsXxsChild(a_actor, true);
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
        const auto args = RE::MakeFunctionArguments(RE::VMHandle{ Script::GetHandle(a_actor) });
        if (const auto key = detail::RunSyncStatic<std::string>("xxsUtility"sv, "GetSexLabActorKey"sv, args)) {
            return *key;
        }
        return "";
    }

    bool GetXxsFlag_SexlabUseMeForChildVoice()
    {
        if (!IsXxsUtilityLoaded()) {
            return false;
        }
        if (const auto v = detail::RunSyncStatic<bool>("xxsUtility"sv, "GetFlagSexlabUseMeForChildVoice"sv, RE::MakeFunctionArguments())) {
            return *v;
        }
        return false;
    }
}
