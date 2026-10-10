#pragma once

namespace Thread
{
    // Smoothly drives an actor's facial phonemes, modifiers and expression (mood) towards target values.
    // Targets are set from any thread (Papyrus natives); values are written on the main thread by Update().
    // Value layout of a preset (same as sslBaseExpression.GetCurrentMFG):
    //   [0, 15]  phonemes   (0.0 - 1.0)
    //   [16, 29] modifiers  (0.0 - 1.0)
    //   [30]     expression id (0 - 16)
    //   [31]     expression strength (0.0 - 1.0)
    class FaceAnimator
    {
    public:
        static constexpr uint32_t PHONEME_COUNT = 16;
        static constexpr uint32_t MODIFIER_COUNT = 14;
        static constexpr uint32_t EXPRESSION_COUNT = 17;
        static constexpr uint32_t PRESET_SIZE = 32;

        // Time (seconds) a full 0 -> 1 change takes at speed 1.0
        static constexpr float BASE_TRANSITION_TIME = 0.2f;

        static void SetPhoneme(RE::Actor* a_actor, uint32_t a_idx, float a_value, float a_speed);
        static void SetModifier(RE::Actor* a_actor, uint32_t a_idx, float a_value, float a_speed);
        static void SetExpression(RE::Actor* a_actor, uint32_t a_mood, float a_value, float a_speed);
        static void ApplyPreset(RE::Actor* a_actor, const std::vector<float>& a_preset, bool a_keepMouth, float a_speed);
        static void Reset(RE::Actor* a_actor, bool a_phonemes, bool a_modifiers, bool a_expression, float a_speed);

        static void Update(float a_delta);
        static void Clear();

    private:
        struct Track
        {
            float target;
            float rate;  // value units per second
        };

        struct State
        {
            std::array<std::optional<Track>, PHONEME_COUNT> phonemes{};
            std::array<std::optional<Track>, MODIFIER_COUNT> modifiers{};
            std::optional<Track> expression{};
            uint32_t expressionId{ RE::BSFaceGenKeyframeMultiple::Expression::MoodNeutral };
            float expressionValue{ 0.0f };
            bool clearExpressionWhenDone{ false };

            bool Empty() const;
        };

        static float GetRate(float a_speed);
        static State& GetState(RE::Actor* a_actor);
        static void SetExpressionUnlocked(RE::Actor* a_actor, uint32_t a_mood, float a_value, float a_speed);
        static bool StepKeyframe(RE::BSFaceGenKeyframeMultiple& a_keyframe, std::optional<Track>* a_tracks, uint32_t a_count, float a_delta);
        static bool StepExpression(RE::BSFaceGenAnimationData* a_data, State& a_state, float a_delta);

        static inline std::mutex _m{};
        static inline std::unordered_map<RE::FormID, State> states{};
    };
}
