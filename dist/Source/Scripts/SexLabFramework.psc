ScriptName SexLabFramework extends Quest

; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;
; ----------------------------------------------------------------------------------------------------------------------------------------- ;
;                                                                                                                                           ;
;     ███████╗███████╗██╗  ██╗██╗      █████╗ ██████╗     ███████╗██████╗  █████╗ ███╗   ███╗███████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗    ;
;     ██╔════╝██╔════╝╚██╗██╔╝██║     ██╔══██╗██╔══██╗    ██╔════╝██╔══██╗██╔══██╗████╗ ████║██╔════╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝    ;
;     ███████╗█████╗   ╚███╔╝ ██║     ███████║██████╔╝    █████╗  ██████╔╝███████║██╔████╔██║█████╗  ██║ █╗ ██║██║   ██║██████╔╝█████╔╝     ;
;     ╚════██║██╔══╝   ██╔██╗ ██║     ██╔══██║██╔══██╗    ██╔══╝  ██╔══██╗██╔══██║██║╚██╔╝██║██╔══╝  ██║███╗██║██║   ██║██╔══██╗██╔═██╗     ;
;     ███████║███████╗██╔╝ ██╗███████╗██║  ██║██████╔╝    ██║     ██║  ██║██║  ██║██║ ╚═╝ ██║███████╗╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗    ;
;     ╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝     ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝ ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝    ;
;                                                                                                                                           ;
; ----------------------------------------------------------------------------------------------------------------------------------------- ;
; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;
; ----------------------------------------------------------------------------------------------------------------------------------------- ;
;                                  作成者: Ashal@LoversLab.com [http://www.loverslab.com/user/1-ashal/]                                  ;
; ----------------------------------------------------------------------------------------------------------------------------------------- ;
;                                   SexLab P+ 保守担当: Scrab [https://www.patreon.com/ScrabJoseline]                                   ;
; ----------------------------------------------------------------------------------------------------------------------------------------- ;
; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;

; 現在のSexLabバージョンを表す整数ID
int function GetVersion()
  return SexLabUtil.GetVersion()
endFunction

; 現在のSexLabバージョンを表すユーザー向け文字列
string function GetStringVer()
  return SexLabUtil.GetStringVer()
endFunction

; SexLabが有効で、新しいシーンを開始できる状態か
bool property Enabled hidden
  bool function get()
    return GetState() != "Disabled"
  endFunction
endProperty

; 現在、実行中のSexLabスレッド（アニメーション）があるか
bool property IsRunning hidden
  bool function get()
    return ThreadSlots.IsRunning()
  endFunction
endProperty

; 実行中のシーン数
int property ActiveAnimations hidden
  int function get()
    return ThreadSlots.ActiveThreads()
  endFunction
endProperty

; クリーチャーが現在有効か
bool property AllowCreatures hidden
  bool function get()
    return Config.AllowCreatures
  endFunction
endProperty

; クリーチャーの性別設定が現在有効か
bool property CreatureGenders hidden
  bool function get()
    return Config.UseCreatureGender
  endFunction
endProperty

;#------------------------------------------------------------------------------------------------------------------------------------------#;
;#                                                                                                                                          #;
;#                                                            メインAPI関数                                                            #;
;#                                                                                                                                          #;
;#------------------------------------------------------------------------------------------------------------------------------------------#;

; SexLabシーンを作成する推奨関数
; --- 引数:
; akPositions:    アニメーションさせるアクター
; asTags:         要求するアニメーションタグ（空でも可）。接頭辞 '-' はタグの除外、'~' はOR条件を表す
;                 例: "~A, B, ~C, -D" は、タグBを含み、Dを含まず、AまたはCのいずれかを含むアニメーションを表す
; akSubmissive:   参加アクターのうち1人を指定する。指定した場合、そのアクターはこのアニメーションで従属側として扱われる
; akCenter:       指定すると、すべてのアクターをこのリファレンスの近くまたは上に配置しようとする
; aiFurniture:    家具の優先度。0 - 無効、1 - 許可、2 - 優先
; asHook:         コールバックイベントを受け取るための文字列。詳細は下の「フック」セクションを参照
; --- 戻り値:
; SexLabThread:   開始したシーンを操作するAPIインスタンス。詳細はSexLabThread.pscを参照
; None:           エラーが発生した場合
SexLabThread Function StartScene(Actor[] akPositions, String asTags, Actor akSubmissive = none, ObjectReference akCenter = none, int aiFurniture = 1, String asHook = "")
  return StartSceneA(akPositions, asTags, MakeActorArray(akSubmissive), akCenter, aiFurniture, asHook)
EndFunction
SexLabThread Function StartSceneA(Actor[] akPositions, String asTags, Actor[] akSubmissives, ObjectReference akCenter = none, int aiFurniture = 1, String asHook = "")
  String[] scenes = SexLabRegistry.LookupScenesA(akPositions, asTags, akSubmissives, aiFurniture, akCenter)
  If (!scenes.Length)
    Log("StartScene() - Failed to find valid animations")
    return none
  EndIf
  return StartSceneImpl(akPositions, scenes, asTags, akSubmissives, akCenter, aiFurniture, asHook)
EndFunction

; あらかじめ指定したアニメーションでシーンを開始する
SexLabThread Function StartSceneEx(Actor[] akPositions, String[] asScenes, Actor akSubmissive = none, String asContext = "", \
    ObjectReference akCenter = none, int aiFurniture = 1, String asHook = "")
  return StartSceneExA(akPositions, asScenes, MakeActorArray(akSubmissive), asContext, akCenter, aiFurniture, asHook)
EndFunction
SexLabThread Function StartSceneExA(Actor[] akPositions, String[] asScenes, Actor[] akSubmissives, String asContext = "", \
    ObjectReference akCenter = none, int aiFurniture = 1, String asHook = "")
  return StartSceneImpl(akPositions, asScenes, asContext, akSubmissives, akCenter, aiFurniture, asHook)
EndFunction

; アクター配列の代わりにアクターを個別に受け取るStartSceneのラッパー関数
SexLabThread Function StartSceneQuick(Actor akActor1, Actor akActor2 = none, Actor akActor3 = none, Actor akActor4 = none, Actor akActor5 = none, \
                                        Actor akSubmissive = none, String asTags = "", String asHook = "")
  Actor[] Positions = SexLabUtil.MakeActorArray(akActor1, akActor2, akActor3, akActor4, akActor5)
  return StartScene(Positions, asTags, akSubmissive, asHook = asHook)
EndFunction

;#-----------------------------------------------------------------------------------------------------------------------------------------#
;#                                                                                                                                         #
;#                                                            スレッド関数                                                             #
;#                                                                                                                                         #
;#-----------------------------------------------------------------------------------------------------------------------------------------#

; 指定したスレッドIDに対応するスレッドAPIを取得する
SexLabThread Function GetThread(int aiThreadID)
  return ThreadSlots.GetThread(aiThreadID)
EndFunction

; このアクターを最後にアニメーションさせたスレッドを表すスレッドAPIを取得する
SexLabThread Function GetThreadByActor(Actor akActor)
  return ThreadSlots.GetThreadByActor(akActor)
EndFunction

;#------------------------------------------------------------------------------------------------------------------------------------------#;
;#                                                                                                                                          #;
;#                                                              フック関数                                                              #;
;#                                                                                                                                          #;
;#------------------------------------------------------------------------------------------------------------------------------------------#;
;#------------------------------------------------------------------------------------------------------------------------------------------#;
;#                                                                                                                                          #;
;# SEXLABのフックについて                                                                                                                   #;
;# フックは、スレッド実行中に発生するイベントを利用して、SexLabの実行中スレッドに反応・連携するために使われる                             #;
;#                                                                                                                                          #;
;# SexLabのフックには、ブロッキングとノンブロッキングの2種類がある                                                                   #;
;# より一般的なのはノンブロッキングフックで、アニメーションの進行に非同期で反応するために使う                                         #;
;#   たとえば、アニメーション終了後にストーリーを進めたり、他のアクターのアニメーション開始に反応したりできる                           #;
;# 一方、ブロッキングフックは同期処理であり、フックが戻るまでスレッドの実行を停止する                                                   #;
;#   プレイヤーのゲーム体験への影響が大きいため、使用は必要最小限にすること                                                             #;
;#                                                                                                                                          #;
;#                                                                                                                                          #;   
;# フックの使い方                                                                                                                          #;
;# 1. ノンブロッキングフック                                                                                                                #;
;# ノンブロッキングフックはModイベントを使って処理する。非同期で動作し、保守も容易                                                        #;
;#   使用できるフックはいくつかあるが、どれも同じ手順で設定する:                                                                          #;
;# - まず、次のようにModイベントを登録する:                                                                                                 #;
;#        RegisterForModEvent("Hook<ModEventType>", "<EventName>")                                                                          #;
;#   "ModEventType"を下記のイベント種別（例: AnimationStart）に置き換え、イベント名には任意の名前（例: MyEvent）を指定する             #;
;# - 次に、スクリプト内の別の場所に、次の形式でイベント関数を追加する:                                                                    #;
;#        Event <EventName>(int aiThreadID, bool abHasPlayer)                                                                               #;
;#        EndEvent                                                                                                                          #;
;#   <EventName>は先ほど指定した名前に置き換える。例では "Event MyEvent(int aiThreadID, bool abHasPlayer)"                               #;
;#   これで設定は完了。アニメーション開始時に、登録したイベントを受け取れる                                                               #;
;#                                                                                                                                          #;
;# 1.1 ローカルフック                                                                                                                       #;
;# すべてのイベントではなく、自分が開始したシーンの一部イベントだけに反応したい場合がある                                                 #;
;#   その場合は、このAPIでシーンを要求するときに指定できる "asHook" 引数を使う                                                             #;
;#   この引数により、そのフックを認識しているスレッドだけが送信する専用のスレッド単位フックを作成できる                                 #;
;# ローカルフックの動作はグローバルフックとほぼ同じだが、送信されるイベントIDが少し異なる:                                                 #;
;#   グローバルフックのIDは `Hook<ModEventType>`。ローカルフックでは、特定のフックだけを対象とする接尾辞 `_<MyLocalHookID>` を付ける      #;
;#   たとえば、"AnimationStart" に "MyLocalHook" というローカルフックを設定する場合、IDは `HookAnimationStart_MyLocalHook` となる          #;
;#   開始するスレッドにフックIDを知らせるため、"asHook" 引数に "MyLocalHook" を渡す                                                       #;
;#                                                                                                                                          #;
;# 1.2 イベントの種類                                                                                                                       #;
;#  AnimationStart    - アニメーション開始時に送信                                                                                         #;
;#  AnimationEnd      - アニメーションが完全に終了したときに送信                                                                           #;
;#  LeadInStart       - リードイン付きアニメーションの開始時に送信                                                                          #;
;#  LeadInEnd         - リードインアニメーションの終了時に送信                                                                              #;
;#  StageStart        - 各アニメーションステージの開始時に送信                                                                              #;
;#  StageEnd          - 各アニメーションステージの完了時に送信                                                                              #;
;#  OrgasmStart       - アクターが最終ステージに到達したときに送信                                                                          #;
;#  OrgasmEnd         - 最終ステージの完了時に送信                                                                                          #;
;#  AnimationChange   - ホットキーで再生中のアニメーションが変更されたときに送信                                                            #;
;#  PositionChange    - アニメーションの配置（参加アクター）が変更されたときに送信                                                          #;
;#  ActorsRelocated   - アクターの配置が新たに調整されたときに送信                                                                          #;
;#  ActorChangeStart  - ChangeActors関数の呼び出し時に送信                                                                                 #;
;#  ActorChangeEnd    - ChangeActors関数によるアクターの交代が完了したときに送信                                                            #;
;#                                                                                                                                          #;
;#                                                                                                                                          #;
;# 2. ブロッキングフック                                                                                                                   #;
;# もう一つのより複雑な種類がブロッキングフック。スレッドの実行を停止するため、通常は使用を避けること                                   #;
;#   ただし、時間が重要で非同期フックでは対応できない状況もある                                                                            #;
;# ブロッキングフックを実装するには、新しいReferenceAliasを作成してスクリプトを割り当てる                                                 #;
;#   スクリプト名は任意だが、"ReferenceAlias" ではなく "SexLabThreadHook" を継承し、プロパティを設定する必要がある                        #;
;#   これで実装は完了。フックの実際の使い方は "SexLabThreadHook.psc" を参照                                                                 #;
;#                                                                                                                                          #;
;#------------------------------------------------------------------------------------------------------------------------------------------#;

; 実行中のスレッドからイベントを受け取るブロッキングフックを登録する
; フックの登録に成功した場合はtrueを返す
bool Function RegisterHook(SexLabThreadHook akHook)
  return Config.AddHook(akHook)
EndFunction

; フックの登録を解除し、イベントを受け取らないようにする
; フックの登録解除に成功した場合はtrueを返す
bool Function UnregisterHook(SexLabThreadHook akHook)
  return Config.RemoveHook(akHook)
EndFunction

; 指定したフックが現在登録されているか確認する
bool Function IsHooked(SexLabThreadHook akHook)
  return Config.IsHooked(akHook)
EndFunction

;#-----------------------------------------------------------------------------------------------------------------------------------------#
;#                                                                                                                                         #
;#                                                             アクター関数                                                             #
;#                  アニメーションに参加するアクターを操作し、情報を取得する関数                                                         #;
;#                                                                                                                                         #
;#-----------------------------------------------------------------------------------------------------------------------------------------#

; このアクターが現在SexLabスレッドでアニメーション中か
bool function IsActorActive(Actor ActorRef)
  return ActorRef.IsInFaction(AnimatingFaction)
endFunction

; このアクターの性別を返す
; 対応値: Male = 0 | Female = 1 | Futa = 2 | CrtMale = 3 | CrtFemale = 4
int Function GetSex(Actor akActor)
  return SexlabRegistry.GetSex(akActor, false)
EndFunction
int[] Function GetSexAll(Actor[] akPositions)
  return sslActorLibrary.GetSexAll(akPositions)
EndFunction

; SexLabでアクターを男性、女性、またはフタとして扱うよう強制する
; --- 引数:
; akActor:    性別を上書きするアクター
; aiSexTag:   アクターに設定する性別。0 - Male、1 - Female、2 - Futa
Function TreatAsSex(Actor akActor, int aiSexTag)
  ActorLib.TreatAsSex(akActor, aiSexTag)
EndFunction
Function TreatAsMale(Actor ActorRef)
  TreatAsSex(ActorRef, 0)
EndFunction
Function TreatAsFemale(Actor ActorRef)
  TreatAsSex(ActorRef, 1)
EndFunction
Function TreatAsFuta(Actor ActorRef)
  TreatAsSex(ActorRef, 2)
EndFunction

; "TreatAsSex" で設定した性別の強制指定を解除する
Function ClearForcedSex(Actor akActor)
  ActorLib.ClearForcedSex(akActor)
EndFunction

; アクター配列を受け取り、配列内の各性別の人数を表す長さ5の配列を作成する
; 戻り値の各インデックスは、配列内の該当する性別の人数を表す:
;   [0] 人間の男性の数
;   [1] 人間の女性の数
;   [2] 人間のフタの数
;   [3] クリーチャーの男性の数
;   [4] クリーチャーの女性の数
int[] Function CountSexAll(Actor[] akPositions)
  return sslActorLibrary.CountSexAll(akPositions)
EndFunction
int Function CountMale(Actor[] akPositions)
	return sslActorLibrary.CountMale(akPositions)
EndFunction
int Function CountFemale(Actor[] akPositions)
	return sslActorLibrary.CountFemale(akPositions)
EndFunction
int Function CountFuta(Actor[] akPositions)
	return sslActorLibrary.CountFuta(akPositions)
EndFunction
int Function CountCreatures(Actor[] akPositions)
	return sslActorLibrary.CountCreatures(akPositions)
EndFunction
int Function CountCrtMale(Actor[] akPositions)
	return sslActorLibrary.CountCrtMale(akPositions)
EndFunction
int Function CountCrtFemale(Actor[] akPositions)
	return sslActorLibrary.CountCrtFemale(akPositions)
EndFunction

; 指定したアクターがSexLabアニメーションの対象として有効か確認する
; --- 戻り値:
;     1 = アクターは有効。それ以外は以下の理由を示す:
;    -1 = アクターが存在しない（None）
;    -2 = アクターの種族が無効
;   -10 = アクターはすでにSexLabアニメーションに参加している
;   -11 = アクターはSexLabアニメーションへの参加を禁止されている
;   -12 = アクターの3Dモデルが読み込まれていない
;   -13 = アクターが死亡している
;   -14 = アクターが無効化されている（モデルまたはAI）
;   -15 = アクターが飛行中（SexLabアニメーションを実行できない）
;   -16 = アクターが騎乗中（SexLabアニメーションを実行できない）
;   -17 = アクターはクリーチャーだが、クリーチャーアニメーションが無効
;   -18 = アクターはSexLabでサポートされていないクリーチャー
int function ValidateActor(Actor ActorRef)
  return ActorLib.ValidateActor(ActorRef)
endFunction
bool function IsValidActor(Actor ActorRef)
  return ActorLib.ValidateActor(ActorRef) == 1
endFunction

;/* ForbidActor
* * アクターがSexLabアニメーションに参加できないよう禁止する。
* * @param: ActorRef - SexLabでの使用を禁止するアクター。
*/;
function ForbidActor(Actor ActorRef)
  ActorLib.ForbidActor(ActorRef)
endFunction

;/* AllowActor
* * 禁止リストからアクターを削除し、ForbidActor()の効果を取り消す。
* * 
* * @param: ActorRef - 禁止リストから削除するアクター。
*/;
function AllowActor(Actor ActorRef)
  ActorLib.AllowActor(ActorRef)
endFunction

;/* IsForbidden
* * アクターが現在SexLabシーンでの使用を禁止されているか確認する。
* * 
* * @param: ActorRef - 確認するアクター。
* * @return: 使用が禁止されている場合はtrue。
*/;
bool function IsForbidden(Actor ActorRef)
  return ActorLib.IsForbidden(ActorRef)
endFunction

; ---------------------------------------------------
; * 精液エフェクト関数
; ---------------------------------------------------
; 注意: ここにある一部の関数は `int aiType` 引数を取る。有効な値は次の場所を参照:
; https://github.com/Scrabx3/SexLabpp/blob/master/src/Registry/CumFx.h（FxType enum）またはsslActorLibrary.pscを参照（内容が異なる場合はCumFx.hを優先）。
; aiTypeを-1にすると、すべての種類が対象になる。

; 指定した種類のインタラクションに対応する精液エフェクトをアクターに適用する
Function AddCumFx(Actor akActor, int aiType)
  ActorLib.AddCumFx(akActor, aiType)
EndFunction
Function AddCumFxLayers(Actor akActor, int aiType, int aiLayers)
  int i = 0
  While (i < aiLayers)
    AddCumFx(akActor, aiType)
    i += 1
  EndWhile
EndFunction

; 指定した種類のインタラクションに対応する精液エフェクトをアクターから削除する
Function RemoveCumFx(Actor akActor, int aiType = -1)
  ActorLib.RemoveCumFx(akActor, aiType)
EndFunction

; アクターに適用されている精液エフェクトの重ね掛け数を数える
int Function CountCumFx(Actor ActorRef, int aiType = -1)
  return ActorLib.CountCumFx(ActorRef, aiType)
EndFunction
int Function CountCumVaginal(Actor ActorRef)
  return ActorLib.CountCumFx(ActorRef, ActorLib.FX_Vaginal)
EndFunction
int Function CountCumOral(Actor ActorRef)
  return ActorLib.CountCumFx(ActorRef, ActorLib.FX_ORAL)
EndFunction
int Function CountCumAnal(Actor ActorRef)
  return ActorLib.CountCumFx(ActorRef, ActorLib.FX_ANAL)
EndFunction

;/* StripActor
* * SexLab MCMでユーザーが設定した装備解除設定に従って、アクターの装備を解除する。
* * 
* * @param: Actor ActorRef - 装備を解除するアクター。
* * @param: Actor VictimRef [任意] - ActorRefと一致する場合は被害者用の設定を使う。指定されていて一致しない場合は加害者用の設定を使う。
* * @param: bool DoAnimate [任意、既定値true] - 装備解除中にアクターの脱衣アニメーションを再生するか。
* * @param: bool LeadIn [任意、既定値false] - trueかつVictimRef == noneの場合、前戯時の装備解除設定を使う。
* * @return: Form[] - ActorRefから解除した装備の配列。
*/;
Form[] function StripActor(Actor ActorRef, Actor VictimRef = none, bool DoAnimate = true, bool LeadIn = false)
  return ActorLib.StripActor(ActorRef, VictimRef, DoAnimate, LeadIn)
endFunction

;/* StripSlots
* * 二足オブジェクト／スロットマスクを独自に選択して、アクターの装備を解除する。
* * スロット値は http://www.creationkit.com/Biped_Object を参照。
* * 
* * @param: Actor ActorRef - 装備を解除するアクター。
* * @param: bool[] Strip - 長さが正確に33のbool配列を必ず指定する。trueの要素に対応する装備を解除する（配列のインデックス + 30 = 二足オブジェクト／スロットマスク）。追加要素Strip[32]は武器の解除に使う。
* * @param: bool DoAnimate - 装備解除中にアクターの脱衣アニメーションを再生するか。
* * @param: bool AllowNudesuit - MCMで有効にしている場合、ヌードスーツの使用を許可するか。
* * @return: Form[] - ActorRefから解除した装備の配列。
*/;
Form[] function StripSlots(Actor ActorRef, bool[] Strip, bool DoAnimate = false, bool AllowNudesuit = true)
  return ActorLib.StripSlots(ActorRef, Strip, DoAnimate, AllowNudesuit)
endFunction

;/* UnstripActor
* * 指定した装備をアクターに装備させる。Strip系関数の戻り値を使い、装備解除の結果を元に戻す用途を想定。
* * 
* * @param: Actor ActorRef - 装備を再装備するアクター。
* * @param: Form[] Stripped - ActorRefに装備するアイテムのForm配列。通常はStripActor()またはStripSlots()の戻り値を保存したもの。
* * @param: bool IsVictim - trueかつSexLab MCMの「被害者の再装備」が無効の場合、実際には装備を再装備しない。
*/;
function UnstripActor(Actor ActorRef, Form[] Stripped, bool IsVictim = false)
  ActorLib.UnstripActor(ActorRef, Stripped, IsVictim)
endFunction

;/* IsStrippable
* * 指定したアイテムをSexLabの装備解除関数でアクターから外せるか確認する。
* * 
* * @param: Form ItemRef - 確認するアイテム。
* * @return: bool - アイテムに "NoStrip" を含むキーワードがなく、またはSexLab MCMの装備解除エディターで「常に解除」に設定されている場合はtrue。
*/;
bool function IsStrippable(Form ItemRef)
  return ActorLib.IsStrippable(ItemRef)
endFunction

;/* StripSlot
* * 指定したスロットマスクの位置にあるアイテムをアクターから取り外す。
* * SexLabで装備解除可能と判定されたアイテムのみを外す。
* * 
* * @param: Actor ActorRef - 指定スロットの装備を外すアクター。
* * @param: int SlotMask - 対象の二足オブジェクトに対応するスロットマスクID。詳細は http://www.creationkit.com/Slot_Masks_-_Armor を参照。
* * @return: Form - 取り外した場合はスロットマスクに装備されていたアイテム。取り外さなかった場合、または装備がなかった場合はNone。
*/;
Form function StripSlot(Actor ActorRef, int SlotMask)
  return ActorLib.StripSlot(ActorRef, SlotMask)
endFunction

;/* WornStrapon
* * アクターが装備中のものから、SexLabに登録済みのストラップオンを探して返す（登録方法はLoadStrapon()を参照）。
* * 
* * @param: Actor ActorRef - ストラップオンを検索するアクター。
* * @return: Form - アクターが装備中のSexLab登録済みストラップオン。見つからない場合はNone。
*/;
Form function WornStrapon(Actor ActorRef)
  return Config.WornStrapon(ActorRef)
endFunction

;/* HasStrapon
* * アクターがSexLab登録済みのストラップオンを装備中、または所持しているか確認する。
* * 
* * @param: Actor ActorRef - ストラップオンを確認するアクター。
* * @return: bool - SexLab登録済みのストラップオンを装備中または所持している場合はtrue。
*/;
bool function HasStrapon(Actor ActorRef)
  return Config.HasStrapon(ActorRef)
endFunction

;/* PickStrapon
* * アクターが使用するストラップオンをSexLab登録済みのものから選ぶ。
* * 
* * @param: Actor ActorRef - 使用するストラップオンを選ぶアクター。
* * @return: Form - ランダムに選んだストラップオン。所持品にすでにある場合はそのストラップオン。
*/;
Form function PickStrapon(Actor ActorRef)
  return Config.PickStrapon(ActorRef)
endFunction

; 防具オブジェクトを使用可能なストラップオンの一覧に追加する
; --- 引数:
; esp:    検索対象のオブジェクトを含む.esp/.esmファイル
; id:     オブジェクトのForm ID
; --- 戻り値:
; Armor:  一覧に追加されたオブジェクト
; None:   指定したespとForm IDに該当するFormがない場合
Armor function LoadStrapon(string esp, int id)
  return Config.LoadStrapon(esp, id)
EndFunction
Function LoadStraponEx(Armor akStrapon)
  Config.LoadStraponEx(akStrapon)
EndFunction

;#-----------------------------------------------------------------------------------------------------------------------------------------#
;#                                                                                                                                         #
;#                                                       ベッド関数開始                                                            #
;#                                                                                                                                         #
;#-----------------------------------------------------------------------------------------------------------------------------------------#

;/* FindBed
* * 指定した中心点から指定半径内のベッドを検索し、そのObjectReferenceを返す。
* * 
* * @param: ObjectReference CenterRef - 検索の中心点として使うオブジェクト、アクター、またはマーカー。
* * @param: float Radius - CenterRefからベッドを検索する半径。
* * @param: bool IgnoreUsed - ベッドの使用中アクターを確認し、使用中の場合は検索結果から除外するか。
* * @param: ObjectReference IgnoreRef1/IgnoreRef2 - 検索範囲内にあっても除外するベッド。
* * @return: ObjectReference - 半径内で見つかった有効なベッド。見つからない場合はNONE。
*/;
ObjectReference function FindBed(ObjectReference CenterRef, float Radius = 1000.0, bool IgnoreUsed = true, ObjectReference IgnoreRef1 = none, ObjectReference IgnoreRef2 = none)
  return ThreadLib.FindBed(CenterRef, Radius, IgnoreUsed, IgnoreRef1, IgnoreRef2)
endFunction

;/* IsBedRoll
* * 指定したベッドが寝袋として扱われるか確認する。
* * 
* * @param: ObjectReference BedRef - 確認するベッドオブジェクト。
* * @return: bool - BedRefが寝袋として扱われる場合はtrue。
*/;
bool function IsBedRoll(ObjectReference BedRef)
  return ThreadLib.IsBedRoll(BedRef)
endFunction

;/* IsDoubleBed
* * 指定したベッドが二人用ベッドとして扱われるか確認する。
* * 
* * @param: ObjectReference BedRef - 確認するベッドオブジェクト。
* * @return: bool - BedRefが二人用ベッドとして扱われる場合はtrue。
*/;
bool function IsDoubleBed(ObjectReference BedRef)
  return ThreadLib.IsDoubleBed(BedRef)
endFunction

;/* IsSingleBed
* * 指定したベッドが一人用ベッドとして扱われるか確認する。
* * 
* * @param: ObjectReference BedRef - 確認するベッドオブジェクト。
* * @return: bool - BedRefが一人用ベッドとして扱われる場合はtrue。
*/;
bool function IsSingleBed(ObjectReference BedRef)
  return ThreadLib.IsSingleBed(BedRef)
endFunction

;/* IsBedAvailable
* * 指定したベッドが他のアクターに使用されているか確認する。
* * 
* * @param: ObjectReference BedRef - 確認するベッドオブジェクト。
* * @return: bool - BedRefが未使用ならtrue。NPCが眠っているか、別のSexLabスレッドが使用中ならfalse。
*/;
bool function IsBedAvailable(ObjectReference BedRef)
  return ThreadLib.IsBedAvailable(BedRef)
endFunction

;/* AddCustomBed
* * アニメーション開始時にSexLabが検索するベッドの一覧に新しいベッドを追加する。
* * 
* * @param: Form BaseBed - 追加するベッドのベースオブジェクト。
* * @param: int BedType - ベッドの種類。0 = 通常のベッド、1 = 寝袋、2 = 二人用ベッド。
* * @return: bool - ベッド一覧への追加に成功した場合はtrue。
*/;
bool function AddCustomBed(Form BaseBed, int BedType = 0)
  return Config.AddCustomBed(BaseBed, BedType)
endFunction

;/* SetCustomBedOffset
* * 指定したベッドのベースオブジェクトについて、アニメーション中に使うSexLab既定のオフセット[30, 0, 37, 0]を上書きする。
* * 
* * @param: Form BaseBed - 独自オフセットを設定するベッドのベースオブジェクト。
* * @param: float Forward - アニメーション中、アクターをベッド上で前方へ移動させる量。
* * @param: float Sideward - アニメーション中、アクターをベッド上で横方向へ移動させる量。
* * @param: float Upward - アニメーション中、アクターをベッド上で上方向へ移動させる量（注意: 寝袋では無視される）。
* * @param: float Rotation - アニメーション中、ベッド上でアクターを回転させる量。
* * @return: bool - ベッドの既定オフセットを正常に上書きできた場合はtrue。
*/;
bool function SetCustomBedOffset(Form BaseBed, float Forward = 30.0, float Sideward = 0.0, float Upward = 37.0, float Rotation = 0.0)
  return Config.SetCustomBedOffset(BaseBed, Forward, Sideward, Upward, Rotation)
endFunction

;/* ClearCustomBedOffset
* * SetCustomBedOffset()で設定したベッドオフセットの上書きを削除し、SexLabの既定値に戻す。
* * 
* * @param: Form BaseBed - 独自オフセットを削除するベッドのベースオブジェクト。
* * @return: bool - 既定オフセットへの復元に成功した場合はtrue。元から独自設定がなかった場合はfalse。
*/;
bool function ClearCustomBedOffset(Form BaseBed)
  return Config.ClearCustomBedOffset(BaseBed)
endFunction

;/* GetBedOffsets
* * 指定したベッドに適用されるオフセットの配列を取得する。
* * @param: ObjectReference BedRef - オフセットを取得するベッドオブジェクト。
* * @return: float[] - [Forward, Sideward, Upward, Rotation]の順のオフセット配列。独自設定がなければ既定値を返す。
*/;
float[] function GetBedOffsets(Form BaseBed)
  return Config.GetBedOffsets(BaseBed)
endFunction

;#-----------------------------------------------------------------------------------------------------------------------------------------#
;#                                                                                                                                         #
;#                                                        トラッキング関数開始                                                             #
;#                                                                                                                                         #
;#-----------------------------------------------------------------------------------------------------------------------------------------#


;#-----------------------------------------------------------------------------------------------------------------------------------------#
;#                                                                                                                                         #
;#  トラッキングの使い方                                                                                                                   #
;#                                                                                                                                         #
;# アクターは、個別に追跡対象として指定するか、追跡対象の派閥に所属している場合にトラッキングされる                                       #
;# トラッキング対象のアクターは専用のModイベントを受け取る                                                                                 #
;# 注意: プレイヤーには、コールバック "PlayerTrack" による既定のトラッキングイベントが設定されている                                        #
;#                                                                                                                                         #
;# 既定のトラッキングイベントの種類はAdded、Start、End、Orgasm                                                                            #
;# それぞれ、アクターのスレッドへの追加、アニメーション開始、アニメーション終了、オーガズム発生に対応する                                 #
;#                                                                                                                                         #
;# アクターまたは派閥にコールバックを登録すると、"<custom callback>_<event type>" という名前のModイベントが送信される                       #
;#                                                                                                                                         #
;# 例:                                                                                                                                     #
;# 特定のアクターがSexLabアニメーションを終了するたびに処理を実行するには、次のようにする:                                                 #
;#                                                                                                                                         #
;#  Actor myActor = ...                              <-- 任意の方法でアクターを取得                                                        #
;#  SexLab.TrackActor(ActorRef, "MyHook")            <-- アクターの追跡を開始し、MyHookをフック名として使う                                #
;#  RegisterForModEvent("MyHook_End", "DoSomething")                                                                                        #
;#                                                                                                                                         #
;#  Event DoSomething(Form FormRef, int tid)                                                                                               #
;#    Debug.MessageBox("アクター " + myActor.getDisplayname() + " がアニメーションを終了しました。")                                        #
;#  EndEvent                                                                                                                               #
;#                                                                                                                                         #
;# 受信イベントの第1引数FormRefはアクター（必要に応じて型変換すること）                                                                     #
;# 第2引数tidはスレッドコントローラーのID                                                                                                   #
;#                                                                                                                                         #
;# イベント管理の詳細はフックのセクションを参照                                                                                             #
;#                                                                                                                                         #
;#                                                                                                                                         #
;# 注意: 以下の関数のCallback引数は関数ではなく、生成されるイベント名の一部                                                                 #
;#                                                                                                                                         #
;#                                                                                                                                         #
;#-----------------------------------------------------------------------------------------------------------------------------------------#

;/* TrackActor
* * 特定のアクターに一意のコールバックModイベントを関連付け、SexLabアニメーション中にそのアクターが特定の動作をしたときに送信する。
* * <Callback>_<Event>という名前のイベントをRegisterForModEventsで登録する。イベントの種類は次のとおり:
* * "Added" - アクターがSexLabアニメーションに追加された
* * "Start" - アクターが参加するSexLabアニメーションが開始した
* * "Orgasm" - アクターがオーガズムに達した
* * "End" - アクターが参加するSexLabアニメーションが終了した
* * 
* * @param: Actor ActorRef - トラッキングイベントを受け取る対象のアクター。
* * @param: string Callback - このアクターに関連付ける一意のコールバック名。
*/;
function TrackActor(Actor ActorRef, string Callback)
  ThreadLib.TrackActor(ActorRef, Callback)
endFunction

;/* UntrackActor
* * アクターから関連付けられたコールバック名を削除する。
* * このアクターには、<Callback>_Start、<Callback>_End、<Callback>_Orgasm、<Callback>_AddedのModイベントが送信されなくなる。
* * 注意: プレイヤーの登録は解除しないこと。一部の古いModが動作しなくなる可能性がある。
* * 
* * @param: Actor ActorRef - トラッキングイベントを解除するアクター。
* * @param: string Callback - 無効にする一意のコールバックイベント名。
*/;
function UntrackActor(Actor ActorRef, string Callback)
  ThreadLib.UntrackActor(ActorRef, Callback)
endFunction

;/* 
* * 特定の派閥に一意のコールバックModイベントを関連付け、その派閥に属するアクターがSexLabアニメーション中に特定の動作をしたときに送信する。
* * <Callback>_<Event>という名前のイベントをRegisterForModEventsで登録する。イベントの種類は次のとおり:
* * "Added" - アクターがSexLabアニメーションに追加された
* * "Start" - アクターが参加するSexLabアニメーションが開始した
* * "Orgasm" - アクターがオーガズムに達した
* * "End" - アクターが参加するSexLabアニメーションが終了した
* * 
* * @param: Faction FactionRef - 所属アクターにトラッキングイベントを送る派閥。
* * @param: string Callback - この派閥のアクターに関連付ける一意のコールバック名。
*/;
function TrackFaction(Faction FactionRef, string Callback)
  ThreadLib.TrackFaction(FactionRef, Callback)
endFunction

;/* UntrackFaction
* * 派閥から関連付けられたコールバックを削除する。
* * 
* * @param: Faction FactionRef - トラッキングイベントを解除する派閥。
* * @param: string Callback - 無効にする一意のコールバックイベント名。
*/;
function UntrackFaction(Faction FactionRef, string Callback)
  ThreadLib.UntrackFaction(FactionRef, Callback)
endFunction

;/* IsActorTracked
* * 指定したアクターがトラッキングイベントを受け取るか確認する。プレイヤーの場合、組み込みの "PlayerTrack" コールバックにより常にtrueを返す。
* * 
* * @param: Actor ActorRef - 確認するアクター。
* * @return: bool - 関連付けられたコールバックがあるか、トラッキング対象の派閥に属している場合はtrue。
*/;
bool function IsActorTracked(Actor ActorRef)
  return ThreadLib.IsActorTracked(ActorRef)
endFunction

;#-----------------------------------------------------------------------------------------------------------------------------------------#
;#                                                                                                                                         #
;#                                                          ボイス関数開始                                                          #
;#                                                                                                                                         #
;#-----------------------------------------------------------------------------------------------------------------------------------------#

; このアクターに合うボイスを選択する
; --- 引数
; akActor:  ボイスを選ぶ対象のアクター。タグ指定版ではnoneでもよく、その場合は指定タグに合うボイスを選択する
; asTags:   タグ文字列またはタグ配列。接頭辞（-/~）に対応
; --- 戻り値:
; 一意のボイスオブジェクトを表す文字列ID
String Function SelectVoice(Actor akActor)
  sslVoiceSlots.SelectVoice(akActor)
EndFunction
String Function SelectVoiceByTags(Actor akActor, String asTags)
  sslVoiceSlots.SelectVoiceByTags(akActor, asTags)
EndFunction
String Function SelectVoiceByTagsA(Actor akActor, String[] asTags)
  sslVoiceSlots.SelectVoiceByTagsA(akActor, asTags)
EndFunction

; ランダム選択より優先してこのアクターに使うボイスを登録する
Function StoreVoice(Actor akActor, String asVoice)
  sslVoiceSlots.StoreVoice(akActor, asVoice)
EndFunction
bool Function HasStoredVoice(Actor akActor)
  return GetStoredVoice(akActor) != ""
EndFunction
String Function GetStoredVoice(Actor akActor)
  return sslVoiceSlots.GetSavedVoice(akActor)
EndFunction
Function ClearVoice(Actor akActor)
  sslVoiceSlots.DeleteVoice(akActor)
EndFunction

;#-----------------------------------------------------------------------------------------------------------------------------------------#
;#                                                                                                                                         #
;#  ^^^                                                      ボイス関数終了                                                      ^^^  #
;#                                                                                                                                         #
;#-----------------------------------------------------------------------------------------------------------------------------------------#

;#-----------------------------------------------------------------------------------------------------------------------------------------#
;#                                                                                                                                         #
;#                                                        表情関数開始                                                        #
;#                                                                                                                                         #
;#-----------------------------------------------------------------------------------------------------------------------------------------#

;/* GetCurrentMFG
* * アクターに現在適用されているムード、音素、モディファイアを配列で取得する。
* * sslBaseExpressionsのグローバル関数と同等の関数。スクリプトでは、この関数ではなくグローバル関数の使用を推奨。
* *
* * @param: Actor ActorRef - 表情値を取得するアクター。
* * @return: float[] - 長さ32のfloat配列。ApplyPresetFloats関数のPreset引数と同じ形式・構造。
*/;
float[] function GetCurrentMFG(Actor ActorRef)
  return sslBaseExpression.GetCurrentMFG(ActorRef)
endFunction

;/* ClearMFG
* * アクターのムード、音素、モディファイアをリセットする。
* * sslBaseExpressionsのグローバル関数と同等の関数。スクリプトでは、この関数ではなくグローバル関数の使用を推奨。
* *
* * @param: Actor ActorRef - 表情を通常の状態に戻すアクター。
*/;
function ClearMFG(Actor ActorRef)
  sslBaseExpression.ClearMFG(ActorRef)
endFunction

;/* ClearPhoneme
* * アクターのすべての音素を0にリセットする。
* * sslBaseExpressionsのグローバル関数と同等の関数。スクリプトでは、この関数ではなくグローバル関数の使用を推奨。
* *
* * @param: Actor ActorRef - 音素をリセットするアクター。
*/;
function ClearPhoneme(Actor ActorRef)
  sslBaseExpression.ClearPhoneme(ActorRef)
endFunction

;/* ClearModifier
* * アクターのすべてのモディファイアを0にリセットする。
* * sslBaseExpressionsのグローバル関数と同等の関数。スクリプトでは、この関数ではなくグローバル関数の使用を推奨。
* *
* * @param: Actor ActorRef - モディファイアをリセットするアクター。
*/;
function ClearModifier(Actor ActorRef)
  sslBaseExpression.ClearModifier(ActorRef)
endFunction

;/* ApplyPresetFloats
* * 値の配列をアクターに適用し、音素、モディファイア、ムードを自動的に設定する。
* * sslBaseExpressionsのグローバル関数と同等の関数。スクリプトでは、この関数ではなくグローバル関数の使用を推奨。
* *
* * @param: Actor ActorRef - プリセットを適用するアクター。
* * @param: float[] Preset - 長さ32の配列を指定する。各インデックスはMFG IDに対応する。ムード種別を除き、値の範囲は0.0～1.0。
* *                          音素       0-15 = Preset[0]  ～ Preset[15]
* *                          モディファイア 0-13 = Preset[16] ～ Preset[29]
* *                          ムード種別      = Preset[30]
* *                          ムード値        = Preset[31]
*/;
function ApplyPresetFloats(Actor ActorRef, float[] Preset)
  sslBaseExpression.ApplyPresetFloats(ActorRef, Preset)
endfunction

;#-----------------------------------------------------------------------------------------------------------------------------------------#
;#                                                                                                                                         #
;#                                                         ユーティリティ関数開始                                                         #
;#                                                                                                                                         #
;#-----------------------------------------------------------------------------------------------------------------------------------------#

; 引数に指定されたアクターのうち、noneではないものだけを含む配列を作成する
Actor[] Function MakeActorArray(Actor Actor1 = none, Actor Actor2 = none, Actor Actor3 = none, Actor Actor4 = none, Actor Actor5 = none)
  return SexLabUtil.MakeActorArray(Actor1, Actor2, Actor3, Actor4, Actor5)
EndFunction

; 秒数をHH:MM:SS形式に変換する
String Function ParseTime(int time)
  return sslActorStats.ParseTime(time)
EndFunction

; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;
; ----------------------------------------------------------------------------------------------------------------------------------------- ;
;                                                                                                                                           ;
;                                      ██╗███╗   ██╗████████╗███████╗██████╗ ███╗   ██╗ █████╗ ██╗                                          ;
;                                      ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗████╗  ██║██╔══██╗██║                                          ;
;                                      ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝██╔██╗ ██║███████║██║                                          ;
;                                      ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██║╚██╗██║██╔══██║██║                                          ;
;                                      ██║██║ ╚████║   ██║   ███████╗██║  ██║██║ ╚████║██║  ██║███████╗                                     ;
;                                      ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝                                     ;
;                                                                                                                                           ;
; ----------------------------------------------------------------------------------------------------------------------------------------- ;
; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;
; ----------------------------------------------------------------------------------------------------------------------------------------- ;
;                                                     公開APIはここまで                                                                    ;
;                                    以下の関数やプロパティは使用・参照しないこと                                                        ;
; ----------------------------------------------------------------------------------------------------------------------------------------- ;
; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;

;#-----------------------------------------------------------------------------------------------------------------------------------------#;
;#                                                                                                                                         #;
;#                                                 非推奨関数 - 使用しないこと                                                            #;
;#         Modで使用している場合は、使いやすさとパフォーマンスに優れた対応する新しい関数に置き換えること。                               #;
;#                                                                                                                                         #;
;#-----------------------------------------------------------------------------------------------------------------------------------------#;

;/ 非推奨 /;
sslThreadController function HookController(string argString)
  return ThreadSlots.GetController(argString as int)
endFunction

;/* 非推奨 */;
sslBaseAnimation function HookAnimation(string argString)
  return ThreadSlots.GetController(argString as int).Animation
endFunction

;/* 非推奨 */;
int function HookStage(string argString)
  return ThreadSlots.GetController(argString as int).Stage
endFunction

;/* 非推奨 */;
Actor function HookVictim(string argString)
  return ThreadSlots.GetController(argString as int).VictimRef
endFunction

;/* 非推奨 */;
Actor[] function HookActors(string argString)
  return ThreadSlots.GetController(argString as int).Positions
endFunction

;/* 非推奨 */;
float function HookTime(string argString)
  return ThreadSlots.GetController(argString as int).TotalTime
endFunction

;/* 非推奨 */;
bool function HasCreatureAnimation(Race CreatureRace, int Gender = -1)
  return CreatureSlots.RaceHasAnimation(CreatureRace, -1, Gender)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] function GetAnimationsByTag(int ActorCount, string Tag1, string Tag2 = "", string Tag3 = "", string TagSuppress = "", bool RequireAll = true)
  return AnimSlots.GetByTags(ActorCount, sslUtility.MakeArgs(",", Tag1, Tag2, Tag3), TagSuppress, RequireAll)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] function GetCreatureAnimationsByTags(int ActorCount, string Tags, string TagSuppress = "", bool RequireAll = true)
  return CreatureSlots.GetByTags(ActorCount, Tags, TagSuppress, RequireAll)
endFunction

;/* 非推奨 */;
sslBaseVoice function GetVoiceByTag(string Tag1, string Tag2 = "", string TagSuppress = "", bool RequireAll = true)
  return VoiceSlots.GetByTags(sslUtility.MakeArgs(",", Tag1, Tag2), TagSuppress, RequireAll)
endFunction

;/* 非推奨 */;
function ApplyCum(Actor ActorRef, int CumID)
  ActorLib.ApplyCum(ActorRef, CumID)
endFunction

;/* 非推奨 */;
form function StripWeapon(Actor ActorRef, bool RightHand = true)
  return none ; ActorLib.StripWeapon(ActorRef, RightHand)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] property Animations hidden
  sslBaseAnimation[] function get()
    return AnimSlots.GetSlots(0, 128)
  endFunction
endProperty

;/* 非推奨 */;
sslBaseAnimation[] property CreatureAnimations hidden
  sslBaseAnimation[] function get()
    return CreatureSlots.GetSlots(0, 128)
  endFunction
endProperty

;/* 非推奨 */;
sslBaseVoice[] property Voices hidden
  sslBaseVoice[] function get()
    return VoiceSlots.Voices
  endFunction
endProperty

;/* 非推奨 */;
sslBaseExpression[] property Expressions hidden
  sslBaseExpression[] function get()
    return ExpressionSlots.Expressions
  endFunction
endProperty

;/* 非推奨 */;
sslBaseExpression function RandomExpressionByTag(string Tag)
  return ExpressionSlots.RandomByTag(Tag)
endFunction

;/* 非推奨 */;
function ApplyPreset(Actor ActorRef, int[] Preset)
  sslBaseExpression.ApplyPreset(ActorRef, Preset)
endFunction

;/* 非推奨 */;
sslThreadController[] property Threads hidden
  sslThreadController[] function get()
    return ThreadSlots.Threads
  endFunction
endProperty

;/* 非推奨 */;
int function StartSex(Actor[] Positions, sslBaseAnimation[] Anims, Actor Victim = none, ObjectReference CenterOn = none, bool AllowBed = true, string Hook = "")
  sslThreadModel thread = NewThread()
  If (!thread)
    Log("StartSex() - Failed to claim an available thread")
    return -1
  ElseIf (!thread.AddActors(Positions, Victim))
    Log("StartSex() - Failed to add some actors to thread")
    return -1
  EndIf
  thread.SetAnimations(Anims)
  thread.CenterOnObject(CenterOn)
  thread.DisableBedUse(!AllowBed)
  thread.SetHook(Hook)
  thread.SetConsent(Victim == none)
  If (thread.StartThread())
    return thread.GetThreadID()
  EndIf
  return -1
EndFunction

;/* 非推奨 */;
sslThreadController Function QuickStart(Actor Actor1, Actor Actor2 = none, Actor Actor3 = none, Actor Actor4 = none, Actor Actor5 = none, Actor Victim = none, string Hook = "", string AnimationTags = "")
  Actor[] Positions = SexLabUtil.MakeActorArray(Actor1, Actor2, Actor3, Actor4, Actor5)
  return StartScene(Positions, AnimationTags, Victim, asHook = Hook) as sslThreadController
EndFunction

;/* 非推奨 */;
string function MakeAnimationGenderTag(Actor[] Positions)
  return ActorLib.MakeGenderTag(Positions)
endFunction

;/* 非推奨 */;
string function GetGenderTag(int Females = 0, int Males = 0, int Creatures = 0)
  return ActorLib.GetGenderTag(Females, Males, Creatures)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] function GetAnimationsByTags(int ActorCount, string Tags, string TagSuppress = "", bool RequireAll = true)
  return AnimSlots.GetByTags(ActorCount, Tags, TagSuppress, RequireAll)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] function GetAnimationsByType(int ActorCount, int Males = -1, int Females = -1, int StageCount = -1, bool Aggressive = false, bool Sexual = true)
  return AnimSlots.GetByType(ActorCount, Males, Females, StageCount, Aggressive, Sexual)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] function PickAnimationsByActors(Actor[] Positions, int Limit = 64, bool Aggressive = false)
  return AnimSlots.PickByActors(Positions, limit, aggressive)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] function GetAnimationsByDefault(int Males, int Females, bool IsAggressive = false, bool UsingBed = false, bool RestrictAggressive = true)
  return AnimSlots.GetByDefault(Males, Females, IsAggressive, UsingBed, RestrictAggressive)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] function GetAnimationsByDefaultTags(int Males, int Females, bool IsAggressive = false, bool UsingBed = false, bool RestrictAggressive = true, string Tags, string TagsSuppressed = "", bool RequireAll = true)
  return AnimSlots.GetByDefaultTags(Males, Females, IsAggressive, UsingBed, RestrictAggressive, Tags, TagsSuppressed, RequireAll)
endFunction

;/* 非推奨 */;
Actor[] function SortCreatures(Actor[] Positions, sslBaseAnimation Animation = none)
  return ThreadLib.SortCreatures(Positions, Animation)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] function GetCreatureAnimationsByRace(int ActorCount, Race RaceRef)
  return CreatureSlots.GetByRace(ActorCount, RaceRef)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] function GetCreatureAnimationsByRaceTags(int ActorCount, Race RaceRef, string Tags, string TagSuppress = "", bool RequireAll = true)
  return CreatureSlots.GetByRaceTags(ActorCount, RaceRef, Tags, TagSuppress, RequireAll)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] function GetCreatureAnimationsByRaceGenders(int ActorCount, Race RaceRef, int MaleCreatures = 0, int FemaleCreatures = 0, bool ForceUse = false)
  return CreatureSlots.GetByRaceGenders(ActorCount, RaceRef, MaleCreatures, FemaleCreatures, ForceUse)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] function GetCreatureAnimationsByRaceGendersTags(int ActorCount, Race RaceRef, int MaleCreatures = 0, int FemaleCreatures = 0, string Tags, string TagSuppress = "", bool RequireAll = true)
  return CreatureSlots.GetByRaceGendersTags(ActorCount, RaceRef, MaleCreatures, FemaleCreatures, Tags, TagSuppress, RequireAll)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] function GetCreatureAnimationsByRaceKey(int ActorCount, string RaceKey)
  return CreatureSlots.GetByRaceKey(ActorCount, RaceKey)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] function GetCreatureAnimationsByRaceKeyTags(int ActorCount, string RaceKey, string Tags, string TagSuppress = "", bool RequireAll = true)
  return CreatureSlots.GetByRaceKeyTags(ActorCount, RaceKey, Tags, TagSuppress, RequireAll)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] function GetCreatureAnimationsByActors(int ActorCount, Actor[] Positions)
  return CreatureSlots.GetByCreatureActors(ActorCount, Positions)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] function GetCreatureAnimationsByActorsTags(int ActorCount, Actor[] Positions, string Tags, string TagSuppress = "", bool RequireAll = true)
  return CreatureSlots.GetByCreatureActorsTags(ActorCount, Positions, Tags, TagSuppress, RequireAll)
endFunction

;/* 非推奨 */;
sslBaseAnimation function RegisterAnimation(string Registrar, Form CallbackForm = none, ReferenceAlias CallbackAlias = none)
  return none
endFunction

;/* 非推奨 */;
sslBaseAnimation function RegisterCreatureAnimation(string Registrar, Form CallbackForm = none, ReferenceAlias CallbackAlias = none)
  return none
endFunction

;/* 非推奨 */;
sslBaseAnimation function NewAnimationObject(string Token, Form Owner)
  return none
endFunction

;/* 非推奨 */;
sslBaseAnimation function GetSetAnimationObject(string Token, string Callback, Form Owner)
  return none
endFunction

;/* 非推奨 */;
sslBaseAnimation function NewAnimationObjectCopy(string Token, sslBaseAnimation CopyFrom, Form Owner)
  return none
endFunction

;/* 非推奨 */;
sslBaseAnimation function GetAnimationObject(string Token)
  String ret = SexLabRegistry.GetSceneByName(Token)
  return AnimSlots.GetSetAnimation(ret)
endFunction

;/* 非推奨 */;
sslBaseAnimation[] function GetOwnerAnimations(Form Owner)
  return none
endFunction

;/* 非推奨 */;
sslBaseAnimation function MakeAnimationRegistered(string Token)
  return none
endFunction

;/* 非推奨 */;
bool function RemoveRegisteredAnimation(string Registrar)
  return AnimSlots.UnregisterAnimation(Registrar)
endFunction

;/* 非推奨 */;
bool function RemoveRegisteredCreatureAnimation(string Registrar)
  return CreatureSlots.UnregisterAnimation(Registrar)
endFunction

; --- P+ Phase 2以降に削除

int function GetGender(Actor ActorRef)
  return ActorLib.GetGender(ActorRef)
endFunction
Function TreatAsGender(Actor ActorRef, bool AsFemale) ;  TreatAsSex()を参照
  ActorLib.TreatAsGender(ActorRef, AsFemale)
EndFunction
function ClearForcedGender(Actor ActorRef)  ; ClearForcedSex()を参照
  ActorLib.ClearForcedGender(ActorRef)
endFunction
int[] function GenderCount(Actor[] Positions)
  return ActorLib.GenderCount(Positions)
endFunction
int[] function TransGenderCount(Actor[] Positions)
  return ActorLib.TransCount(Positions)
endFunction
int function MaleCount(Actor[] Positions)
  return ActorLib.MaleCount(Positions)
endFunction
int function FemaleCount(Actor[] Positions)
  return ActorLib.FemaleCount(Positions)
endFunction
int function CreatureCount(Actor[] Positions)
  return ActorLib.CreatureCount(Positions)
endFunction
int function TransMaleCount(Actor[] Positions)
  return ActorLib.TransCount(Positions)[0]
endFunction
int function TransFemaleCount(Actor[] Positions)
  return ActorLib.TransCount(Positions)[1]
endFunction
int function TransCreatureCount(Actor[] Positions)
  int[] TransCount = ActorLib.TransCount(Positions)
  return TransCount[2] + TransCount[3]
endFunction
Form function EquipStrapon(Actor ActorRef)
  return Config.EquipStrapon(ActorRef)
endFunction
function UnequipStrapon(Actor ActorRef)
  Config.UnequipStrapon(ActorRef)
endFunction
int function CountCum(Actor ActorRef, bool Vaginal = true, bool Oral = true, bool Anal = true)
  return ActorLib.CountCum(ActorRef, Vaginal, Oral, Anal)
endFunction
function AddCum(Actor ActorRef, bool Vaginal = true, bool Oral = true, bool Anal = true)
  ActorLib.AddCum(ActorRef, Vaginal, Oral, Anal)
endFunction
function ClearCum(Actor ActorRef)
  ActorLib.ClearCum(ActorRef)
endFunction
bool function CheckBardAudience(Actor ActorRef, bool RemoveFromAudience = true)
  return Config.CheckBardAudience(ActorRef, RemoveFromAudience)
endFunction
Actor[] function SortActors(Actor[] Positions, bool FemaleFirst = true)
  return ThreadLib.SortActors(Positions, FemaleFirst)
endFunction
Actor[] function SortActorsByScene(String asSceneID, Actor[] akPositions, Actor[] akSubmissives)
  return ThreadLib.SortActorsByAnimationImpl(asSceneID, akPositions, akSubmissives)
endFunction
Actor function FindAvailableActor(ObjectReference CenterRef, float Radius = 5000.0, int FindGender = -1, Actor IgnoreRef1 = none, Actor IgnoreRef2 = none, Actor IgnoreRef3 = none, Actor IgnoreRef4 = none)
  return ThreadLib.FindAvailableActor(CenterRef, Radius, FindGender, IgnoreRef1, IgnoreRef2, IgnoreRef3, IgnoreRef4)
endFunction
Actor function FindAvailableActorByFaction(Faction FactionRef, ObjectReference CenterRef, float Radius = 5000.0, int FindGender = -1, Actor IgnoreRef1 = none, Actor IgnoreRef2 = none, Actor IgnoreRef3 = none, Actor IgnoreRef4 = none, bool HasFaction = True)
  return ThreadLib.FindAvailableActorInFaction(FactionRef, CenterRef, Radius, FindGender, IgnoreRef1, IgnoreRef2, IgnoreRef3, IgnoreRef4, HasFaction)
endFunction
Actor function FindAvailableActorWornForm(int slotMask, ObjectReference CenterRef, float Radius = 5000.0, int FindGender = -1, Actor IgnoreRef1 = none, Actor IgnoreRef2 = none, Actor IgnoreRef3 = none, Actor IgnoreRef4 = none, bool AvoidNoStripKeyword = True, bool HasWornForm = True)
  return ThreadLib.FindAvailableActorWornForm(slotMask, CenterRef, Radius, FindGender, IgnoreRef1, IgnoreRef2, IgnoreRef3, IgnoreRef4, AvoidNoStripKeyword, HasWornForm)
endFunction
Actor function FindAvailableCreature(string RaceKey, ObjectReference CenterRef, float Radius = 5000.0, int FindGender = 2, Actor IgnoreRef1 = none, Actor IgnoreRef2 = none, Actor IgnoreRef3 = none, Actor IgnoreRef4 = none)
  return ThreadLib.FindAvailableActor(CenterRef, Radius, FindGender, IgnoreRef1, IgnoreRef2, IgnoreRef3, IgnoreRef4, RaceKey)
endFunction
Actor function FindAvailableCreatureByFaction(string RaceKey, Faction FactionRef, ObjectReference CenterRef, float Radius = 5000.0, int FindGender = -1, Actor IgnoreRef1 = none, Actor IgnoreRef2 = none, Actor IgnoreRef3 = none, Actor IgnoreRef4 = none, bool HasFaction = True)
  return ThreadLib.FindAvailableActorInFaction(FactionRef, CenterRef, Radius, FindGender, IgnoreRef1, IgnoreRef2, IgnoreRef3, IgnoreRef4, HasFaction, RaceKey)
endFunction
Actor function FindAvailableCreatureWornForm(string RaceKey, int slotMask, ObjectReference CenterRef, float Radius = 5000.0, int FindGender = -1, Actor IgnoreRef1 = none, Actor IgnoreRef2 = none, Actor IgnoreRef3 = none, Actor IgnoreRef4 = none, bool AvoidNoStripKeyword = True, bool HasWornForm = True)
  return ThreadLib.FindAvailableActorWornForm(slotMask, CenterRef, Radius, FindGender, IgnoreRef1, IgnoreRef2, IgnoreRef3, IgnoreRef4, AvoidNoStripKeyword, HasWornForm, RaceKey)
endFunction
Actor[] function FindAvailablePartners(Actor[] Positions, int TotalActors, int Males = -1, int Females = -1, float Radius = 10000.0)
  return ThreadLib.FindAvailablePartners(Positions, TotalActors, Males, Females, Radius)
endFunction

function SendTrackedEvent(Actor ActorRef, string Hook, int id = -1)
  ThreadLib.SendTrackedEvent(ActorRef, Hook, id)
endFunction

; --- 旧スレッドAPI

sslThreadController function GetController(int tid)
  return ThreadSlots.GetController(tid)
endFunction
int function FindActorController(Actor ActorRef)
  return ThreadSlots.FindActorController(ActorRef)
endFunction
int function FindPlayerController()
  return ThreadSlots.FindActorController(PlayerRef)
endFunction
sslThreadController function GetActorController(Actor ActorRef)
  return ThreadSlots.GetActorController(ActorRef)
endFunction
sslThreadController function GetPlayerController()
  return ThreadSlots.GetActorController(PlayerRef)
endFunction
int function GetEnjoyment(int tid, Actor ActorRef)
  return ThreadSlots.GetController(tid).GetEnjoyment(ActorRef)
endfunction
bool function IsVictim(int tid, Actor ActorRef)
  return ThreadSlots.GetController(tid).IsVictim(ActorRef)
endFunction
bool function IsAggressor(int tid, Actor ActorRef)
  return ThreadSlots.GetController(tid).IsAggressor(ActorRef)
endFunction
bool function IsUsingStrapon(int tid, Actor ActorRef)
  return ThreadSlots.GetController(tid).ActorAlias(ActorRef).IsUsingStrapon()
endFunction
bool function PregnancyRisk(int tid, Actor ActorRef, bool AllowFemaleCum = false, bool AllowCreatureCum = false)
  return ThreadSlots.GetController(tid).PregnancyRisk(ActorRef, AllowFemaleCum, AllowCreatureCum)
endfunction

; --- 旧式のアニメーション関数

Actor[] function SortActorsByAnimation(Actor[] Positions, sslBaseAnimation Animation = none)
  return ThreadLib.SortActorsByAnimation(Positions, Animation)
endFunction
sslBaseAnimation function GetAnimationByName(string FindName)
  return AnimSlots.GetByName(FindName)
endFunction
sslBaseAnimation function GetAnimationByRegistry(string Registry)
  return AnimSlots.GetByRegistrar(Registry)
endFunction
int function FindAnimationByName(string FindName)
  return AnimSlots.FindByName(FindName)
endFunction
int function GetAnimationCount(bool IgnoreDisabled = true)
  return AnimSlots.GetCount(IgnoreDisabled)
endFunction
sslBaseAnimation[] function MergeAnimationLists(sslBaseAnimation[] List1, sslBaseAnimation[] List2)
  return sslUtility.MergeAnimationLists(List1, List2)
endFunction
sslBaseAnimation[] function RemoveTagged(sslBaseAnimation[] Anims, string Tags)
  return sslUtility.RemoveTaggedAnimations(Anims, PapyrusUtil.StringSplit(Tags))
endFunction
int function CountTag(sslBaseAnimation[] Anims, string Tags)
  return AnimSlots.CountTag(Anims, Tags)
endFunction
int function CountTagUsage(string Tags, bool IgnoreDisabled = true)
  return AnimSlots.CountTagUsage(Tags, IgnoreDisabled)
endFunction
int function CountCreatureTagUsage(string Tags, bool IgnoreDisabled = true)
  return CreatureSlots.CountTagUsage(Tags, IgnoreDisabled)
endFunction
string[] function GetAllAnimationTags(int ActorCount = -1, bool IgnoreDisabled = true)
  return AnimSlots.GetAllTags(ActorCount, IgnoreDisabled)
endFunction
string[] function GetAllAnimationTagsInArray(sslBaseAnimation[] List)
  return sslUtility.GetAllAnimationTagsInArray(List)
endFunction

; --- 旧式のクリーチャー関数

sslBaseAnimation function GetCreatureAnimationByName(string FindName)
  return CreatureSlots.GetByName(FindName)
endFunction
sslBaseAnimation function GetCreatureAnimationByRegistry(string Registry)
  return CreatureSlots.GetByRegistrar(Registry)
endFunction
bool function HasCreatureRaceAnimation(Race CreatureRace, int ActorCount = -1, int Gender = -1)
  return CreatureSlots.RaceHasAnimation(CreatureRace, ActorCount, Gender)
endFunction
bool function HasCreatureRaceKeyAnimation(string RaceKey, int ActorCount = -1, int Gender = -1)
  return CreatureSlots.RaceKeyHasAnimation(RaceKey, ActorCount, Gender)
endFunction
bool function AllowedCreature(Race CreatureRace)
  return CreatureSlots.AllowedCreature(CreatureRace)
endFunction
bool function AllowedCreatureCombination(Race CreatureRace, Race CreatureRace2)
  return CreatureSlots.AllowedCreatureCombination(CreatureRace, CreatureRace2)
endFunction
string[] function GetAllCreatureAnimationTags(int ActorCount = -1, bool IgnoreDisabled = true)
  return CreatureSlots.GetAllTags(ActorCount, IgnoreDisabled)
endFunction
string[] function GetAllBothAnimationTags(int ActorCount = -1, bool IgnoreDisabled = true)
  string[] Output = PapyrusUtil.MergeStringArray(AnimSlots.GetAllTags(ActorCount, IgnoreDisabled), CreatureSlots.GetAllTags(ActorCount, IgnoreDisabled))
  PapyrusUtil.SortStringArray(Output)
  return Output
endFunction

; --- 旧式の統計関数

int function RegisterStat(string Name, string Value, string Prepend = "", string Append = "")
  return Stats.RegisterStat(Name, Value, Prepend, Append)
endFunction
function Alter(string Name, string NewName = "", string Value = "", string Prepend = "", string Append = "")
  Stats.Alter(Name, NewName, Value, Prepend, Append)
endFunction
int function FindStat(string Name)
  return Stats.FindStat(Name)
endFunction
string function GetActorStat(Actor ActorRef, string Name)
  return Stats.GetStat(ActorRef, Name)
endFunction
int function GetActorStatInt(Actor ActorRef, string Name)
  return Stats.GetStatInt(ActorRef, Name)
endFunction
float function GetActorStatFloat(Actor ActorRef, string Name)
  return Stats.GetStatFloat(ActorRef, Name)
endFunction
string function SetActorStat(Actor ActorRef, string Name, string Value)
  return Stats.SetStat(ActorRef, Name, Value)
endFunction
int function ActorAdjustBy(Actor ActorRef, string Name, int AdjustBy)
  return Stats.AdjustBy(ActorRef, Name, AdjustBy)
endFunction
string function GetActorStatFull(Actor ActorRef, string Name)
  return Stats.GetStatFull(ActorRef, Name)
endFunction
string function GetStatFull(string Name)
  return Stats.GetStatFull(PlayerRef, Name)
endFunction
string function GetStat(string Name)
  return Stats.GetStat(PlayerRef, Name)
endFunction
int function GetStatInt(string Name)
  return Stats.GetStatInt(PlayerRef, Name)
endFunction
float function GetStatFloat(string Name)
  return Stats.GetStatFloat(PlayerRef, Name)
endFunction
string function SetStat(string Name, string Value)
  return Stats.SetStat(PlayerRef, Name, Value)
endFunction
int function AdjustBy(string Name, int AdjustBy)
  return Stats.AdjustBy(PlayerRef, Name, AdjustBy)
endFunction
bool function IsImpure(Actor ActorRef)
  return Stats.IsLewd(ActorRef)
endFunction
float function AdjustPurity(Actor ActorRef, float amount)
  return Stats.AdjustPurity(ActorRef, amount)
endFunction
float function GetPurity(Actor ActorRef)
  return Stats.GetPurity(ActorRef)
endFunction
int function GetPurityLevel(Actor ActorRef)
  return Stats.GetPurityLevel(ActorRef)
endFunction
string function GetPurityTitle(Actor ActorRef)
  return Stats.GetPurityTitle(ActorRef)
endFunction
bool function IsPure(Actor ActorRef)
  return Stats.IsPure(ActorRef)
endFunction
bool function IsLewd(Actor ActorRef)
  return Stats.IsLewd(ActorRef)
endFunction
float function AdjustPlayerPurity(float amount)
  return Stats.AdjustPurity(PlayerRef, amount)
endFunction
int function GetPlayerPurityLevel()
  return Stats.GetPurityLevel(PlayerRef)
endFunction
string function GetPlayerPurityTitle()
  return Stats.GetPurityTitle(PlayerRef)
endFunction
float function DaysSinceLastSex(Actor ActorRef)
  return Stats.DaysSinceLastSex(ActorRef)
endFunction
float function HoursSinceLastSex(Actor ActorRef)
  return Stats.HoursSinceLastSex(ActorRef)
endFunction
float function MinutesSinceLastSex(Actor ActorRef)
  return Stats.MinutesSinceLastSex(ActorRef)
endFunction
float function SecondsSinceLastSex(Actor ActorRef)
  return Stats.SecondsSinceLastSex(ActorRef)
endFunction
string function LastSexTimerString(Actor ActorRef)
  return Stats.LastSexTimerString(ActorRef)
endFunction
float function LastSexRealTime(Actor ActorRef)
  return Stats.LastSexRealTime(ActorRef)
endFunction
float function DaysSinceLastSexRealTime(Actor ActorRef)
  return Stats.DaysSinceLastSexRealTime(ActorRef)
endFunction
float function HoursSinceLastSexRealTime(Actor ActorRef)
  return Stats.HoursSinceLastSexRealTime(ActorRef)
endFunction
float function MinutesSinceLastSexRealTime(Actor ActorRef)
  return Stats.MinutesSinceLastSexRealTime(ActorRef)
endFunction
float function SecondsSinceLastSexRealTime(Actor ActorRef)
  return Stats.SecondsSinceLastSexRealTime(ActorRef)
endFunction
string function LastSexTimerStringRealTime(Actor ActorRef)
  return Stats.LastSexTimerStringRealTime(ActorRef)
endFunction
int function CalcSexuality(bool IsFemale, int males, int females)
  return Stats.CalcSexuality(IsFemale, males, females)
endFunction
int function CalcLevel(float total, float curve = 0.65)
  return sslActorStats.CalcLevel(total, curve)
endFunction
int function GetPlayerStatLevel(string Skill)
  return Stats.GetSkillLevel(PlayerRef, Skill)
endFunction
string function GetPlayerSexualityTitle()
  return sslActorStats.GetSexualityTitle(PlayerRef)
endFunction
string function GetPlayerSkillTitle(string Skill)
  return Stats.GetSkillTitle(PlayerRef, Skill)
endFunction
int function GetPlayerSkillLevel(string Skill)
  return Stats.GetSkillLevel(PlayerRef, Skill)
endFunction
string function GetSexualityTitle(Actor ActorRef)
  return sslActorStats.GetSexualityTitle(ActorRef)
endFunction
string function GetSkillTitle(Actor ActorRef, string Skill)
  return Stats.GetSkillTitle(ActorRef, Skill)
endFunction
int function PlayerSexCount(Actor ActorRef)
  return Stats.PlayerSexCount(ActorRef)
endFunction
bool function HadPlayerSex(Actor ActorRef)
  return Stats.HadPlayerSex(ActorRef)
endFunction
Actor function MostUsedPlayerSexPartner()
  return Stats.MostUsedPlayerSexPartner()
endFunction
Actor[] function MostUsedPlayerSexPartners(int MaxActors = 5)
  return Stats.MostUsedPlayerSexPartners(MaxActors)
endFunction
float Function LastSexGameTime(Actor ActorRef)
  return Stats.LastSexGameTime(ActorRef)
EndFunction
Actor function LastSexPartner(Actor ActorRef)
  return Stats.LastSexPartner(ActorRef)
endFunction
bool function HasHadSexTogether(Actor ActorRef1, Actor ActorRef2)
  return Stats.HasHadSexTogether(ActorRef1, ActorRef2)
endfunction
Actor function LastAggressor(Actor ActorRef)
  return Stats.LastAggressor(ActorRef)
endFunction
bool function WasVictimOf(Actor VictimRef, Actor AggressorRef)
  return Stats.WasVictimOf(VictimRef, AggressorRef)
endFunction
Actor function LastVictim(Actor ActorRef)
  return Stats.LastVictim(ActorRef)
endFunction
bool function WasAggressorTo(Actor AggressorRef, Actor VictimRef)
  return Stats.WasAggressorTo(AggressorRef, VictimRef)
endFunction
function SetSexuality(Actor ActorRef, int amount)
  Stats.SetSkill(ActorRef, "Sexuality", PapyrusUtil.ClampInt(amount, 1, 100))
endFunction
function SetSexualityStraight(Actor ActorRef)
  Stats.SetSkill(ActorRef, "Sexuality", 100)
endFunction
function SetSexualityBisexual(Actor ActorRef)
  Stats.SetSkill(ActorRef, "Sexuality", 50)
endFunction
function SetSexualityGay(Actor ActorRef)
  Stats.SetSkill(ActorRef, "Sexuality", 1)
endFunction
int function GetSexuality(Actor ActorRef)
  return Stats.GetSexuality(ActorRef)
endFunction
int function GetSkill(Actor ActorRef, string Skill)
  return Stats.GetSkill(ActorRef, Skill)
endFunction
int function GetSkillLevel(Actor ActorRef, string Skill)
  return Stats.GetSkillLevel(ActorRef, Skill)
endFunction
bool function IsStraight(Actor ActorRef)
  return Stats.IsStraight(ActorRef)
endFunction
bool function IsBisexual(Actor ActorRef)
  return Stats.IsBisexual(ActorRef)
endFunction
bool function IsGay(Actor ActorRef)
  return Stats.IsGay(ActorRef)
endFunction
int function SexCount(Actor ActorRef)
  return Stats.SexCount(ActorRef)
endFunction
bool function HadSex(Actor ActorRef)
  return Stats.HadSex(ActorRef)
endFunction

; --- 旧式のファクトリー関数
; これらの関数はすべて既定値を返す。実装は削除済み。

sslBaseVoice function NewVoiceObject(string Token, Form Owner)
  return Factory.NewVoice(Token, Owner)
endFunction
sslBaseExpression function NewExpressionObject(string Token, Form Owner)
  return Factory.NewExpression(Token, Owner)
endFunction
sslBaseVoice function GetSetVoiceObject(string Token, string Callback, Form Owner)
  return Factory.GetSetVoice(Token, Callback, Owner)
endFunction
sslBaseExpression function GetSetExpressionObject(string Token, string Callback, Form Owner)
  return Factory.GetSetExpression(Token, Callback, Owner)
endFunction
sslBaseVoice function NewVoiceObjectCopy(string Token, sslBaseVoice CopyFrom, Form Owner)
  return Factory.NewVoiceCopy(Token, CopyFrom, Owner)
endFunction
sslBaseExpression function NewExpressionObjectCopy(string Token, sslBaseExpression CopyFrom, Form Owner)
  return Factory.NewExpressionCopy(Token, CopyFrom, Owner)
endFunction
sslBaseVoice function GetVoiceObject(string Token)
  return Factory.GetVoice(Token)
endFunction
sslBaseExpression function GetExpressionObject(string Token)
  return Factory.GetExpression(Token)
endFunction
sslBaseVoice[] function GetOwnerVoices(Form Owner)
  return Factory.GetOwnerVoices(Owner)
endFunction
sslBaseExpression[] function GetOwnerExpressions(Form Owner)
  return Factory.GetOwnerExpressions(Owner)
endFunction
bool function HasVoiceObject(string Token)
  return Factory.HasVoice(Token)
endFunction
bool function HasExpressionObject(string Token)
  return Factory.HasExpression(Token)
endFunction
bool function ReleaseVoiceObject(string Token)
  return Factory.ReleaseVoice(Token)
endFunction
bool function ReleaseExpressionObject(string Token)
  return Factory.ReleaseExpression(Token)
endFunction
int function ReleaseOwnerVoices(Form Owner)
  return Factory.ReleaseOwnerVoices(Owner)
endFunction
int function ReleaseOwnerExpressions(Form Owner)
  return Factory.ReleaseOwnerExpressions(Owner)
endFunction
sslBaseVoice function MakeVoiceRegistered(string Token)
  return Factory.MakeVoiceRegistered(Token)
endFunction
sslBaseExpression function MakeExpressionRegistered(string Token)
  return Factory.MakeExpressionRegistered(Token)
endFunction
bool function HasAnimationObject(string Token)
  return Factory.HasAnimation(Token)
endFunction
bool function ReleaseAnimationObject(string Token)
  return Factory.ReleaseAnimation(Token)
endFunction
int function ReleaseOwnerAnimations(Form Owner)
  return Factory.ReleaseOwnerAnimations(Owner)
endFunction

; --- 旧式の表情関数

sslBaseExpression function PickExpression(Actor ActorRef, Actor VictimRef = none)
  return ExpressionSlots.PickByStatus(ActorRef, (VictimRef && VictimRef == ActorRef), (VictimRef && VictimRef != ActorRef))
endFunction
sslBaseExpression function PickExpressionByStatus(Actor ActorRef, bool IsVictim = false, bool IsAggressor = false)
  return ExpressionSlots.PickByStatus(ActorRef, IsVictim, IsAggressor)
endFunction
sslBaseExpression[] function GetExpressionsByStatus(Actor ActorRef, bool IsVictim = false, bool IsAggressor = false)
  return ExpressionSlots.GetByStatus(ActorRef, IsVictim, IsAggressor)
endFunction
sslBaseExpression function PickExpressionsByTag(Actor ActorRef, string Tag)
  sslBaseExpression[] Found =  ExpressionSlots.GetByTag(Tag, ActorRef.GetLeveledActorBase().GetSex() == 1)
  if Found && Found.Length > 0
    return Found[(Utility.RandomInt(0, (Found.Length - 1)))]
  endIf
  return none
endFunction
sslBaseExpression[] function GetExpressionsByTag(Actor ActorRef, string Tag)
  return ExpressionSlots.GetByTag(Tag, ActorRef.GetLeveledActorBase().GetSex() == 1)
endFunction
sslBaseExpression function GetExpressionByName(string findName)
  return ExpressionSlots.GetByName(findName)
endFunction
int function FindExpressionByName(string findName)
  return ExpressionSlots.FindByName(findName)
endFunction
sslBaseExpression function GetExpressionBySlot(int slot)
  return ExpressionSlots.GetBySlot(slot)
endFunction
function OpenMouth(Actor ActorRef)
  if ActorRef
    int i
    while i < ThreadSlots.Threads.Length
      int ActorSlot = Threads[i].FindSlot(ActorRef)
      if ActorSlot != -1
        Threads[i].ActorAlias[ActorSlot].ForceOpenMouth = True
      endIf
      i += 1
    endwhile
    sslBaseExpression.OpenMouth(ActorRef)
  endIf
endFunction
function CloseMouth(Actor ActorRef)
  if ActorRef
    int i
    while i < ThreadSlots.Threads.Length
      int ActorSlot = Threads[i].FindSlot(ActorRef)
      if ActorSlot != -1
        Threads[i].ActorAlias[ActorSlot].ForceOpenMouth = False
      endIf
      i += 1
    endwhile
    sslBaseExpression.CloseMouth(ActorRef)
  endIf
endFunction
bool function IsMouthOpen(Actor ActorRef)
  return sslBaseExpression.IsMouthOpen(ActorRef)
endFunction

; --- 旧式のボイス関数

sslBaseVoice function PickVoice(Actor ActorRef)
  return VoiceSlots.PickVoice(ActorRef)
endFunction
sslBaseVoice function GetVoice(Actor ActorRef)
  return VoiceSlots.PickVoice(ActorRef)
endFunction
function SaveVoice(Actor ActorRef, sslBaseVoice Saving)
  VoiceSlots.SaveVoice(ActorRef, Saving)
endFunction
function ForgetVoice(Actor ActorRef)
  VoiceSlots.ForgetVoice(ActorRef)
endFunction
sslBaseVoice function GetSavedVoice(Actor ActorRef)
  return VoiceSlots.GetSaved(ActorRef)
endFunction
bool function HasCustomVoice(Actor ActorRef)
  return VoiceSlots.HasCustomVoice(ActorRef)
endFunction
sslBaseVoice function GetVoiceByGender(int Gender)
  return VoiceSlots.PickGender(Gender)
endFunction
sslBaseVoice[] function GetVoicesByGender(int Gender)
  return VoiceSlots.GetAllGender(Gender)
endFunction
sslBaseVoice function GetVoiceByName(string FindName)
  return VoiceSlots.GetByName(FindName)
endFunction
int function FindVoiceByName(string FindName)
  return VoiceSlots.FindByName(FindName)
endFunction
sslBaseVoice function GetVoiceBySlot(int slot)
  return VoiceSlots.GetBySlot(slot)
endFunction
sslBaseVoice function GetVoiceByTags(string Tags, string TagSuppress = "", bool RequireAll = true)
  return VoiceSlots.GetByTags(Tags, TagSuppress, RequireAll)
endFunction
sslBaseVoice[] function GetVoicesByTags(string Tags, string TagSuppress = "", bool RequireAll = true)
  return VoiceSlots.GetAllByTags(Tags, TagSuppress, RequireAll)
endFunction

;#-----------------------------------------------------------------------------------------------------------------------------------------#
;#                                                                                                                                         #
;# ^^^                                            非推奨関数ここまで - 使用しないこと                                                   ^^^ #
;#                                                                                                                                         #
;#-----------------------------------------------------------------------------------------------------------------------------------------#
;/
  注意: 以下の関数はまだ旧式ではないが、将来の更新で旧式になる可能性がある。将来のバージョンとの互換性を保つため、使用しないこと。
/;

;/* RegisterVoice
* * 使用可能なSexLabVoiceスロットを探し、登録用コールバックを開始する。
* * SexLabVoiceがすでに登録済みの場合、更新せずに登録済みのSexLabVoiceを返す。
* *
* * @param: string Registrar - SexLabVoiceのID。空白は使用不可。
* * @param: Form CallbackForm - SexLabVoice登録処理を行うコードを含むスクリプト（オブジェクト）。Registrarと同じ名前のEventが必要。
* * @param: ReferenceAlias CallbackAlias - スクリプトがReferenceAlias内にある場合、CallbackFormの代わりに指定できる。
* * @return: sslBaseVoice - 登録されたSexLabVoice。
*/;
sslBaseVoice function RegisterVoice(string Registrar, Form CallbackForm = none, ReferenceAlias CallbackAlias = none)
  return VoiceSlots.RegisterVoice(Registrar, CallbackForm, CallbackAlias)
endFunction

;/* RegisterExpression
* * 使用可能なSexLabExpressionスロットを探し、登録用コールバックを開始する。
* * SexLabExpressionがすでに登録済みの場合、更新せずに登録済みのSexLabExpressionを返す。
* *
* * @param: string Registrar - SexLabExpressionのID。空白は使用不可。
* * @param: Form CallbackForm - SexLabExpression登録処理を行うコードを含むスクリプト（オブジェクト）。Registrarと同じ名前のEventが必要。
* * @param: ReferenceAlias CallbackAlias - スクリプトがReferenceAlias内にある場合、CallbackFormの代わりに指定できる。
* * @return: sslBaseExpression - 登録されたSexLabExpression。
*/;
sslBaseExpression function RegisterExpression(string Registrar, Form CallbackForm = none, ReferenceAlias CallbackAlias = none)
  return ExpressionSlots.RegisterExpression(Registrar, CallbackForm, CallbackAlias)
endFunction

;/* RemoveRegisteredVoice
* * 要対応
* * 
* * @param: 
* * @return: 
*/;
bool function RemoveRegisteredVoice(string Registrar)
  return VoiceSlots.UnregisterVoice(Registrar)
endFunction

;/* RemoveRegisteredExpression
* * 要対応
* * 
* * @param: 
* * @return: 
*/;
bool function RemoveRegisteredExpression(string Registrar)
  return ExpressionSlots.UnregisterExpression(Registrar)
endFunction

;#-----------------------------------------------------------------------------------------------------------------------------------------#
;#                                                                                                                                         #
;#                                    以下のプロパティと関数は内部使用専用                                                               #;
;#                                                                                                                                         #
;#                                                                                                                                         #
;#                             ****       ***         *     *   ***   *******     *     *   ******  *******                                #
;#                             *   **    *   *        **    *  *   *     *        *     *  *      * *                                      #
;#                             *     *  *     *       * *   * *     *    *        *     *  *        *                                      #
;#                             *      * *     *       *  *  * *     *    *        *     *   ******  *****                                  #
;#                             *     *  *     *       *   * * *     *    *        *     *         * *                                      #
;#                             *   **    *   *        *    **  *   *     *         *   *   *      * *                                      #
;#                             ****       ***         *     *   ***      *          ***     ******  *******                                #
;#                                                                                                                                         #
;#                                                                                                                                         #
;#-----------------------------------------------------------------------------------------------------------------------------------------#

sslSystemConfig property Config Auto
sslActorLibrary property ActorLib Auto
sslThreadLibrary property ThreadLib Auto
sslThreadSlots property ThreadSlots Auto

Function Setup()
	Form SexLabQuestFramework = Game.GetFormFromFile(0xD62, "SexLab.esm")
	Config = SexLabQuestFramework as sslSystemConfig
	ThreadLib = SexLabQuestFramework as sslThreadLibrary
	ThreadSlots = SexLabQuestFramework as sslThreadSlots
	ActorLib = SexLabQuestFramework as sslActorLibrary

  Log(self + " - Loaded SexLabFramework")
EndFunction

sslThreadModel Function NewThread(float TimeOut = 5.0)
  return ThreadSlots.PickModel(TimeOut)
EndFunction

SexLabThread Function StartSceneImpl(Actor[] akPositions, String[] asScenes, String asContext, Actor[] akSubmissive, ObjectReference akCenter, int aiFurniture, String asHook)
  sslThreadModel thread = NewThread()
  If (!thread)
    Log("StartSceneImpl() - Failed to claim an available thread")
    return none
  ElseIf (!thread.AddActorsA(akPositions, akSubmissive))
    Log("StartSceneImpl() - Failed to add some actors to thread")
    return none
  EndIf
  thread.SetScenes(asScenes)
  thread.CenterOnObject(akCenter)
  thread.SetFurnitureStatus(aiFurniture)
  thread.AddContextEx(asContext)
  thread.SetHook(asHook)
  return thread.StartThread()
EndFunction

Function Log(string Log, string Type = "NOTICE")
  If(Type == "FATAL")
    sslLog.Error(Log)
  Else
    sslLog.Log(Log)
  EndIf
EndFunction

auto state Disabled
  sslThreadModel function NewThread(float TimeOut = 5.0)
    LogDisabled("NewThread")
    return none
  endFunction
  SexLabThread Function StartScene(Actor[] akPositions, String asTags, Actor akSubmissive = none, ObjectReference akCenter = none, int aiFurniture = 1, String asHook = "")
    LogDisabled("StartScene")
    return none
  EndFunction
  SexLabThread Function StartSceneA(Actor[] akPositions, String asTags, Actor[] akSubmissives, ObjectReference akCenter = none, int aiFurniture = 1, String asHook = "")
    LogDisabled("StartSceneA")
  EndFunction
  SexLabThread Function StartSceneEx(Actor[] akPositions, String[] asAnims, Actor akSubmissive = none, String asContext = "", \
      ObjectReference akCenter = none, int aiFurniture = 1, String asHook = "")
    LogDisabled("StartSceneEx")
  EndFunction
  SexLabThread Function StartSceneExA(Actor[] akPositions, String[] asScenes, Actor[] akSubmissives, String asContext = "", \
      ObjectReference akCenter = none, int aiFurniture = 1, String asHook = "")
    LogDisabled("StartSceneExA")
  EndFunction
  SexLabThread Function StartSceneQuick(Actor akActor1, Actor akActor2 = none, Actor akActor3 = none, Actor akActor4 = none, Actor akActor5 = none, \
                                          Actor akSubmissive = none, String asTags = "", String asHook = "")
    LogDisabled("StartSceneQuick")
  EndFunction
  SexLabThread Function StartSceneImpl(Actor[] akPositions, String[] asScenes, String asContext, Actor[] akSubmissive, ObjectReference akCenter, int aiFurniture, String asHook)
    LogDisabled("StartSceneImpl")
    return none
  EndFunction
  sslThreadController function QuickStart(Actor Actor1, Actor Actor2 = none, Actor Actor3 = none, Actor Actor4 = none, Actor Actor5 = none, Actor Victim = none, string Hook = "", string AnimationTags = "")
    LogDisabled("QuickStart")
    return none
  endFunction
  int function StartSex(Actor[] Positions, sslBaseAnimation[] Anims, Actor Victim = none, ObjectReference CenterOn = none, bool AllowBed = true, string Hook = "")
    LogDisabled("StartSex")
    return -1
  endFunction
  event OnBeginState()
    Log("SexLabFramework - Disabled")
    ModEvent.Send(ModEvent.Create("SexLabDisabled"))
  endEvent
endState

Function LogDisabled(String asFunc)
  Log(asFunc + "() - Failed to make new thread model; system is currently disabled or not installed", "FATAL")
EndFunction

state Enabled
  event OnBeginState()
    Log("SexLabFramework - Enabled")
    ModEvent.Send(ModEvent.Create("SexLabEnabled"))
  endEvent
endState

Actor Property PlayerRef
  Actor Function Get()
    return Game.GetPLayer()
  EndFunction
EndProperty

Faction Property AnimatingFaction
  Faction Function Get()
    return Config.AnimatingFaction
  EndFunction
EndProperty
sslAnimationSlots property AnimSlots Hidden
  sslAnimationSlots Function Get()
    return Game.GetFormFromFile(0x639DF, "SexLab.esm") as sslAnimationSlots
  EndFunction
EndProperty
sslCreatureAnimationSlots property CreatureSlots Hidden
  sslCreatureAnimationSlots Function Get()
    return Game.GetFormFromFile(0x664FB, "SexLab.esm") as sslCreatureAnimationSlots
  EndFunction
EndProperty
sslVoiceSlots property VoiceSlots Hidden
  sslVoiceSlots Function Get()
	  return Game.GetFormFromFile(0x664FB, "SexLab.esm") as sslVoiceSlots
  EndFunction
EndProperty
sslObjectFactory property Factory Hidden
  sslObjectFactory Function Get()
    return Game.GetFormFromFile(0x78818, "SexLab.esm") as sslObjectFactory
  EndFunction
EndProperty
sslActorStats Property Stats Hidden
  sslActorStats Function Get()
	  return Game.GetFormFromFile(0xD62, "SexLab.esm") as sslActorStats
  EndFunction
EndProperty
sslExpressionSlots property ExpressionSlots Hidden
  sslExpressionSlots Function Get()
    return Game.GetFormFromFile(0x664FB, "SexLab.esm") as sslExpressionSlots
  EndFunction
EndProperty

event OnInit()
endEvent
