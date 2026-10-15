Scriptname SSLRSMCMQuestScript extends SKI_ConfigBase

GlobalVariable Property SSLRSMagnitude auto
GlobalVariable Property SSLRSNakedRate auto
GlobalVariable Property SSLRSLightLevel auto
GlobalVariable Property SSLRSPlayerAssaultRateDefault auto
GlobalVariable Property SSLRSNonLoverNorMasterRate auto
GlobalVariable Property SSLRSCourtingRateDefault auto
GlobalVariable Property SSLRSRandomRateDefault auto
GlobalVariable Property SSLRSPlayerNakedRate auto
GlobalVariable Property SSLRSSpeedFactor auto
GlobalVariable Property SSLRSCrimeEnabled auto
GlobalVariable Property SSLRSMoralSwitch auto
GlobalVariable Property SSLRSMxFFilter auto
GlobalVariable Property SSLRSFxMFilter auto
GlobalVariable Property SSLRSMxMFilter auto
GlobalVariable Property SSLRSFxFFilter auto
GlobalVariable Property SSLRSHomosexualFilter auto
GlobalVariable Property SSLRSGenderAnimation auto
Quest Property SSLRSWorldQuest auto

int [] descs = None
String [] labels = None
float [] defaults = None
GlobalVariable [] globals = None
String [] infos = None
int Property currentPreset = 0 auto
String [] presets = None
int [] index = None
int pdIdx = -1
int msIdx = -1
int crIdx = -1
int mrIdx = -1
int gaIdx = -1

Event onPageReset(String pageName)
	int k = 0
	descs = new Int [19]
	infos = new String [19]
	labels = new String [14]
	defaults = new float [14]
	globals = new GlobalVariable [14]
	presets = new String [6]
	index = new Int [14]

	labels[0] = "$Overall Magnitude"
	globals[0] = SSLRSMagnitude
	defaults[0] = 1.0
	infos[0] = "$SSLRSMagnitudeInfo"
	; この値は全体の発生倍率を定義する。0 にすると NPC による襲撃は発生しない。2 にすると NPC による襲撃の発生頻度は 2 倍になる。
	labels[1] = "$Naked %"
	globals[1] = SSLRSNakedRate
	defaults[1] = 50.0
	infos[1] = "$SSLRSNakedRateInfo"
	; 裸の NPC 被害者を潜在的な加害者が目撃した場合に、襲撃が発生する可能性を定義する。
	labels[2] = "$Light Level Threshold"
	globals[2] = SSLRSLightLevel
	defaults[2] = 40.0
	infos[2] = "$SSLRSLightLevelInfo"
	; 加害者が行動を起こす明るさのしきい値を定義する。被害者がこの値より暗い場所にいる場合、加害者が襲撃を開始する可能性がある。
	labels[3] = "$Player Assault %"
	globals[3] = SSLRSPlayerAssaultRateDefault
	defaults[3] = 12.0
	infos[3] = "$SSLRSPlayerAssaultInfo"
	; 恋人（RelationshipRank が 4）または主人（すでにプレイヤーを屈服させた相手）が、プレイヤーへ性的行為を要求しに来る頻度を定義する。
	labels[4] = "$Non Lover Nor Master Mod %"
	globals[4] = SSLRSNonLoverNorMasterRate
	defaults[4] = 20.0
	infos[4] = "$SSLRSNonLoverNorMasterInfo"
	; 味方（RelationshipRank が 3）だが主人ではない NPC からの襲撃確率に掛ける倍率を定義する。つまり、主人ではない味方の襲撃確率は「Player Assault % × この値」となる。
	labels[5] = "$NPC Courting %"
	globals[5] = SSLRSCourtingRateDefault
	defaults[5] = 12.0
	infos[5] = "$SSLRSCourtingInfo"
	; NPC 同士の恋愛関係にあるカップルが性交する頻度を定義する。
	labels[6] = "$Random Rape %"
	globals[6] = SSLRSRandomRateDefault
	defaults[6] = 5.0
	infos[6] = "$SSLRSRandomInfo"
	; ランダムな加害者がランダムな被害者を襲撃する頻度を定義する。
	labels[7] = "$Player Naked %"
	globals[7] = SSLRSPlayerNakedRate
	defaults[7] = 50.0
	infos[7] =  "$SSLRSPlayerNakedRateInfo"
	; 裸のプレイヤーを潜在的な加害者が目撃した場合に、襲撃が発生する可能性を定義する。
	labels[8] = "$Speed %"
	globals[8] = SSLRSSpeedFactor
	defaults[8] = 100
	infos[8] = "$SSLRSSpeedFactorInfo"

	labels[9] = "$MxFFilter"
	globals[9] = SSLRSMxFFilter
	defaults[9] = 100
	infos[9] = "$MxFFilterInfo"
	labels[10] = "$FxMFilter"
	globals[10] = SSLRSFxMFilter
	defaults[10] = 100
	infos[10] = "$FxMFilterInfo"
	labels[11] = "$MxMFilter"
	globals[11] = SSLRSMxMFilter
	defaults[11] = 0
	infos[11] = "$MxMFilterInfo"
	labels[12] = "$FxFFilter"
	globals[12] = SSLRSFxFFilter
	defaults[12] = 0
	infos[12] = "$FxFFilterInfo"
	labels[13] = "$HomosexualFilter"
	globals[13] = SSLRSHomosexualFilter
	defaults[13] = 4
	infos[13] = "$HomosexualFilterInfo"

	k = 13

	; index[] は、画面上のスライダー順序と globals[] / labels[] の実データ順序を対応付ける変換表。
	; 以降の descs[i] は画面側の番号、globals[index[i]] は実際に変更する GlobalVariable を指す。
	index[0] = 8
	index[1] = 0
	index[2] = 2
	index[3] = 7
	index[4] = 3
	index[5] = 4
	index[6] = 1
	index[7] = 5
	index[8] = 6

	index[9] = 9
	index[10] = 10
	index[11] = 11
	index[12] = 12
	index[13] = 13

	; ここからはスライダー以外の特殊オプション用 index を、descs[] の末尾側へ割り当てる。
	k += 1
	pdIdx = k
	k += 1
	msIdx = k
	k += 1
	crIdx = k
	k += 1
	mrIdx = k
	k += 1
	gaIdx = k

	int basePos = 0
	int i = 0
	int count = 0

	; basePos で SkyUI MCM の配置位置を管理し、i でスライダー項目を順番に生成する。
	setCursorPosition(basePos)
	addHeaderOption("$General/Common Options")
	basePos += 1

	descs[msIdx] = addTextOption("$Mod Running?", SSLRSWorldQuest.isRunning())
	basePos += 1

	descs[crIdx] = addToggleOption("$Criminal?", SSLRSCrimeEnabled.getValue() == 1.0)
	infos[crIdx] = "$SSLRSCrimeEnabledInfo"
	basePos += 1

	descs[mrIdx] = addToggleOption("$Moral?", SSLRSMoralSwitch.getValue() == 1.0)
	infos[mrIdx] = "$SSLRSMoralSwitchInfo"
	basePos += 1

	setCursorPosition(basePos)
	descs[i] = addSliderOption(labels[index[i]], globals[index[i]].getValue(), "{1}")
	i += 1
	basePos += 2

	setCursorPosition(basePos)
	presets[0] = "$Custom"
	presets[1] = "$No NPC Aggressors"
	presets[2] = "$Aggressors against NPCs Only"
	presets[3] = "$Less Taking Turns"
	presets[4] = "$Obscure Sex Life"
	presets[5] = "$Default"
	descs[pdIdx] = addMenuOption("$Preset", presets[currentPreset])
	infos[pdIdx] = "$SSLRSPresetInfo"
	; このプルダウンはプリセットを選択する。\nCustom - 自由設定\nNo NPC Aggressors - プレイヤーだけが他者を襲撃できる\nLess Taking Turns - NPC は裸の被害者に反応しにくくなる\nObscure Sex Life - より暗い場所でのみ襲撃が発生する\nDefault - 初期設定
	basePos += 2

	count = i + 2
	while (i < count)
		setCursorPosition(basePos)
		descs[i] = addSliderOption(labels[index[i]], globals[index[i]].getValue(), "{1}")
		basePos += 1
		i += 1
	endWhile

	if ((basePos%2) != 0)
		basePos += 1
	endIf
	setCursorPosition(basePos)
	addHeaderOption("$Player Victim Possibility")
	basePos += 2

	count = i + 3
	while (i < count)
		setCursorPosition(basePos)
		descs[i] = addSliderOption(labels[index[i]], globals[index[i]].getValue(), "{1}")
		basePos += 1
		i += 1
	endWhile

	if ((basePos%2) != 0)
		basePos += 1
	endIf
	setCursorPosition(basePos)
	addHeaderOption("$NPC Victim Possibility")
	basePos += 2

	count = i + 3
	while (i < count)
		setCursorPosition(basePos)
		descs[i] = addSliderOption(labels[index[i]], globals[index[i]].getValue(), "{1}")
		basePos += 1
		i += 1
	endWhile

	if ((basePos%2) != 0)
		basePos += 1
	endIf
	setCursorPosition(basePos)
	addHeaderOption("$Sexuality Filter")
	basePos += 2

	count = i + 4
	while (i < count)
		setCursorPosition(basePos)
		descs[i] = addSliderOption(labels[index[i]], globals[index[i]].getValue(), "{1}")
		basePos += 1
		i += 1
	endWhile

	setCursorPosition(basePos)
	descs[i] = addSliderOption(labels[index[i]], globals[index[i]].getValue(), "{1}")
	i += 1
	basePos += 2

	descs[gaIdx] = addToggleOption("$GenderAnimation", SSLRSGenderAnimation.getValue() == 1.0)
	infos[gaIdx] = "$SSLRSGenderAnimationInfo"
	basePos += 1
endEvent

Event onOptionSelect(int option)
	; 「Mod Running?」が選択された場合は、操作中の二重入力を避けるため全オプションを一時的に無効化し、
	; SSLRSWorldQuest の実行状態を反転する。
	if (option == descs[msIdx])
		setTextOptionValue(option, "$RESTARTING")
		int i = 0
		while (i < descs.Length)
			setOptionFlags(descs[i], OPTION_FLAG_DISABLED)
			i += 1
		endWhile
		if (SSLRSWorldQuest.isRunning())
			SSLRSWorldQuest.stop()			
		else
			SSLRSWorldQuest.start()
		endIf
	elseIf (option == descs[crIdx])
		SSLRSCrimeEnabled.setValue(1 - SSLRSCrimeEnabled.getValue())
		setToggleOptionValue(option, SSLRSCrimeEnabled.getValue() == 1.0)
	elseIf (option == descs[mrIdx])
		SSLRSMoralSwitch.setValue(1 - SSLRSMoralSwitch.getValue())
		setToggleOptionValue(option, SSLRSMoralSwitch.getValue() == 1.0)
	elseIf (option == descs[gaIdx])
		SSLRSGenderAnimation.setValue(1 - SSLRSGenderAnimation.getValue())
		setToggleOptionValue(option, SSLRSGenderAnimation.getValue() == 1.0)
	endIf
endEvent

Event onOptionMenuOpen(int option)
	if (option == descs[pdIdx])
		; プリセット
		setMenuDialogStartIndex(currentPreset)
		setMenuDialogDefaultIndex(0)
		setMenuDialogOptions(presets)
	endIf
endEvent

Event onOptionSliderOpen(int option)
	; descs[] から選択された画面項目の位置を求め、index[] を経由して対応する globals[] の実インデックスへ変換する。
	int idx = descs.find(option)
	if (idx < 0)
		return
	endIf
	idx = index[idx]
	if (globals[idx] == SSLRSSpeedFactor)
		setSliderDialogRange(10.0, 1000.0)
		setSliderDialogInterval(5.0)
	elseIf (globals[idx] == SSLRSLightLevel)
		; 明るさレベルだけは例外的な値域を使用する
		setSliderDialogRange(0.0, 150.0)
		setSliderDialogInterval(0.1)
	elseIf (globals[idx] == SSLRSHomosexualFilter)
		setSliderDialogRange(0.0, 4.0)
		setSliderDialogInterval(1.0)
	else
		setSliderDialogRange(0.0, 100.0)
		setSliderDialogInterval(0.1)
	endIf
	setSliderDialogStartValue(globals[idx].getValue())
	setSliderDialogDefaultValue(defaults[idx])
endEvent

Event onOptionMenuAccept(int option, int idx)
	; 選択されたプリセットに応じて globals[] の主要設定値をまとめて書き換える。
	if (option == descs[pdIdx])
		; プリセット
		currentPreset = idx
		setMenuOptionValue(option, presets[currentPreset])
		if (idx == 0)
			; Custom - 値は変更しない
			return
		elseIf (idx == 1)
			; NPC 加害者なし
			globals[0].setValue(0.0)
			globals[1].setValue(0.0)
			globals[2].setValue(40.0)
			globals[3].setValue(0.0)
			globals[4].setValue(20.0)
			globals[5].setValue(0.0)
			globals[6].setValue(0.0)
			globals[7].setValue(0.0)
		elseIf (idx == 2)
			; NPC 同士のみ
			globals[0].setValue(1.0)
			globals[1].setValue(50.0)
			globals[2].setValue(40.0)
			globals[3].setValue(0.0)
			globals[4].setValue(0.0)
			globals[5].setValue(12.0)
			globals[6].setValue(5.0)
			globals[7].setValue(0.0)
		elseIf (idx == 3)
			; 順番に相手をする頻度を抑える
			globals[0].setValue(1.0)
			globals[1].setValue(12.0)
			globals[2].setValue(40.0)
			globals[3].setValue(12.0)
			globals[4].setValue(20.0)
			globals[5].setValue(12.0)
			globals[6].setValue(5.0)
			globals[7].setValue(0.0)
		elseIf (idx == 4)
			globals[0].setValue(1.0)
			globals[1].setValue(25.0)
			globals[2].setValue(25.0)
			globals[3].setValue(12.0)
			globals[4].setValue(20.0)
			globals[5].setValue(12.0)
			globals[6].setValue(5.0)
			globals[7].setValue(25.0)
		elseIf (idx == 5)
			globals[0].setValue(1.0)
			globals[1].setValue(50.0)
			globals[2].setValue(40.0)
			globals[3].setValue(12.0)
			globals[4].setValue(20.0)
			globals[5].setValue(12.0)
			globals[6].setValue(5.0)
			globals[7].setValue(50.0)
		endIf
		; プリセット適用後、変更された GlobalVariable の値を現在の MCM スライダー表示へ反映する。
		int i = 0
		while (i < globals.Length)
			setSliderOptionValue(descs[i], globals[index[i]].getValue(), "{1}")
			i += 1
		endWhile
	endIf
endEvent

Event onOptionSliderAccept(int option, float value)
	; スライダーを手動変更した場合は、その項目に対応する GlobalVariable を更新する。
	int idx = descs.find(option)
	if (idx < 0)
		return
	endIf
	idx = index[idx]
	globals[idx].setValue(value)
	setSliderOptionValue(option, value, "{1}")
	; 手動変更が入った時点で既定プリセットとは一致しなくなるため、プリセット表示を Custom に戻す。
	currentPreset = 0
	setMenuOptionValue(descs[8], presets[currentPreset])
endEvent

Event onOptionDefault(int option)
	int idx = descs.find(option)
	if (idx < 0)
		return
	endIf
	idx = index[idx]
	globals[idx].setValue(defaults[idx])
	setSliderOptionValue(option, defaults[idx], "{1}")
endEvent

Event onOptionHighLight(int option)
	; ハイライトされた画面項目を実データ側の index に変換し、対応する説明文 infos[] を表示する。
	int idx = descs.find(option)
	if (idx < 0)
		return
	endIf
	idx = index[idx]
	setInfoText(infos[idx])
endEvent