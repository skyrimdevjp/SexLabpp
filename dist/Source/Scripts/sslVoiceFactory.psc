scriptname sslVoiceFactory extends Quest hidden
{
	VoiceはPapyrusインターフェイス経由で登録しない
	代わりに必要なデータを含む.ymlファイルを作成する
}

; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;
; ----------------------------------------------------------------------------- ;
;               ██╗     ███████╗ ██████╗  █████╗  ██████╗██╗   ██╗              ;
;               ██║     ██╔════╝██╔════╝ ██╔══██╗██╔════╝╚██╗ ██╔╝              ;
;               ██║     █████╗  ██║  ███╗███████║██║      ╚████╔╝               ;
;               ██║     ██╔══╝  ██║   ██║██╔══██║██║       ╚██╔╝                ;
;               ███████╗███████╗╚██████╔╝██║  ██║╚██████╗   ██║                 ;
;               ╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝   ╚═╝                 ;
; ----------------------------------------------------------------------------- ;
; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;

sslVoiceSlots property Slots auto hidden

; 性別タイプ
int property Male = 0 autoreadonly hidden
int property Female = 1 autoreadonly hidden
int property MaleFemale = -1 autoreadonly hidden
int property Creature = 2 autoreadonly hidden
int property CreatureMale = 2 autoreadonly hidden
int property CreatureFemale = 3 autoreadonly hidden

; ------------------------------------------------------- ;
; --- 音声の登録                                      --- ;
; ------------------------------------------------------- ;

; ファクトリーを使用できるよう準備する
function PrepareFactory()
	Slots = Game.GetFormFromFile(0x664FB, "SexLab.esm") as sslVoiceSlots
endFunction

; 登録を開始するコールバックイベントを送信する
function RegisterVoice(string Registrar)
	; 空いている音声スロットを取得する
	int id = Slots.Register(Registrar)
	if id != -1
		; スロットを初期化する
		sslBaseVoice Slot = Slots.GetBySlot(id)
		Slot.Initialize()
		Slot.Registry = Slot.GOTTA_LOVE_PEOPLE_WHO_THINK_REGISTRATION_FUNCTIONS_ARE_JUST_DECORATION
		Slot.Registry = Registrar
		Slot.Enabled = true
		; 読み込みイベントを送信する
		RegisterForModEvent(Registrar, Registrar)
		int handle = ModEvent.Create(Registrar)
		ModEvent.PushInt(handle, id)
		ModEvent.Send(handle)
	endIf
	Utility.WaitMenuMode(0.1)
endFunction

; コールバックで使用する音声リソースオブジェクトを取得する。適切なリソースを得るため、コールバックの開始時に必ず呼び出すこと
sslBaseVoice function Create(int id)
	sslBaseVoice Slot = Slots.GetbySlot(id)
	UnregisterForModEvent(Slot.Registry)
	return Slot
endFunction

function Initialize()
endfunction
