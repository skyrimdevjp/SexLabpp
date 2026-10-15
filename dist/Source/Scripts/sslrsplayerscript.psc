Scriptname SSLRSPlayerScript extends ReferenceAlias  

; ワールド側の発生処理を管理する Quest。
Quest Property SSLRSRaperQuest auto

; プレイヤーのロケーションが変化したときに呼ばれる。
; 所有 Quest を sslrsworldquestscript として扱い、3秒後のワールド更新を予約する。
Event onLocationChange(Location akOldLoc, Location akNewLoc)
	(getOwningQuest() as sslrsworldquestscript).triggerWorld(3)
endEvent

; プレイヤーが新しいセルへアタッチされた場合にも同じワールド更新を予約する。
; ロケーション変更だけでは拾えないセル遷移でも更新処理を走らせるための入口。
Event onCellAttach()
	(getOwningQuest() as sslrsworldquestscript).triggerWorld(3)
endEvent
