Scriptname SSLRSVictimScript extends ReferenceAlias  

; この被害者に対応する加害者側 ReferenceAlias。
ReferenceAlias Property RaperRef auto
; OnHit で無視する MOD 内部のサポートスペル一覧。
Formlist Property SSLRSSupportSpells auto

; この Alias が保持する Actor が何らかの Hit を受けたときに呼ばれる。
; MOD 内部の補助スペルによる Hit は無視し、外部からの Hit だけを中断契機として扱う。
Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, Bool abPowerAttack, Bool abSneakAttack, Bool abBashAttack, Bool abHitBlocked)
	; サポートスペル由来の Hit なら、状態を崩さずそのまま終了する。
	if (SSLRSSupportSpells.hasForm(akSource))
		return
	endIf
	; 外部からの Hit を受けた場合は、対応する加害者 Alias を解除する。
	RaperRef.clear()
	; 被害者がプレイヤーの場合は、この Victim Alias 自身は保持する。
	; プレイヤー以外なら else 側でこの Alias も解除する。
	if (getActorRef() == Game.getPlayer())
	else
		; NPC 被害者の場合は、自分自身の Victim Alias も解放する。
		clear()
	endIf
endEvent