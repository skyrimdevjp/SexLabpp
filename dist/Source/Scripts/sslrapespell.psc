scriptname sslRapeSpell extends ReferenceAlias
; SexLabRapeSpell のバージョン番号
int version = 6

; 使用する SexLab フレームワークを読み込む
SexLabFramework property SexLab auto

; アクター選択用の格納領域
Actor[] Slots


; 別のアクターのスペル効果が切れた後、同じアクター構成に対して TriggerSex() を
; 誤って複数回呼び出さないようにするためのトリガーロック。
bool locked

; 使用するスペル
Spell property SexLabRapeSpellTarget auto
Spell property SexLabRapeSpellBuff auto

Faction Property SSLRSLoverFaction auto
Spell Property SSLRSCriminalPulseSpell auto
Spell Property SSLRSVictimDrainSpell auto
Spell Property SSLRSAggressDrainSpell auto
Spell Property SSLRSFearSpell auto
Spell Property SSLRSCalmSpell auto
Spell Property SSLRSGenitalQuench auto
MiscObject Property SSLRSBodyFluid auto

ReferenceAlias Property PlayerRef auto
ReferenceAlias Property OngoingVictim auto

Perk Property SSLRSSexualInferiorityPerk auto
Keyword Property ActorTypeNPC auto

GlobalVariable Property SSLRSSpeedFactor auto
GlobalVariable Property SSLRSGenderAnimation auto

bool Property CounterAttack = false auto

Actor Property caster = None auto
Actor Property target = None auto

FormList Property ForbiddenFactionList auto

int previousCrimeGold = 0
float previousArousal = 0.0
bool interrupted = false
bool wasProtected = false
bool wasNaked = false

; RapeSpell スクリプトを、登録済みアクターがいない状態へ初期化する
function ResetSlots()
	; Slots 配列を空の配列で初期化して内容を空にする。
	Actor[] emptyslots
	Slots = emptyslots
	; 今後使用できるよう TriggerSex() 関数のロックを解除する。
	locked = false
endFunction

; MOD が有効な状態で最初に起動されたときに呼ばれる
event OnInit()
	; ここでの各処理を開始させる irresistible aura スペルをプレイヤーに付与する。
	Game.GetPlayer().AddSpell(SexLabRapeSpellTarget, true)
	; Game.GetPlayer().AddSpell(RapeSpellSelf, true)
	; Slots と locked の状態を初期化する
	ResetSlots()
	if (self != PlayerRef)
		clear()
	endIf
endEvent

; プレイヤーがゲームをロードするたびに、登録済みアクターとロックをリセットする。
; 念のため、ロードのたびに使用可能な状態から開始できるようにする。
event OnPlayerLoadGame()
	if version < 6
		SexLab.PlayerRef.RemoveSpell(SexLabRapeSpellBuff)
		version = 6
	endIf
	ResetSlots()
endEvent

; アクターがすでにスロットへ登録されているか確認するユーティリティ関数
; すでに Slots 配列内に存在する場合は true を返す
bool function IsSlotted(actor Position)
	return Slots.Find(Position) != -1
endFunction

; スペルから呼び出され、対象を検証してシーンで使用するためにアクターを格納する。
; アクターを正常に格納できた場合は True、検証に失敗した場合は False を返す。
bool function RegisterActor(actor Position, Actor Aggressor, bool isTarget)
	interrupted = false
	; 登録を試みる前に、そのアクターを追加可能か検証する。

	; IsSlotted() で、すでに登録済みかどうかを確認する。
	if IsSlotted(Position)
		; Position はすでにスロット済みなので失敗とし、演出用メッセージを表示する。
		showMessage(Position.GetLeveledActorBase().GetName() + " is already in action!")
		return false ; 検証に通らなかったため、この関数の処理を続行しない。

	; すでに上限の 3 アクターを超えていないか確認する
	; あわせて、SexLab から見てアニメーション可能な有効なアクターかも確認する
	; Slots.Length >= 3 により、最大 3 人までの Slots 配列に空きがあるか確認する。
	; ValidateActor() は拒否された場合に負の値を返す。
	elseIf Slots.Length >= 3 || SexLab.ValidateActor(Position) < 1
		; 失敗時の演出用メッセージ。
		showMessage("Your spell fizzles and fails to affect " + Position.GetLeveledActorBase().GetName())
		return false ; 検証に通らなかったため、この関数の処理を続行しない。

	endIf

	; ここまで来たなら、アクターは検証チェックに合格している。
	if (Position == Aggressor)
		caster = Position
	endIf
	if (isTarget)
		target = Position
	endIf
	Position.removeItem(SSLRSBodyFluid, 100)

	; アクターを登録用配列へ追加する。
	Slots = sslUtility.PushActor(Position, Slots)
	; キャスト成功時の演出用メッセージ
	showMessage(Position.GetLeveledActorBase().GetName() + " gets involved in action!")

	; これで上限の 3 アクターに達したなら待たずにシーンを開始する。
	if Slots.Length >= 3
		TriggerSex()
	endIf
	return true
endFunction

; 現在の Slots 配列に入っている 1～3 人のアクターを使って、性行為シーンの開始を試みる。
function TriggerSex()

	; この処理中に別アクターのスペル効果が切れ、二重にトリガーされないよう確認する
	; また、そもそも処理対象となるアクターが存在することも確認する。
	if locked || Slots.Length == 0
		return ; TriggerSex() がすでに処理中、またはアクタースロットが空。ここで停止し、性行為を開始しない。
	endIf

	; 現在のアクタースロットに対する TriggerSex() の追加呼び出しを防ぐためロックする。
	locked = true

	; アクターを追加できる、使用可能な SexLab アニメーションスレッドを確保する。
	sslThreadModel Thread = SexLab.NewThread()

	; 現時点の SexLab アニメーションは、最初に渡されるアクターが女性であることを想定している。
	; そのため、アニメーション位置が正しく設定されるよう女性アクターを配列の先頭側へ移動する
	; SexLab の SortActors() は、既定で女性を配列の先頭側へ移動した配列を返す。
	Slots = SexLab.SortActors(Slots)

	bool aggressive = true
	String aggMask = ",Aggressive"
	if (SexLab.GetGender(caster) == 1 && SexLab.GetGender(target) == 0)
		; 女性から男性への行為では、Aggressive 扱いにするかをランダムに選択する
		aggressive = (Utility.randomInt(0, 1) == 1)
		if (!aggressive)
			stopAlarm()
			aggMask = ""
		endIf
	endIf

	int i = 0
	if (SSLRSGenderAnimation.getValue() == 1)
		bool lesb = true
		bool gay = true
		int maleCount = 0
		int femaleCount = 0
		while (i < Slots.Length)
			if (SexLab.getGender(Slots[i]) == 0)
				lesb = false
				maleCount += 1
			elseIf (SexLab.getGender(Slots[i]) == 1)
				gay = false
				femaleCount += 1
			else
				lesb = false
				gay = false
			endIf
			i += 1
		endWhile
		if (i == 1)
			; ソロケース - 相手が見つからなかった場合。典型例は女性 1 人に対して男性 3 人以上。
			lesb = false
			gay = false
			aggressive = false
		endIf
		String mask = ""
		if (Slots.Length > 2 &&  maleCount + femaleCount == Slots.Length)
			i = 0
			while (i < maleCount)
				mask += "M"
				i += 1
			endWhile
			i = 0
			while (i < femaleCount)
				mask += "F"
				i += 1
			endWhile
		endIf
		sslBaseAnimation [] anims
		if  (mask != "")
			;; 複数人ケース - Aggressive 条件は通常利用者には制限が厳しすぎるため無視する
			;; ex. anims = SexLab.AnimSlots.getByTags(Slots.Length, mask+aggMask, "", false)
			anims = SexLab.AnimSlots.getByTags(Slots.Length, mask, "", false)
			if (anims)
				Thread.setAnimations(anims)
			endIf
		elseIf (gay)
			; Aggressive 条件は通常利用者には制限が厳しすぎるため無視する
			anims = SexLab.AnimSlots.getByTags(Slots.Length, "Gay,Anal", "", false)
			if (anims)
				Thread.setAnimations(anims)
			endIf
		elseIf (lesb)
			; Aggressive 条件は通常利用者には制限が厳しすぎるため無視する
			anims = SexLab.AnimSlots.getByTags(Slots.Length, "Lesbian", "", false)
			if (anims)
				Thread.setAnimations(anims)
			endIf
		endIf
		if (anims.Length == 0)
			; 通常ケース、および上記すべての特殊ケースに対するフォールバック処理
			anims = SexLab.AnimSlots.getByDefault(maleCount, femaleCount, aggressive)
			anims = SexLab.removeTagged(anims, "LeadIn")
			if (anims)
				Thread.setAnimations(anims)
			endIf
		endIf
	endIf

	; ソート済みの Slots 配列から、登録済みアクターを順番にスレッドへ追加する。
	i = 0
	while i < Slots.Length
		; 各アクターをスレッドへ追加する。AddActor() は追加に失敗すると -1 を返す。
		if Thread.AddActor(Slots[i], (Slots[i] == target) && aggressive) == -1
			; 何らかの理由でアクターをスレッドへ追加できなかったため、処理を続行しない。
			; デバッグログへエラーメッセージを出力する。
			Debug.Trace("--- SexLab RapeSpell --- Failed to slot the actor '" + Slots[i].GetLeveledActorBase().GetName() + "' into the animation thread["+Thread.tid+"]!")
			; アニメーションスレッドのロックを解除し、自身をクリアして、すでに追加済みのアクターで処理を続けないようにする。
			; Thread.UnlockThread()
			; アクターをクリアし、今後使用できるよう TriggerSex() 関数のロックを解除する。
			ResetSlots()
			return ; アクターの追加に失敗したため、この関数をここで終了する。
		endIf
		if (Slots[i] == target)
			Thread.disableRagdollEnd(Slots[i], false)
		else
			Thread.disableRagdollEnd(Slots[i], true)
		endIf
		i += 1
	endWhile

	; スレッドに独自フック名 "RapeSpell" を設定する。
	Thread.SetHook("RapeSpell"+getName())
	; 独自イベント "EndBuff" を AnimationEnd フックへ登録する。このフックは、
	; アクターの処理が完了してリセットを開始した時点で一度発火する。
	; _RapeSpell により、上で設定した Thread.SetHook("RapeSpell") から呼ばれる非グローバルフックになるため、
	; RapeSpell 外部で開始された他のアニメーションではなく、このシーンだけが EndBuff イベントを呼び出す。
	RegisterForModEvent("AnimationStart_RapeSpell"+getName(), "AnimationChanged")
	RegisterForModEvent("LeadInEnd_RapeSpell"+getName(), "AnimationChanged")
	RegisterForModEvent("StageStart_RapeSpell"+getName(), "periodicReport")
	RegisterForModEvent("OrgasmStart_RapeSpell"+getName(), "periodicReport")
	RegisterForModEvent("AnimationChange_RapeSpell"+getName(), "AnimationChanged")
	RegisterForModEvent("AnimationEnd_RapeSpell"+getName(), "EndBuff")

	; シーン自体は基本的な構成にとどめ、その他の大部分は SexLab とプレイヤー設定に任せる。
	; それではアニメーションを開始する。
	thread_subject =Thread.StartThread()

	; 登録済みアクターの処理は完了したので、ロックをリセットして登録済みアクターをクリアする。
	ResetSlots()

endFunction

sslThreadController thread_subject = None
string flatten = ""
event AnimationChanged(string eventName, string argString, float argNum, form sender)
	target.dispelSpell(SSLRSVictimDrainSpell)
	caster.dispelSpell(SSLRSAggressDrainSpell)
	sslBaseAnimation sba = thread_subject.Animation
	string [] tags = sba.getTags()
	string [] skills = new string [4]
	skills[0] = "Vaginal"
	skills[1] = "Anal"
	skills[2] = "Oral"
	skills[3] = "Foreplay"
	flatten = ""
	int i = 0
	float caster_level = 1.0
	float target_level = 1.0
	while (i < tags.Length)
		int idx = skills.find(tags[i])
		if (idx >= 0)
			caster_level += SexLab.Stats.getSkillLevel(caster, skills[idx]) as float
			target_level += SexLab.Stats.getSkillLevel(target, skills[idx]) as float
			if (flatten != "")
				flatten += "/"
			endIf
			flatten += skills[idx]
		endIf
		i += 1
	endWhile
	if (flatten == "")
		flatten = "Uncategorized"
	endIf
	i = 0
	float C = 0.011*(SSLRSSpeedFactor.getValue()/100.0)
	float pF = 0.75
	float rF = 1 - pF
	float victimBaseMag = C*math.pow(strongerMaxValue(target), pF)*math.pow(strongerMaxValue(caster), rF)
	float aggressBaseMag = C*math.pow(strongerMaxValue(caster), pF)*math.pow(strongerMaxValue(target), rF)
	float victimDamage = victimBaseMag * (pF*caster_level+rF*target_level)/(caster_level+target_level)
	float aggressDamage = aggressBaseMag * (pF*target_level+rF*caster_level)/(caster_level+target_level)
	if (victimDamage < 0.01)
		victimDamage = 0.01
	endIf
	if (aggressDamage < 0.01)
		aggressDamage = 0.01
	endIf
	while (i < SSLRSVictimDrainSpell.getNumEffects())
		SSLRSVictimDrainSpell.setNthEffectMagnitude(i, victimDamage)
		SSLRSAggressDrainSpell.setNthEffectMagnitude(i, aggressDamage)
		i += 1
	endWhile
	SSLRSVictimDrainSpell.cast(target, target)
	SSLRSAggressDrainSpell.cast(target, caster)
	showMessage(flatten+" sex - "+caster.getLeveledActorBase().getName()+": Level "+caster_level as int+" / "+target.getLeveledActorBase().getName()+": Level "+target_level as int)
	periodicReport(eventName, argString, argNum, sender)
	registerForSingleUpdate(5)   ;;; 更新通知の取りこぼしを避けるためのハートビート回避策
endEvent

float Function strongerMaxValue(Actor akActor)
	float tsta = akActor.getActorValue("Stamina")
	float tstap = akActor.getActorValuePercentage("Stamina")
	if (tstap)
		tsta /= tstap
	endIf
	float tmag = akActor.getActorValue("Magicka")
	float tmagp = akActor.getActorValuePercentage("Magicka")
	if (tmagp)
		tmag /= tmagp
	endIf
	float tstrong = tsta
	if (tstrong < tmag)
		tstrong = tmag
	endIf
	if (tstrong == 0.0)
		tstrong = (akActor.getBaseActorValue("Stamina")+akActor.getBaseActorValue("Magicka"))/2
	endIf
	return tstrong
endFunction

float Function strongerValue(Actor akActor)
	float tsta = akActor.getActorValue("Stamina")
	float tmag = akActor.getActorValue("Magicka")
	float tstrong = tsta
	if (tstrong < tmag)
		tstrong = tmag
	endIf
	return tstrong
endFunction

function periodicReport(string eventName, string argString, float argNum, form sender)
	if (thread_subject.Stage == (thread_subject.Animation.StageCount))
		caster.addItem(SSLRSBodyFluid, 1)
		target.addItem(SSLRSBodyFluid, 1)
	endIf
	bool friendly = (target.getRelationshipRank(caster) > 0)
	if (friendly || CounterAttack || !caster.isDetectedBy(target) || wasNaked || target == Game.getPlayer() || caster.isGuard())
		; 何もしない
	else
		SSLRSCriminalPulseSpell.cast(caster, target)
	endIf
	float victimDamage = SSLRSVictimDrainSpell.getNthEffectMagnitude(0)+0.001
	float aggressDamage = SSLRSAggressDrainSpell.getNthEffectMagnitude(0)+0.001
	float tstrong = strongerValue(target)
	float ttime = tstrong/victimDamage+0.001
	float cstrong = strongerValue(caster)
	float ctime = cstrong/aggressDamage+0.001
	if (math.abs(ctime/ttime - 1.0) <= 0.1)
		showMessage("This is going to be a fair bout")
	elseIf (ctime > ttime)
		if (ctime > ttime*2)
			showMessage(caster.getLeveledActorBase().getName()+" is overwhelming in this position")
		else
			showMessage(caster.getLeveledActorBase().getName()+" has advantage in this position")
		endIf
	else
		if (ttime > ctime*2)
			showMessage(target.getLeveledActorBase().getName()+" is overwhelming in this position!")
		else
			showMessage(target.getLeveledActorBase().getName()+" has advantage in this position!")
		endIf
	endIf
	if (ttime as int == 0)
		showMessage(target.getLeveledActorBase().getName()+" is already exhausted")
	else
		showMessage(target.getLeveledActorBase().getName()+" will be exhausted in "+(ttime as int)+" seconds")
	endIf
	if (caster != Game.getPlayer() && caster.getParentCell() == Game.getPlayer().getParentCell())
		bool leadin = thread_subject.Animation.HasTag("LeadIn")
		float x = ((cstrong/strongerMaxValue(caster))+(tstrong/strongerMaxValue(target)))/2.0
		if (x > 1.0)
			x = 1.0
		endIf
		float stageFactor = 0.5 + 0.5*thread_subject.Stage/thread_subject.Animation.StageCount
		float y = stageFactor*1.2*x*(1.5 - math.pow(x, 3))
		y -= 0.1  ; カットオフ
		;debug.notification("backward threshold["+thread_subject.Stage+"]: "+y)
		if (!leadin && thread_subject.Stage > 2 && Utility.randomFloat(0, 1.0) <= y)
			if (thread_subject.Stage == thread_subject.Animation.StageCount)
				Utility.wait(1.5)
				thread_subject.advanceStage(true)
				Utility.wait(1)
				thread_subject.changeAnimation()
			else
				thread_subject.advanceStage(true)
			endIf
		endIf
	endIf
endFunction

string function format(float value)
	int integerPart = (value as int)*10
	int decimalPart = (value*10) as int
	decimalPart = decimalPart - integerPart
	integerPart /= 10
	return (integerPart as string)+"."+(decimalPart as string)
endFunction

; バフ用フック。RegisterForModEvent("AnimationEnd_RapeSpell", "EndBuff") から呼ばれる
; AnimationEnd は、性行為アニメーションが完全に停止した時点で SexLab から一度送信される
event EndBuff(string eventName, string argString, float argNum, form sender)

	; 終了時点のアクター一覧を取得する
	Actor[] Positions = SexLab.HookActors(argString)

	; アクター一覧を順番に処理する
	int i = Positions.Length
	while i
		i -= 1
		; 削除されたバフの代わりとなる終了時の演出用テキスト
		; Debug.Notification(Positions[i].GetLeveledActorBase().GetName() + "'s irrestible aura fades.")
		; バフスペルの不具合により Rev 6 で削除
		; 処理中のアクターへバフスペルを追加する
		; Positions[i].AddSpell(SexLabRapeSpellBuff, false)
		Positions[i].RemoveSpell(SexLabRapeSpellBuff)
	endWhile

	target.dispelSpell(SSLRSVictimDrainSpell)
	caster.dispelSpell(SSLRSAggressDrainSpell)
	bool casterWeak = ((caster.GetActorValue("Magicka") == 0 || caster.GetActorValuePercentage("Magicka") < 0.1) && (caster.GetActorValue("Stamina") == 0 || caster.GetActorValuePercentage("Stamina") < 0.1))
	bool targetWeak = ((target.GetActorValue("Magicka") == 0 || target.GetActorValuePercentage("Magicka") < 0.1) && (target.GetActorValue("Stamina") == 0 || target.GetActorValuePercentage("Stamina") < 0.1))
	bool friendly = (target.getRelationshipRank(caster) > 0)
	bool satisfied = previousArousal - getArousal(target) >= 75

	Form gold = Game.getForm(0xf)
	int budget = caster.getGoldAmount()
	if (budget > 50)
		budget = 50
	endIf
	if (budget < 5 || caster == Game.getPlayer() || friendly || interrupted)
	else
		budget = Utility.randomInt(5, budget)
		if (budget)
			caster.addItem(gold, budget)
			if (target == Game.getPlayer())
				debug.notification(caster.getActorBase().getName()+" dropped "+budget+" gold for hush money")
			endIf
			ObjectReference droppedCoin = caster.dropObject(gold, budget)
			droppedCoin.setActorOwner(target.getActorBase())
			if (target != Game.getPlayer())
				droppedCoin.activate(target)
				target.addItem(Game.getForm(0xf), budget - 1)
			endIf
		endIf
	endIf

	if (friendly || CounterAttack || (!interrupted && targetWeak) || satisfied)
		; 'satisfied' は SexLab Aroused アドオン専用のオプションである点に注意。'satisfied' だけを単独条件にしない。
		; 受諾
		;; 犯罪警報を解除
		if (targetWeak || satisfied)
			if (target.hasKeyword(ActorTypeNPC))
				debug.sendAnimationEvent(target, "BleedoutStart")
				registerForSingleUpdate(8)
			endIf
			if (caster == Game.getPlayer())
				;;; プレイヤーによるキャストを避ける（意図しないレベルアップを引き起こすため）
				SSLRSCalmSpell.cast(target, target)
			else
				SSLRSCalmSpell.cast(caster, target)
			endIf
			stopAlarm()
			SSLRSGenitalQuench.cast(caster, target)
			SSLRSGenitalQuench.cast(target, caster)
			;; 関係性を進展させる
			if (!friendly && !casterWeak)
				target.setRelationshipRank(caster, target.getRelationshipRank(caster)+1)
				Faction PotentialFollowerFaction = Game.getForm(0x5c84d) as Faction
				Faction CurrentFollowerFaction = Game.getForm(0x5c84e) as Faction
				target.addToFaction(PotentialFollowerFaction)
				if (!target.isInFaction(CurrentFollowerFaction))
					target.setFactionRank(CurrentFollowerFaction, -1)
				endIf
				showMessage("Relation with "+target.getLeveledActorBase().getName()+" improved")
				friendly = true
			endIf
		endIf
		;; 降伏
		if (friendly && targetWeak && !casterWeak)
			occupyCell(caster, target)
		endIf
	else
		; 拒否
		if (!friendly && targetWeak)
			if (caster == Game.getPlayer())
				;;; プレイヤーによるキャストを避ける（意図しないレベルアップを引き起こすため）
				SSLRSFearSpell.cast(target, target)
			else
				SSLRSFearSpell.cast(caster, target)
			endIf
		endIf
	endIf
	if (caster != Game.getPlayer())
		(self as ReferenceAlias).clear()
	endIf
	OngoingVictim.clear()
	wasNaked = false
	thread_subject = None
endEvent

Function sendAlarm(Actor akTarget, Actor akCaster, bool naked = false)
	if (naked)
		wasNaked = true
	endIf
	if (akCaster == Game.getPlayer())
		if (akTarget.getCrimeFaction())
			previousCrimeGold = akTarget.getCrimeFaction().getCrimeGoldViolent()
		endIf
		if (akCaster.getFactionRank(SSLRSLoverFaction) < 2 && !wasNaked)
			;debug.messagebox("Alarming from "+akTarget.getLeveledActorBase().getName()+" to "+akCaster.getLeveledActorBase().getName())
			SSLRSCriminalPulseSpell.cast(akCaster, akTarget)
		endIf
	else
		if (!wasNaked && !caster.isGuard())
			;debug.messagebox("Alarming from "+akTarget.getLeveledActorBase().getName()+" to "+akCaster.getLeveledActorBase().getName())
			SSLRSCriminalPulseSpell.cast(akCaster, akTarget)
		endIf
	endIf
endFunction

Function stopAlarm()
	if (caster == Game.getPlayer())
		if (target.getCrimeFaction())
			target.getCrimeFaction().setCrimeGoldViolent(previousCrimeGold)
		endIf
	endIf
	caster.setAttackActorOnSight(false)
	caster.clearArrested()
	caster.stopCombatAlarm()
	caster.clearArrested()
	caster.stopCombatAlarm()
endFunction

Function storeArousal(Actor akActor)
	if (Game.getFormFromFile(0x3fc36, "SexLabAroused.esm"))
		previousArousal = getArousal(akActor)
	endIf
endFunction

; SexLab Aroused の興奮度を返す。
; SexLabpp に統合したため slaFrameworkScr を型として使わない(ビルドが Aroused のソースに依存しないように)。
; Aroused は興奮度を派閥 sla_Arousal(0x3FC36)の位階に書き込むので、それを読む。
float Function getArousal(Actor akActor)
	Faction slaArousal = Game.getFormFromFile(0x3fc36, "SexLabAroused.esm") as Faction
	if (slaArousal)
		int rank = akActor.getFactionRank(slaArousal)
		if (rank > 0)
			return rank as float
		endIf
	endIf
	return 0.0
endFunction

Function occupyCell(Actor akCaster, Actor akTarget)
	int belongings = akTarget.getNumItems()
	Form nthItem = None
	while (belongings > 0)
		belongings -= 1
		nthItem = akTarget.getNthForm(belongings)
		if (nthItem.getType() == 45 && akCaster.getItemCount(nthItem) == 0)
			showMessage(akTarget.getLeveledActorBase().getName()+" yielded to "+akCaster.getLeveledActorBase().getName())
			akCaster.additem(nthItem, 1)
		endIf
	endWhile
	Cell theRoom = akTarget.getParentCell()
	if (theRoom && theRoom.isInterior())
		ActorBase actorOwner = theRoom.getActorOwner()
		Faction factionOwner = theRoom.getFactionOwner()
		if (!factionOwner || !akCaster.isInFaction(factionOwner))
			if (akCaster == Game.getPlayer() || !ForbiddenFactionList.hasForm(factionOwner))
				if (akTarget.isInFaction(factionOwner))
					akCaster.addToFaction(factionOwner)
					showMessage(akCaster.getLeveledActorBase().getName()+" joined in ownership of "+theRoom.getName())
				elseIf (actorOwner && actorOwner == akTarget.getActorBase())
					factionOwner = SSLRSLoverFaction
					theRoom.setFactionOwner(factionOwner)
					akCaster.setFactionRank(factionOwner, 1)
					akTarget.setFactionRank(factionOwner, 0)
					showMessage(akCaster.getLeveledActorBase().getName()+" joined in ownership of "+theRoom.getName())
				endIf
			endIf
		endIf
	endIf
	if (akCaster != Game.getPlayer() && akTarget == Game.getPlayer())
		akTarget.addPerk(SSLRSSexualInferiorityPerk)
		akCaster.setFactionRank(SSLRSLoverFaction, 2)
		showMessage("You are overwhelmed by "+akCaster.getLeveledActorBase().getName()+".", true)
	elseIf (akTarget != Game.getPlayer() && akCaster == Game.getPlayer())
		if (akTarget.getFactionRank(SSLRSLoverFaction) > 1)
			akCaster.removePerk(SSLRSSexualInferiorityPerk)
			if (akTarget.getFactionRank(SSLRSLoverFaction) == 2)
				akTarget.removeFromFaction(SSLRSLoverFaction)
			endIf
		endIf
	endIf
endFunction

Event onUpdate()
	if (thread_subject)
		thread_subject.onUpdate()
		registerForSingleUpdate(5)
	endIf
	if (target && target.is3DLoaded() && !target.isBleedingOut())
		debug.sendAnimationEvent(target, "BleedoutStop")
	endIf
endEvent

Event onHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, Bool abPowerAttack, Bool abSneakAttack, Bool abBashAttack, Bool abHitBlocked)
	(akAggressor as Actor).clearArrested()
	Weapon source = akSource as Weapon
	if (thread_subject)
		if (source && source.getWeaponType() <= 6)
			thread_subject.endAnimation(true)
			getActorRef().stopCombatAlarm()
			(akAggressor as Actor).clearArrested()
			Utility.wait(1)
			forceStop()
			Utility.wait(1)
			forceStop()
			Utility.wait(1)
			forceStop()
		endIf
	endIf
endEvent

Function showMessage(String msg, bool staticMsg = false)
	if (caster == Game.getPlayer() || target == Game.getPlayer())
		if (staticMsg)
			debug.messageBox(msg)
		else
			debug.notification(msg)
		endIf
	endIf
endFunction

Function forceStop()
	interrupted = true
	if (thread_subject)
		thread_subject.endAnimation(true)
	endIf
	if (caster != Game.getPlayer())
		(self as ReferenceAlias).clear()
	endIf
	OngoingVictim.clear()
	wasNaked = false
	thread_subject = None
endFunction
