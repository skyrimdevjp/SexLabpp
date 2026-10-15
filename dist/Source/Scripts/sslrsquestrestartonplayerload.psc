Scriptname SSLRSQuestRestartOnPlayerLoad extends ReferenceAlias  

; ロード時の後処理対象となる SexLabRapeSpell Quest。
Quest Property SexLabRapeSpell auto
; MOD 更新時に停止・再起動する Quest 群。
Quest [] Property quests auto
; 最後に適用済みのスクリプト更新リビジョンを保持する GlobalVariable。
GlobalVariable Property lastRevision auto
Spell Property SexLabRapeSpellTarget auto
Spell Property SSLRSVictimDrainSpell auto
Spell Property SSLRSAggressDrainSpell auto
; 初期化時にも通常のロード時と同じ復旧処理を実行する。

Event onInit()
	onPlayerLoadGame()
endEvent
; Alias がロードされた場合も同じ復旧処理を実行する。

Event onLoad()
	onPlayerLoadGame()
endEvent
; セーブデータ読込後の復旧・更新処理。

Function onPlayerLoadGame()
	; SexLabRapeSpell の全 Alias を走査し、Actor が保持している一時的な Drain Spell を解除する。
	; 前回のシーン状態がセーブデータに残っていても、ロード後に効果を引きずらないようにする。
	int i = 0
	while (i < SexLabRapeSpell.getNumAliases())
		ReferenceAlias ra = SexLabRapeSpell.getNthAlias(i) as ReferenceAlias
		if (ra.getActorRef() as Actor)
			ra.getActorRef().dispelSpell(SSLRSVictimDrainSpell)
			ra.getActorRef().dispelSpell(SSLRSAggressDrainSpell)
		endIf
		i += 1
	endWhile
	int latestRevision = 12
	; 保存済みリビジョンが現在のリビジョンより古い場合だけ、更新処理を実行する。
	if (lastRevision.getValue() < latestRevision)
		i = 0
		; 各 Quest が更新前に起動していたかを記録する。
		; いったん停止したあと、元々動いていた Quest だけを再開するために使用する。
		bool [] qstatus = new bool [5]
		while (i < qstatus.Length)
			qstatus[i] = false
			i += 1
		endWhile
		i = 0
		while (i < quests.Length)
		; Quest 群を停止する前に、それぞれの実行状態を保存する。
			qstatus[i] = quests[i].isRunning()
			quests[i].stop()
			i += 1
		endWhile
		 i = 0
		while (i < quests.Length)
		; 更新前に動作していた Quest だけを再起動し、停止中だった Quest は停止状態を維持する。
			if (qstatus[i])
				quests[i].start()
			endIf
			i += 1
		endWhile
		if ((lastRevision.getValue() < 12))
			getActorRef().removeSpell(SexLabRapeSpellTarget)
		; Rev.12 より前のセーブデータでは、プレイヤーの対象スペルを一度外して付け直し、
		; 新しい定義を確実に反映させる。
			Utility.wait(0.1)
			getActorRef().addSpell(SexLabRapeSpellTarget)
		endIf
		lastRevision.setValue(latestRevision)
		debug.notification("SexLab RapeSpell: updated")
	endIf
		; 更新完了後、現在のリビジョンを保存して同じ移行処理が次回ロード時に繰り返されないようにする。
endFunction
