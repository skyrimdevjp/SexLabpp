#include "FaceAnimator.h"

namespace Thread
{
    bool FaceAnimator::State::Empty() const
    {
        const auto active = [](const auto& track) { return track.has_value(); };
        return !expression && !clearExpressionWhenDone && std::ranges::none_of(phonemes, active) && std::ranges::none_of(modifiers, active);
    }

    float FaceAnimator::GetRate(float a_speed)
    {
        const auto speed = a_speed > 0.0f ? a_speed : 1.0f;
        return speed / BASE_TRANSITION_TIME;
    }

    FaceAnimator::State& FaceAnimator::GetState(RE::Actor* a_actor)
    {
        return states[a_actor->GetFormID()];
    }

    void FaceAnimator::SetPhoneme(RE::Actor* a_actor, uint32_t a_idx, float a_value, float a_speed)
    {
        if (!a_actor || a_idx >= PHONEME_COUNT)
            return;
        std::scoped_lock lock{ _m };
        GetState(a_actor).phonemes[a_idx] = Track{ std::clamp(a_value, 0.0f, 1.0f), GetRate(a_speed) };
    }

    void FaceAnimator::SetModifier(RE::Actor* a_actor, uint32_t a_idx, float a_value, float a_speed)
    {
        if (!a_actor || a_idx >= MODIFIER_COUNT)
            return;
        std::scoped_lock lock{ _m };
        GetState(a_actor).modifiers[a_idx] = Track{ std::clamp(a_value, 0.0f, 1.0f), GetRate(a_speed) };
    }

    void FaceAnimator::SetExpression(RE::Actor* a_actor, uint32_t a_mood, float a_value, float a_speed)
    {
        if (!a_actor || a_mood >= EXPRESSION_COUNT)
            return;
        std::scoped_lock lock{ _m };
        SetExpressionUnlocked(a_actor, a_mood, a_value, a_speed);
    }

    void FaceAnimator::SetExpressionUnlocked(RE::Actor* a_actor, uint32_t a_mood, float a_value, float a_speed)
    {
        auto& state = GetState(a_actor);
        if (state.expressionId != a_mood) {
            // A different mood replaces the current one right away (the engine only shows one override)
            state.expressionId = a_mood;
            state.expressionValue = 0.0f;
        }
        state.expression = Track{ std::clamp(a_value, 0.0f, 1.0f), GetRate(a_speed) };
        state.clearExpressionWhenDone = false;
    }

    void FaceAnimator::ApplyPreset(RE::Actor* a_actor, const std::vector<float>& a_preset, bool a_keepMouth, float a_speed)
    {
        if (!a_actor || a_preset.size() < PRESET_SIZE)
            return;
        std::scoped_lock lock{ _m };
        auto& state = GetState(a_actor);
        const auto rate = GetRate(a_speed);
        // An open mouth (e.g. oral interaction) keeps its phonemes and mood, see sslBaseExpression.ApplyPresetFloatsLegacy
        if (!a_keepMouth) {
            for (uint32_t i = 0; i < PHONEME_COUNT; i++) {
                state.phonemes[i] = Track{ std::clamp(a_preset[i], 0.0f, 1.0f), rate };
            }
            const auto mood = static_cast<int32_t>(a_preset[30]);
            if (mood >= 0 && static_cast<uint32_t>(mood) < EXPRESSION_COUNT) {
                SetExpressionUnlocked(a_actor, static_cast<uint32_t>(mood), a_preset[31], a_speed);
            }
        }
        for (uint32_t i = 0; i < MODIFIER_COUNT; i++) {
            state.modifiers[i] = Track{ std::clamp(a_preset[PHONEME_COUNT + i], 0.0f, 1.0f), rate };
        }
    }

    void FaceAnimator::Reset(RE::Actor* a_actor, bool a_phonemes, bool a_modifiers, bool a_expression, float a_speed)
    {
        if (!a_actor)
            return;
        std::scoped_lock lock{ _m };
        auto& state = GetState(a_actor);
        const auto rate = GetRate(a_speed);
        if (a_phonemes) {
            for (auto& track : state.phonemes) {
                track = Track{ 0.0f, rate };
            }
        }
        if (a_modifiers) {
            for (auto& track : state.modifiers) {
                track = Track{ 0.0f, rate };
            }
        }
        if (a_expression) {
            state.expression = Track{ 0.0f, rate };
            state.clearExpressionWhenDone = true;
        }
    }

    bool FaceAnimator::StepKeyframe(RE::BSFaceGenKeyframeMultiple& a_keyframe, std::optional<Track>* a_tracks, uint32_t a_count, float a_delta)
    {
        bool active = false;
        const auto count = std::min(a_count, a_keyframe.count);
        for (uint32_t i = 0; i < count; i++) {
            auto& track = a_tracks[i];
            if (!track) {
                continue;
            }
            const auto current = a_keyframe.values[i];
            const auto step = track->rate * a_delta;
            const auto diff = track->target - current;
            if (std::abs(diff) <= step) {
                a_keyframe.SetValue(i, track->target);
                track.reset();
            } else {
                a_keyframe.SetValue(i, current + std::copysign(step, diff));
                active = true;
            }
        }
        return active;
    }

    bool FaceAnimator::StepExpression(RE::BSFaceGenAnimationData* a_data, State& a_state, float a_delta)
    {
        auto& keyframe = a_data->expressionKeyFrame;
        if (a_state.expression) {
            const auto step = a_state.expression->rate * a_delta;
            const auto diff = a_state.expression->target - a_state.expressionValue;
            if (std::abs(diff) <= step) {
                a_state.expressionValue = a_state.expression->target;
                a_state.expression.reset();
            } else {
                a_state.expressionValue += std::copysign(step, diff);
            }
            for (uint32_t i = 0; i < keyframe.count; i++) {
                keyframe.SetValue(i, i == a_state.expressionId ? a_state.expressionValue : 0.0f);
            }
            a_data->exprOverride = true;
        }
        if (!a_state.expression && a_state.clearExpressionWhenDone) {
            a_state.clearExpressionWhenDone = false;
            a_data->ClearExpressionOverride();
        }
        return a_state.expression.has_value();
    }

    void FaceAnimator::Update(float a_delta)
    {
        if (a_delta <= 0.0f)
            return;
        std::scoped_lock lock{ _m };
        for (auto it = states.begin(); it != states.end();) {
            auto& state = it->second;
            const auto actor = RE::TESForm::LookupByID<RE::Actor>(it->first);
            const auto data = actor && actor->Is3DLoaded() ? actor->GetFaceGenAnimationData() : nullptr;
            if (!data) {
                it = states.erase(it);
                continue;
            }
            {
                RE::BSSpinLockGuard dataLock{ data->lock };
                StepKeyframe(data->phenomeKeyFrame, state.phonemes.data(), PHONEME_COUNT, a_delta);
                StepKeyframe(data->modifierKeyFrame, state.modifiers.data(), MODIFIER_COUNT, a_delta);
                StepExpression(data, state, a_delta);
            }
            it = state.Empty() ? states.erase(it) : std::next(it);
        }
    }

    void FaceAnimator::Clear()
    {
        std::scoped_lock lock{ _m };
        states.clear();
    }
}
