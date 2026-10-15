Scriptname SSLRSEdgeTriggerScript extends activemagiceffect  

; 一時的に対象 Actor へ追加・削除するダミーアイテム。
; このスクリプトでは Magic Effect の開始時と終了時の両方で同じ操作に使用する。
Potion Property dummyWeight auto

; Magic Effect が開始されたときに呼ばれる。
Event onEffectStart(Actor akTarget, Actor akCaster)
	; 対象 Actor が有効な場合だけ処理する。
	if (akTarget)
		; dummyWeight を1個だけ一時的に追加する。
		akTarget.addItem(dummyWeight, 1, true)

		; 追加直後に削除せず、0.1秒だけ間隔を空ける。
		Utility.wait(0.1)

		; 先ほど追加した dummyWeight を1個削除し、元の所持状態へ戻す。
		akTarget.removeItem(dummyWeight, 1, true)
	endIf
endEvent

; Magic Effect が終了したときにも、開始時と同じ追加→待機→削除の処理を行う。
Event onEffectFinish(Actor akTarget, Actor akCaster)
	; 対象 Actor が有効な場合だけ処理する。
	if (akTarget)
		; dummyWeight を1個だけ一時的に追加する。
		akTarget.addItem(dummyWeight, 1, true)

		; 開始時と同様、0.1秒だけ待機する。
		Utility.wait(0.1)

		; 一時的に追加した dummyWeight を1個削除する。
		akTarget.removeItem(dummyWeight, 1, true)
	endIf
endEvent
