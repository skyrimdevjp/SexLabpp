Scriptname sslrsworldquestscript extends Quest  

; ワールド側の発生処理を担当する Quest。
Quest Property SSLRSRaperQuest auto
; 2 要素を1組として扱う ReferenceAlias 配列。
; raperStart() では Pairs[i] と Pairs[i+1] の両方が埋まっているかを確認する。
ReferenceAlias [] Property Pairs auto
; 現在のランダム発生率。以下の *Default は基準値として使用する。
GlobalVariable Property SSLRSRandomRate auto
GlobalVariable Property SSLRSCourtingRate auto
GlobalVariable Property SSLRSPlayerAssaultRate auto
GlobalVariable Property SSLRSRandomRateDefault auto
GlobalVariable Property SSLRSCourtingRateDefault auto
GlobalVariable Property SSLRSPlayerAssaultRateDefault auto
; ゲーム内時刻から計算する発生率倍率へ、さらに掛ける全体倍率。
GlobalVariable Property SSLRSMagnitude auto
; 進行中のセッションを保持する ReferenceAlias 配列。
ReferenceAlias [] Property Sessions auto
Keyword Property SexLabActive auto

; Quest 初期化時は残留セッションを整理してから、定期更新を開始する。
Event onInit()
	cleanUp()
	triggerWorld()
endEvent

; Quest が Reset された場合も、初期化時と同じ手順で再開する。
Event onReset()
	cleanUp()
	triggerWorld()
endEvent

; 指定秒数後に onUpdate() を一度だけ呼ぶタイマーを登録する。
Function triggerWorld(int interval=10)
	registerForSingleUpdate(interval)
endFunction

; タイマー発火時にワールド側の発生判定を実行する。
Event onUpdate()
	raperStart()
endEvent

; Sessions[] に残っている古い状態を整理する。
; SexLab のアクティブ状態ではない Actor は forceStop() し、その後 Alias 自体も解放する。
Function cleanUp()
	int i = 0
	; 第1パス: SexLab 実行中ではないセッションを強制停止する。
	while (i < Sessions.Length)
		Actor s = Sessions[i].getActorRef()
		if (s && !s.hasKeyword(SexLabActive))
			(Sessions[i] as SSLRapeSpell).forceStop()
		endIf
		i += 1
	endWhile
	i = 0
	; 第2パス: Actor が残っている Session Alias をすべてクリアする。
	while (i < Sessions.Length)
		Actor s = Sessions[i].getActorRef()
		if (s)
			Sessions[i].clear()
		endIf
		i += 1
	endWhile
endFunction

; 有効な Pair が残っている間、Quest の再起動を何回延期したかを保持する。
int postponed = 0

; ワールド側の発生率更新と SSLRSRaperQuest の再起動を管理する。
Function raperStart()
	if (isRunning())
		int i = 0
		bool paired = false
		; Pairs[] は2要素ずつ確認し、同じ組の両 Alias が埋まっていれば paired=true とする。
		while (i < Pairs.Length && !paired)
			if (Pairs[i].getRef() && Pairs[i+1].getRef())
				paired = true
			endIf
			i += 2
		endWhile
		; 有効な Pair が無い場合は、SexLab 実行中ではない古い Session Alias を解放する。
		if (!paired)
			i = 0
			while (i < Sessions.Length)
				Actor s = Sessions[i].getActorRef()
				if (s && !s.hasKeyword(SexLabActive))
					Sessions[i].clear()
				endIf
				i += 1
			endWhile
		endIf
		; Pair が存在しない場合、または延期が4回に達した場合は発生率を再計算して Quest を再構築する。
		if (!paired || postponed >= 4)
			postponed = 0
			; デバッグ通知は元コードでコメントアウトされているため、そのまま保持する。
			;debug.notification("RaperWorld: restarting...")
			SSLRSRaperQuest.stop()
			; 現在のゲーム内日付の小数部分だけを取り出し、1日の中の時刻として使用する。
			; cos() の4乗で時間帯による倍率 clockMag を作り、SSLRSMagnitude を掛ける。
			float clock = Utility.getCurrentGameTime() - (Utility.getCurrentGameTime() as int)
			float clockMag = math.pow(math.cos(180*(clock+1/12)), 4)*SSLRSMagnitude.getValue()
			; 各発生率は Default 値 × clockMag で更新する。
			SSLRSRandomRate.setValue(SSLRSRandomRateDefault.getValue()*clockMag)
			SSLRSCourtingRate.setValue(SSLRSCourtingRateDefault.getValue()*clockMag)
			SSLRSPlayerAssaultRate.setValue(SSLRSPlayerAssaultRateDefault.getValue()*clockMag)
			; 時間帯倍率が 0 の場合は Quest を再起動せず、発生処理を止めたままにする。
			if (clockMag != 0.0)
				SSLRSRaperQuest.start()
			endIf
		; Pair が残っている間は即時再起動を避け、最大4回まで延期する。
		else
			postponed += 1
		endIf
		; 次回判定を30秒後に予約する。
		triggerWorld(30)
	endIf
endFunction
