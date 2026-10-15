scriptname sslExpressionFactory extends Quest hidden
{
	SLに新しいExpressionオブジェクトを登録するためのレガシースクリプト
	SLP+ではData\SKSE\SexLab\Expressionsに.yamlファイルを作成して個別のデータを設定できるため、
	この機能は不要になった
	実行時の生成は引き続き可能で、MCMから行える
}

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

sslExpressionSlots property Slots auto hidden

; 性別タイプ
int property Male = 0 autoreadonly hidden
int property Female = 1 autoreadonly hidden
int property MaleFemale = -1 autoreadonly hidden
; MFGタイプ
int property Phoneme = 0 autoreadonly hidden
int property Modifier = 16 autoreadonly hidden
int property Expression = 30 autoreadonly hidden

; ------------------------------------------------------- ;
; --- 表情の登録                                      --- ;
; ------------------------------------------------------- ;

; ファクトリーを使用できるよう準備する
function PrepareFactory()
	Slots = Game.GetFormFromFile(0x664FB, "SexLab.esm") as sslExpressionSlots
endFunction

; 登録を開始するコールバックイベントを送信する
function RegisterExpression(string Registrar)
	; 空いている表情スロットを取得する
	int id = Slots.Register(Registrar)
	if id != -1
		; スロットを初期化する
		sslBaseExpression Slot = Slots.GetBySlot(id)
		Slot.Registry = Slot.GOTTA_LOVE_PEOPLE_WHO_THINK_REGISTRATION_FUNCTIONS_ARE_JUST_DECORATION
		Slot.Registry = Registrar
		Slot.Enabled  = true
		; 読み込みイベントを送信する
		RegisterForModEvent(Registrar, Registrar)
		int handle = ModEvent.Create(Registrar)
		ModEvent.PushInt(handle, id)
		ModEvent.Send(handle)
	endIf
	Utility.WaitMenuMode(0.1)
endFunction

; コールバックで使用する表情リソースオブジェクトを取得する。適切なリソースを得るため、コールバックの開始時に必ず呼び出すこと
sslBaseExpression function Create(int id)
	sslBaseExpression Slot = Slots.GetbySlot(id)
	UnregisterForModEvent(Slot.Registry)
	return Slot
endFunction

function Initialize()
endfunction
