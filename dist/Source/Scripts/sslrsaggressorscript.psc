Scriptname sslrsaggressorscript extends ReferenceAlias  

; 性行為開始用スペル。条件を満たした aggressor から target へキャストする。
Spell Property SexLabRapeSpellTarget auto
; この Alias が処理対象として保持しているターゲット。
ReferenceAlias Property target auto
; Actor が NPC かどうかを判定するためのキーワード。
Keyword Property ActorTypeNPC auto
; SexLab のシーンに参加中かどうかを判定するためのキーワード。
Keyword Property SexLabActive auto

; commence() の多重実行を防ぐ簡易ロック。
; Package の Start/Change/End が短時間に連続して発火しても、同じ処理を重複実行しないために使用する。
int Property isOngoing = 0 auto

; 戦闘状態が終了（aeCombatState == 0）したら、この ReferenceAlias を解放する。
; clear() により Alias が保持している参照が外れ、次の対象を割り当てられる状態へ戻る。
Event OnCombatStateChanged(Actor akTarget, Int aeCombatState)
	if (aeCombatState == 0)
		clear()
	endIf
endEvent

Function commence()
	; 開始前のガード条件。
	; すでに処理中、必要な Spell/Alias が未設定、または target が SexLab 使用中なら何もしない。
	; getActorRef().hasKeyword(ActorTypeNPC) も元実装どおり除外条件として扱う。
	if (isOngoing || !SexLabRapeSpellTarget || !target || getActorRef().hasKeyword(ActorTypeNPC) || target.getActorRef().hasKeyword(SexLabActive))
		return
	endIf

	; ここから処理中としてロックする。
	; 下の Utility.wait(1) が終わるまで、別の Package イベントから commence() が呼ばれても即 return する。
	isOngoing = 1

	; aggressor と target の距離が 150 以下のときだけ開始スペルをキャストする。
	; 距離が離れている場合はキャストせず、1秒後にロックだけ解除する。
	if (getActorRef().getDistance(target.getActorRef()) <= 150)
		SexLabRapeSpellTarget.cast(getActorRef(), target.getActorRef())
	endIf

	; Package イベントの連続発火による短時間の再キャストを抑止するための待機時間。
	Utility.wait(1)
	; 次回の commence() 呼び出しを許可する。
	isOngoing = 0
endFunction

; AI Package が切り替わる各タイミングで commence() を試行する。
; 実際に開始できるかどうかは commence() 内のガード条件と距離判定に任せる。
Event OnPackageChange(Package akOldPackage)
	commence()
endEvent

Event OnPackageEnd(Package akOldPackage)
	commence()
endEvent

Event OnPackageStart(Package akNewPackage)
	commence()
endEvent
