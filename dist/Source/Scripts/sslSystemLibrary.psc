scriptname sslSystemLibrary extends Quest hidden
{
	ライブラリ系スクリプトのベーススクリプト
	SLP+ 2.0ではSLのライブラリ機能の大半がグローバルになったため、このスクリプトのほとんどは使われていない
}

; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;
; ----------------------------------------------------------------------------- ;
;        ██╗███╗   ██╗████████╗███████╗██████╗ ███╗   ██╗ █████╗ ██╗            ;
;        ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗████╗  ██║██╔══██╗██║            ;
;        ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝██╔██╗ ██║███████║██║            ;
;        ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██║╚██╗██║██╔══██║██║            ;
;        ██║██║ ╚████║   ██║   ███████╗██║  ██║██║ ╚████║██║  ██║███████╗       ;
;        ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝       ;
; ----------------------------------------------------------------------------- ;
; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;

; オブジェクトレジストリ
sslThreadSlots property ThreadSlots auto

; ------------------------------------------------------- ;
; --- セットアップ                                    --- ;
; ------------------------------------------------------- ;
;/
	このスクリプトを再初期化／初期化する関数
/;

function LoadLibs(bool Forced = false)
	Form SexLabQuestFramework = Game.GetFormFromFile(0xD62, "SexLab.esm")
	ThreadSlots = SexLabQuestFramework as sslThreadSlots
endFunction

function Setup()
	LoadLibs()
endFunction

; ------------------------------------------------------- ;
; --- ログ                                            --- ;
; ------------------------------------------------------- ;
;/
	汎用ログユーティリティ
/;

Function Log(string Log, string Type = "NOTICE")
  If(Type == "FATAL")
    sslLog.Error(Log)
  Else
    sslLog.Log(Log)
  EndIf
EndFunction

; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;
; ----------------------------------------------------------------------------- ;
;								██╗     ███████╗ ██████╗  █████╗  ██████╗██╗   ██╗							;
;								██║     ██╔════╝██╔════╝ ██╔══██╗██╔════╝╚██╗ ██╔╝							;
;								██║     █████╗  ██║  ███╗███████║██║      ╚████╔╝ 							;
;								██║     ██╔══╝  ██║   ██║██╔══██║██║       ╚██╔╝  							;
;								███████╗███████╗╚██████╔╝██║  ██║╚██████╗   ██║   							;
;								╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝   ╚═╝   							;
; ----------------------------------------------------------------------------- ;
; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;

sslActorLibrary Property ActorLib hidden
	sslActorLibrary Function Get()
			return Game.GetFormFromFile(0xD62, "SexLab.esm") as sslActorLibrary
	EndFunction
EndProperty
sslThreadLibrary property ThreadLib hidden
	sslThreadLibrary Function Get()
		return Game.GetFormFromFile(0xD62, "SexLab.esm") as sslThreadLibrary
	EndFunction
EndProperty
sslAnimationSlots property AnimSlots hidden
	sslAnimationSlots Function Get()
		return Game.GetFormFromFile(0x639DF, "SexLab.esm") as sslAnimationSlots
	EndFunction
EndProperty
sslCreatureAnimationSlots property CreatureSlots hidden
	sslCreatureAnimationSlots Function Get()
		return Game.GetFormFromFile(0x664FB, "SexLab.esm") as sslCreatureAnimationSlots
	EndFunction
EndProperty
sslActorStats property Stats Hidden
	sslActorStats Function Get()
		return Game.GetFormFromFile(0xD62, "SexLab.esm") as sslActorStats
	EndFunction
EndProperty
sslExpressionSlots property ExpressionSlots Hidden
	sslExpressionSlots Function Get()
		return Game.GetFormFromFile(0x664FB, "SexLab.esm") as sslExpressionSlots
	EndFunction
EndProperty
sslVoiceSlots property VoiceSlots Hidden
  sslVoiceSlots Function Get()
	  return Game.GetFormFromFile(0x664FB, "SexLab.esm") as sslVoiceSlots
  EndFunction
EndProperty
sslSystemConfig property Config Hidden
	sslSystemConfig Function Get()
		return SexLabUtil.GetConfig()
	EndFunction
EndProperty
Actor property PlayerRef Hidden
	Actor Function Get()
		return Game.GetPlayer()
	EndFunction
EndProperty

bool property InDebugMode hidden
	bool Function Get()
		return sslSystemConfig.GetSettingBool("bDebugMode")
	EndFunction
EndProperty
event SetDebugMode(bool ToMode)
endEvent

event OnInit()
endEvent
