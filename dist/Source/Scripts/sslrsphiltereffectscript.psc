Scriptname SSLRSPhilterEffectScript extends activemagiceffect  

; プレイヤーが caster の場合に使用する NPC 側 Alias。
ReferenceAlias Property PlayerAlly auto
; NPC 同士の分岐で使用する被害者側 Alias。
ReferenceAlias Property RandomVictim auto
; NPC 同士の分岐で使用する加害者側 Alias。
ReferenceAlias Property RandomRaper auto
; プレイヤーが caster で、target が NPC 以外の場合に使用する Alias。
ReferenceAlias Property ForcedPlayerRaper auto
; プレイヤー以外が caster で、target が NPC 以外の場合に使用する被害者側 Alias。
ReferenceAlias Property VolunteerVictim auto
; プレイヤー以外が caster で、target が NPC 以外の場合に使用する加害者側 Alias。
ReferenceAlias Property ForcedRaper auto
; 効果終了時に target 自身へキャストする Calm 用スペル。
Spell Property SSLRSTrueCalmSpell auto
Keyword Property ActorTypeNPC auto
Keyword Property ActorTypeCreature auto
; Alias 割り当て処理を行う Quest。
Quest Property SSLRSRaperQuest auto

; 効果開始時には特別な処理を行わない。
Event OnEffectStart(Actor akTarget, Actor akCaster)
endEvent

; 実際の処理は Magic Effect の終了時に行う。
Event OnEffectFinish(Actor akTarget, Actor akCaster)
	; まず target 自身へ Calm スペルを掛ける。
	SSLRSTrueCalmSpell.cast(akTarget, akTarget)
	; 続いて関連 Quest を開始し、Alias を割り当て可能な状態にする。
	SSLRSRaperQuest.start()
	; Quest 開始直後の状態反映を待つ。
	Utility.wait(1)
	; caster がプレイヤーかどうかで、使用する Alias の組み合わせを分岐する。
	if (akCaster == Game.getPlayer())
		; プレイヤーが caster の場合は、target が NPC かどうかで割り当て先を変える。
		if (akTarget.hasKeyword(ActorTypeNPC))
			PlayerAlly.forceRefTo(akTarget)
		else
			ForcedPlayerRaper.forceRefTo(akTarget)
		endIf
	else
		; プレイヤー以外が caster の場合も、target が NPC かどうかで被害者/加害者 Alias を切り替える。
		if (akTarget.hasKeyword(ActorTypeNPC))
			RandomVictim.forceRefTo(akCaster)
			RandomRaper.forceRefTo(akTarget)
		else
			VolunteerVictim.forceRefTo(akCaster)
			ForcedRaper.forceRefTo(akTarget)
		endIf
	endIf
endEvent