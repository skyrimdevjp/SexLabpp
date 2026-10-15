Scriptname sslrsattractanteffectscript extends activemagiceffect  

Quest Property SSLRSRaperQuest auto
; この Magic Effect で再起動する Quest。

Event onEffectStart(Actor akCaster, Actor akTarget)
	; 効果開始後、Quest をいったん停止してから再起動し、状態を更新する。
	Utility.wait(0.5)
	SSLRSRaperQuest.stop()
	; Stop() の反映を待ってから Start() する。
	Utility.wait(0.5)
	SSLRSRaperQuest.start()
endEvent
