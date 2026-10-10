Scriptname SSLRSOngoingVictimScript extends ReferenceAlias  

; 現在の加害者側処理を保持している ReferenceAlias。
ReferenceAlias Property RaperRef auto
; OnHit で無視する対象となるサポートスペルの一覧。
Formlist Property SSLRSSupportSpells auto
; 犯罪判定用パルススペル。
Spell Property SSLRSCriminalPulseSpell auto

; この Alias が保持している被害者が攻撃を受けたときに呼ばれる。
; サポートスペルによる内部的な Hit は除外し、それ以外の Hit では進行中の処理を中断する。
Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, Bool abPowerAttack, Bool abSneakAttack, Bool abBashAttack, Bool abHitBlocked)
	; MOD 内部のサポートスペルが発生させた Hit は、通常の攻撃として扱わず無視する。
	if (SSLRSSupportSpells.hasForm(akSource))
		return
	endIf
	; 実際の攻撃を受けた場合は、進行中の RapeSpell 側処理を強制停止する。
	(RaperRef as sslrapespell).forceStop()
	; あわせて攻撃者の戦闘状態も停止し、戦闘継続を抑止する。
	(akAggressor as Actor).stopCombat()
endEvent
