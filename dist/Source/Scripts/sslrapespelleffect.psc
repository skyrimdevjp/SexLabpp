scriptname sslRapeSpellEffect extends ActiveMagicEffect  

; 実際の主要処理を担当するスクリプト群
sslRapeSpell [] property RapeSpellArray auto
sslRSOngoingVictimScript [] property OngoingVictimArray auto
sslRapeSpell property PlayerRapeSpell auto
sslRSOngoingVictimScript property PlayerVictim auto
Sound Property SexLabRSPush auto
Keyword Property ArmorCuirass auto
Keyword Property ClothingBody auto
Spell Property SexLabRapeSpellTarget auto
ReferenceAlias[] Property Aggressors  Auto  
ReferenceAlias[] Property NPCAggressors  Auto
Spell Property SexLabRapeSpellBuff Auto

bool reported = false
sslRapeSpell RapeSpell = None
sslRSOngoingVictimScript OngoingVictim = None

; スペル効果が開始されたときに呼ばれる
event OnEffectStart(actor target, actor caster)
	; まず対象がこの効果を受けられる状態か確認する。
	; ここでは既存バフ、戦闘状態、残り体力、プレイヤー操作不能状態などを早期 return で除外する。
	caster.isDetectedBy(target)
	if (target.hasSpell(SexLabRapeSpellBuff))
		return
	endIf
	if (target.isWeaponDrawn())
		if (target.isHostileToActor(caster))
			if (target.isInCombat())
				if (target.getActorValuePercentage("Health") > 0.1)
					return
				endIf
			endIf
		endIf
	endIf
	if (target == Game.getPlayer())
		; プレイヤーが拘束中・演出中などで主要操作を失っている場合は開始しない。
		; caster が Aggressors に登録済みなら、その予約もここで解除して後続処理へ残さない。
		if (!Game.isMovementControlsEnabled() || !Game.isFightingControlsEnabled() || !Game.isCamSwitchControlsEnabled())
			int i = 0
			while (i < Aggressors.Length)
				if (Aggressors[i].getActorRef() == caster)
					Aggressors[i].clear()
					i = Aggressors.Length
				endIf
				i += 1
			endWhile
			return
		endIf
	endIf
	if (caster != Game.getPlayer())
		; NPC caster 用には RapeSpellArray / OngoingVictimArray の同じ添字を 1 組のスロットとして使う。
		; 空いている ReferenceAlias を探し、caster と target を対応する組へ固定して処理中の組み合わせを保持する。
		int i = 0
		RapeSpell = None
		while (i < RapeSpellArray.Length)
			if (RapeSpellArray[i].getActorRef() == None)
				RapeSpell = RapeSpellArray[i]
				(RapeSpell as ReferenceAlias).forceRefTo(caster)
				OngoingVictim = OngoingVictimArray[i]
				(OngoingVictim as ReferenceAlias).forceRefTo(target)
				i = RapeSpellArray.Length
			endIf
			i += 1
		endWhile
		if (RapeSpell == None)
			showMessage("Raper full.. "+caster.getLeveledActorBase().getName()+" should give up")
			return
		endIf
	else
		; プレイヤーが caster の場合は専用スロットを使用し、NPC 用プールとは分離する。
		RapeSpell = PlayerRapeSpell
		(RapeSpell as ReferenceAlias).forceRefTo(caster)
		OngoingVictim = PlayerVictim
		(OngoingVictim as ReferenceAlias).forceRefTo(target)
	endIf

	; CounterAttack は対象が SexLabRapeSpellTarget を持っているかで決まる。
	; 友好関係でも反撃扱いなら friendly として扱い、通常の犯罪通報処理を抑制する。
	(RapeSpell as SSLRapeSpell).CounterAttack = (target.hasSpell(SexLabRapeSpellTarget))
	bool friendly = (target.getRelationshipRank(caster) > 0) || (RapeSpell as SSLRapeSpell).CounterAttack
	if (!friendly && caster.isDetectedBy(target))
		bool naked = !(target.wornHasKeyword(ArmorCuirass) || target.wornHasKeyword(ClothingBody))
		RapeSpell.sendAlarm(target, caster, naked)
		reported = true
	endIf
	; シーン開始前の状態を保存し、押し倒し演出を行う。
	; NPC は PushActorAway、プレイヤーは BleedOutStart を使い、対象によって演出経路を分けている。
	RapeSpell.storeArousal(target)
	SexLabRSPush.play(target)
	if (target != Game.getPlayer())
		caster.pushActorAway(target, 2)
	else
		debug.sendAnimationEvent(target, "BleedOutStart")
	endIf
	Utility.wait(0.5)
	caster.stopCombat()
	target.stopCombat()
	; 対象アクターを別スクリプト側の Slots 配列へ登録する。
	; victim と caster の登録結果を result に集約する。
	; どちらかの必須登録に失敗した場合は、後段で Alias を解放して TriggerSex() を呼ばない。
	bool result = true
	result = result&&RapeSpell.RegisterActor(target, caster, true)
	result = result&&RapeSpell.RegisterActor(caster, caster, false)
	; 追加参加者候補は victim がプレイヤーか NPC かで別の Alias 配列から取得する。
	ReferenceAlias [] list
	if (target == Game.getPlayer())
		list = Aggressors
	else
		list = NPCAggressors
	endIf
	int i = 0
	; 追加攻撃者は、無効・未ロード・遠距離・caster 自身・関係性不足などを除外する。
	; 条件を通過した候補だけを RegisterActor() し、使用済み Alias は clear() する。
	while (i < list.length)
		ReferenceAlias ref = list[i]
		Actor actr = ref.getActorRef()
		if (ref == None || actr == None || actr == caster || actr.isDisabled() || actr.is3DLoaded() == false || actr.getDistance(target) > 800 || actr.getFactionReaction(caster) + actr.getRelationshipRank(caster) < 2)
			; 条件を満たさない候補は何もせずスキップする。
		else
			RapeSpell.RegisterActor(actr, caster, false)
			ref.clear()
		endIf
		i += 1
	endWhile
	; 必須アクターの登録に失敗した場合は、この試行で確保した Alias を解放する。
	; 成功した場合だけ TriggerSex() を呼び、実際の SexLab シーン開始処理へ進む。
	if (!result)
		if (caster != Game.getPlayer())
			(RapeSpell as ReferenceAlias).clear()
		endIf
		(OngoingVictim as ReferenceAlias).clear()
	else
		RapeSpell.TriggerSex()
	endIf
endEvent

; スペル効果が終了したときに呼ばれる
event OnEffectFinish(actor target, actor caster)
	; 開始時に犯罪通報されなかったケースを補完する終了時チェック。
	; reported フラグで同じ相手に対する二重通報を防ぐ。
	(RapeSpell as SSLRapeSpell).CounterAttack = (target.hasSpell(SexLabRapeSpellTarget))
	bool friendly = (target.getRelationshipRank(caster) > 0) || (RapeSpell as SSLRapeSpell).CounterAttack
	if (!friendly && !reported)
		bool naked = !(target.wornHasKeyword(ArmorCuirass) || target.wornHasKeyword(ClothingBody))
		RapeSpell.sendAlarm(target, caster, naked)
		reported = true
	endIf
endEvent

Function showMessage(String msg)
	; 通知はプレイヤー自身が caster のときだけ画面へ表示する。
	if (getCasterActor() == Game.getPlayer())
		debug.notification(msg)
	endIf
endFunction
