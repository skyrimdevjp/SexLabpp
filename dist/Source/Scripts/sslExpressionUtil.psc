Scriptname sslExpressionUtil Hidden

; 顔のアニメーションはSexLabUtil.dll (Thread::FaceAnimator)で制御するため、外部MFGプラグインは不要。
; 値の範囲は0.0～1.0。afSpeedは遷移時間を調整する（1.0 = 全体の変化に0.2秒）。
Function SetPhonemeImpl(Actor akActor, int aiIndex, float afValue, float afSpeed) native global
Function SetModifierImpl(Actor akActor, int aiIndex, float afValue, float afSpeed) native global
Function SetExpressionImpl(Actor akActor, int aiMood, float afValue, float afSpeed) native global
; afPreset: [0-15] 音素、[16-29] モディファイア、[30] 表情ID、[31] 表情強度
; abKeepMouth: 音素と表情を変更せずに保つ（口を開いたままにする）
Function ApplyPresetImpl(Actor akActor, float[] afPreset, bool abKeepMouth, float afSpeed) native global
Function ResetFaceImpl(Actor akActor, bool abPhonemes, bool abModifiers, bool abExpression) native global

;MFGモディファイア
;BlinkL 0
;BlinkR 1
;BrowDownL 2
;BrownDownR 3
;BrowInL 4
;BrowInR 5
;BrowUpL 6
;BrowUpR 7
;LookDown 8
;LookLeft 9
;LookRight 10
;LookUp 11
;SquintL 12
;SquintR 13
;2つの値を同時に変更する場合（例: 目を細める）
;mod2を使用しない場合は-1を設定する
Function SmoothSetModifier(Actor act, Int mod1, Int str_dest, float strModifier = 1.0) global
	mod1 = PapyrusUtil.ClampInt(mod1, 0, 13)
	str_dest = (str_dest * strModifier) as Int
	SetModifierImpl(act, mod1, str_dest as float / 100.0, 1.0)
EndFunction

;Aah 0    BigAah 1
;BMP 2    ChjSh 3
;DST 4    Eee 5
;Eh 6     FV 7
;i 8      k 9
;N 10     Oh 11
;OohQ 12  R 13
;Th 14    W 15
;https://steamcommunity.com/sharedfiles/filedetails/?l=english&id=187155077
Function SmoothSetPhoneme(Actor act, Int id, Int str_dest, float modifier = 1.0) global
	str_dest = (str_dest * modifier) as Int
	id = PapyrusUtil.ClampInt(id, 0, 15)
	SetPhonemeImpl(act, id, str_dest as float / 100.0, 1.0)
EndFunction

Function ApplyExpressionPreset(Actor akActor, float[] expression, bool openMouth) global
	float randomSpeed= Utility.RandomFloat(0.65, 1.0)
	ApplyPresetImpl(akActor, expression, openMouth, randomSpeed)
EndFunction

;MFG表情
;他のシステムがこのアクターに設定する表情を上書きする表情を設定する。
;7 - Mood Neutral
;0 - Dialogue Anger 8 - Mood Anger 15 - Combat Anger
;1 - Dialogue Fear 9 - Mood Fear 16 - Combat Shout
;2 - Dialogue Happy 10 - Mood Happy
;3 - Dialogue Sad 11 - Mood Sad
;4 - Dialogue Surprise 12 - Mood Surprise
;5 - Dialogue Puzzled 13 - Mood Puzzled
;6 - Dialogue Disgusted 14 - Mood Disgusted
;現在の表情と同じ表情を使う場合、またはオフセットから開始する場合はaiCurrentStrengthを使用できる
Function SmoothSetExpression(Actor act, Int aiMood, Int aiStrength, float aiModifier = 1.0) global
	aiMood = PapyrusUtil.ClampInt(aiMood, 0, 16)
	SetExpressionImpl(act, aiMood, aiStrength as float / 100.0, 1.0)
EndFunction

Function resetMFGSmooth(Actor ac) global
	ResetFaceImpl(ac, true, true, true)
endfunction
Function resetPhonemesSmooth(Actor ac) global
	ResetFaceImpl(ac, true, false, false)
endfunction
Function resetModifiersSmooth(Actor ac) global
	ResetFaceImpl(ac, false, true, false)
endfunction








