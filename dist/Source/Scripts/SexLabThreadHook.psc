ScriptName SexLabThreadHook extends ReferenceAlias Hidden
{
  実行中のスレッドの動作を操作するインターフェイススクリプト

  **使用する場面**
  Thread Hookは、実行時にSexLabスレッドを読み書きし、必要に応じて動作を変更する明示的なブロッキングフックである
  Modイベントを使う通常のノンブロッキングHookとは異なり、このインターフェイスはSLスレッドの実行を停止し、時間に敏感な情報を
  注入または変更できる。ブロッキングするため、スレッドの実行が一時停止してユーザーがシーンの状態を把握できなくなる可能性があり、
  ユーザー体験を損なうおそれがある。慎重に使用し、ここでの情報処理にかける時間にも注意すること

  **使用方法**
  1) イベントを受け取るReference Aliasオブジェクトを作成する
  2) 独自のカスタムスクリプトを作成して"SexLabThreadHook"を継承し、作成したFormに設定する
  3) このスクリプトにある"@Interface"関数をコピーして作成したスクリプトに貼り付け、実装する
  4) Register()関数（このスクリプト内）を呼び出して、SexLabにHookを登録する。例: OnInit Eventなど
  5) これで完了 \o/。以降、SexLab Threadの実行が特定のポイントに達するたびに、ここに記載されたインターフェイス関数が呼び出される

  **ベストプラクティス**
  1) この機能は時間に敏感なため、特定のスレッド（プレイヤーが関与するものだけなど）を停止したい場合は、以下のロック機構を使うことを強く推奨する
  2) 処理を高速化すること。実行時間がさほど重要でない場面もあるが、他のMod制作者やフレームワーク自体の処理時間にも配慮すること。
      理想的には、プレイヤーがHookや追加の遅延に気付かない状態にする。したがって、コードの実行は速いほどよい
}

; OnInitを上書きする場合は、必ずParent.OnInit()も呼び出すこと
Event OnInit()
  _m = Utility.CreateBoolArray(sslThreadSlots.GetTotalThreadCount(), false)
  If (bAutoegisterOnInit)
    Register()
  EndIf
EndEvent

; ------------------------------------------------------- ;
; --- インターフェイス                                --- ;
; ------------------------------------------------------- ;
;/
  以下の関数は独自スクリプトで実装／オーバーライドする
/;

; スレッドのデータがすべて設定され、再生するアニメーションが選ばれる前に呼び出される
Function OnAnimationStarting(SexLabThread akThread)
EndFunction

; 最初のステージを含め、新しいステージが選ばれるたびに呼び出される
Function OnStageStart(SexLabThread akThread)
EndFunction

; 最後のステージを含め、ステージが終了するたびに呼び出される
Function OnStageEnd(SexLabThread akThread)
EndFunction

; アニメーション終了時に一度呼び出される
Function OnAnimationEnd(SexLabThread akThread)
EndFunction

; ------------------------------------------------------- ;
; --- 登録                                            --- ;
; ------------------------------------------------------- ;
;/
  Hookを登録／解除するための簡易関数
/;

bool Property bAutoegisterOnInit = true Auto
{初期化時にこのHookを自動登録するか。既定値: true}

; 指定されたHookがイベントを受け取るよう登録する
; 登録は新たに開始したスレッドにのみ適用される。すでに実行中のスレッドのイベントは受け取れない
Function Register()
  SexLabUtil.GetAPI().RegisterHook(self)
EndFunction

; 指定されたHookの登録を解除し、イベントを受け取らないようにする
; 登録解除は以降のアニメーションに適用される。現在実行中のスレッドのイベントは引き続き受け取る
Function Unregister()
  SexLabUtil.GetAPI().UnregisterHook(self)
EndFunction

; ------------------------------------------------------- ;
; --- ロック                                          --- ;
; ------------------------------------------------------- ;
;/
  関心のないスレッドの処理を省略する簡易ロックシステム。使用する場合はOnInit()が呼び出されていることを確認する
  実装側でOnInit()をオーバーライドする場合、OnInitイベントを終了する前に"Parent.OnInit()"を呼び出すこと

  **使用例**
  Function OnAnimationStarting(SexLabThread akThread)
    bool ignore_thread_events = ...
    SetLocked(ignore_thread_events)

    ...
  EndFunction

  Function OnStageStart(SexLabThread akThread)
    If (Islocked(akThread))
      return
    EndIf

    ...
  EndFunction
/;
bool[] _m

; 呼び出し元のスレッドがロックされているか返す
bool Function IsLocked(SexLabThread akThread)
  return _m[akThread.GetThreadID()]
EndFunction

; このスレッドのロック状態を設定する
Function SetLocked(SexLabThread akThread, bool abLocked)
  _m[akThread.GetThreadID()] = abLocked
EndFunction
