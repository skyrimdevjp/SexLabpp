ScriptName SexlabRegistry Hidden
{
  レジストリアクセス用のグローバルスクリプト

  すべてのレジストリオブジェクトには一意のNanoIDが付与され、各関数の最初の引数として指定する必要がある
  これらのIDはセーブデータをまたいで保持され、通常はレジストリオブジェクトの提供元が手動で変更しない限り変わらない
  FormEditorIDに似ているが、ゲームではなくSexLab自体が管理するものであり、通常は人が読める形式ではない
}

; ------------------------------------------------------- ;
; --- 定義                                            --- ;
; ------------------------------------------------------- ;

; このアクターの種族を表す0～52の整数を取得する
; 配列を使わない版では、利用可能な中で最も厳密なIDを返す。つまり、Canineのような曖昧な種族を表すIDを避け、
; より正確な種族（ここでは狼または犬）を返す
; -1 - 無効な問い合わせ | 0 - 人間 | 1以上 - クリーチャー
int Function GetRaceID(Actor akActor) native global
int Function MapRaceKeyToID(String asRaceKey) native global
int[] Function GetRaceIDA(Actor akActor) native global
int[] Function MapRaceKeyToIDA(String asRaceKey) native global
; RaceKeyを人が読める文字列で取得する。可能な場合はより正確なキーを優先する
String Function GetRaceKey(Actor akActor) native global
String Function GetRaceKeyByRace(Race akRace) native global
String Function MapRaceIDToRaceKey(int aiRaceID) native global
String[] Function GetRaceKeyA(Actor akActor) native global
String[] Function GetRaceKeyByRaceA(Race akRace) native global
String[] Function MapRaceIDToRaceKeyA(int aiRaceID) native global
; サポートされているすべてのRaceKeyの一覧を取得する
String[] Function GetAllRaceKeys(bool abIgnoreAmbiguous) native global

; このアクターの性別を返す。上書きを無視しない場合、ユーザーまたはMod作者が設定した上書きフラグを反映する
; 対応: Male = 0 | Female = 1 | Futa = 2 | CrtMale = 3 | CrtFemale = 4
int Function GetSex(Actor akActor, bool abIgnoreOverwrite) native global

; ------------------------------------------------------- ;
; --- 検索                                            --- ;
; ------------------------------------------------------- ;

; 指定されたアクターとタグ条件に合うシーンを検索する
; aiFurniturePreference の値: 0 - 家具を許可しない | 1 - 家具を許可する | 2 - 家具を優先する（該当するものがある場合のみ使用）
; akCenter が設定されている場合、aiFurniturePreference は無視され、その中心に適合するアニメーションのみが選ばれる。たとえばテーブルを渡すと、
; テーブル用アニメーションのみを検索する。家具オブジェクトとして認識されない中心は、選択されるアニメーションに影響しない
String[] Function LookupScenes(Actor[] akPositions, String asTags, Actor akSubmissive, int aiFurniturePreference, ObjectReference akCenter) native global
String[] Function LookupScenesA(Actor[] akPositions, String asTags, Actor[] akSubmissives, int aiFurniturePreference, ObjectReference akCenter) native global

; 指定されたタグ条件のもとで、指定されたアクターがシーンを再生できるか確認する。有効なシーンすべてを配列で返す
bool Function ValidateScene(String asSceneID, Actor[] akPositions, String asTags, Actor akSubmissive) native global
bool Function ValidateSceneA(String asSceneID, Actor[] akPositions, String asTags, Actor[] akSubmissives) native global
String[] Function ValidateScenes(String[] asSceneIDs, Actor[] akPositions, String asTags, Actor akSubmissive) native global
String[] Function ValidateScenesA(String[] asSceneIDs, Actor[] akPositions, String asTags, Actor[] akSubmissive) native global

; 指定されたシーンに基づいてakPositionを並べ替える。配列は直接変更され、並べ替え後の順序は規定されない
; 拡張版は配列を受け取り、アクターが並べ替えられたシーンのうちn番目（最初に一致したもの）のインデックスを返す
; ポジションを並べ替えられない場合はfalse/-1を返す
bool Function SortByScene(Actor[] akPositions, Actor akSubmissive, String asScene) native global
bool Function SortBySceneA(Actor[] akPositions, Actor[] akSubmissives, String asScene) native global
int Function SortBySceneEx(Actor[] akPositions, Actor akSubmissive, String[] asScenes) native global
int Function SortBySceneExA(Actor[] akPositions, Actor[] akSubmissives, String[] asScenes) native global

; 引数で指定された名前のシーンを表すシーンIDを返す。その名前のシーンがなければ空文字列を返す
; 同名のシーンが複数ある場合は、最初に見つかったものを返す
String Function GetSceneByName(String asName) native global

; ------------------------------------------------------- ;
; --- シーン                                          --- ;
; ------------------------------------------------------- ;
;/
  SexLabのシーンは有向グラフとして実装されている
  各グラフには開始ノード／ソースが必ず1つあり、終了ノード／シンクは任意の数だけ存在する
  開始ノードを参照するには、空のステージID（""）を使う。グラフには循環が含まれる場合がある

  シーンを自分で再帰的に解析する前に、DFSやBFSアルゴリズムに慣れておくことを強く推奨する:
  https://en.wikipedia.org/wiki/Depth-first_search | https://en.wikipedia.org/wiki/Breadth-first_search
/;

; 指定されたIDが有効なシーンオブジェクトに属するか確認する
bool Function SceneExists(String asID) native global
String[] Function SceneExistA(String[] asSceneIDs) native global
bool Function StageExists(String asID, String asStage) native global

; --- メタデータ

; 指定されたシーンの有効状態を取得／変更する。無効なシーンは検索関数から除外される
bool Function IsSceneEnabled(String asID) native global
Function SetSceneEnabled(String asID, bool abEnabled) native global

; 指定されたシーンの人が読める名前
String Function GetSceneName(String asID) native global

; 指定された中心をこのシーンのアニメーションに使用できるか確認する
bool Function IsCompatibleCenter(String asID, ObjectReference akCenter) native global

; 指定されたタグがシーンに含まれるか確認する
bool Function IsSceneTag(String asID, String asTag) native global
bool Function IsSceneTagA(String asID, String[] asTags) native global
; 指定されたタグがステージに含まれるか確認する
bool Function IsStageTag(String asID, String asStage, String asTag) native global
bool Function IsStageTagA(String asID, String asStage, String[] asTags) native global
; 指定されたタグがポジションに含まれるか確認する
bool Function IsPositionTag(String asID, String asStage, int n, String asTag) native global
bool Function IsPositionTagA(String asID, String asStage, int n, String[] asTags) native global
; このシーンの全タグを取得する。シーンタグは全ステージタグを統合したもの
String[] Function GetSceneTags(String asID) native global
; このステージの全タグを取得する
String[] Function GetStageTags(String asID, String asStage) native global
; このポジションの全タグを取得する
String[] Function GetPositionTags(String asID, String asStage, int n) native global
; シーン一覧から、すべてのシーンに共通するタグを取得する
String[] Function GetCommonTags(String[] asIDs) native global

; --- アニメーション

; 指定されたステージのn番目のポジションに対応するアニメーションイベントを取得する
String Function GetAnimationEvent(String asID, String asStage, int n) native global
; 指定されたステージの全ポジションのアニメーションイベントを取得する
String[] Function GetAnimationEventA(String asID, String asStage) native global

; --- ナビゲーション

; このシーンの最初のアニメーションを取得する
String Function GetStartAnimation(String asID) native global
; このシーンのステージ総数を取得する
int Function GetNumStages(String asID) native global
String[] Function GetAllStages(String asID) native global

; 指定されたステージのn番目の出辺を取得する
String Function BranchTo(String asID, String asStage, int n) native global
; 指定されたステージから出る辺の数を取得する
int Function GetNumBranches(String asID, String asStage) native global
; 戻り値: None/無効 - -1 | 0 - Root | 1 - Common Node | 2 - Sink
int Function GetNodeType(String asID, String asStage) native global

; 指定されたステージから終端までの最短／最長経路を取得する
; 戻り値はasStageを含む終端までの経路: [asStage, ..., Sink]
String[] Function GetPathMin(String asID, String asStage) native global
String[] Function GetPathMax(String asID, String asStage) native global

; すべての終了ステージ／終端を取得する
String[] Function GetEndingStages(String asID) native global

; 固定長フラグが設定されたすべてのステージを取得する
String[] Function GetFixedLengthStages(String asID) native global
; このステージの固定長タイマーを返す。固定長フラグがない場合は0
float Function GetFixedLength(String asID, String asStage) native global

; 絶頂フラグが設定されたすべてのステージを取得する。n > -1 の場合、n番目のアクターが絶頂するステージのみを返す
String[] Function GetClimaxStages(String asID, int n = -1) native global
int[] Function GetClimaxingActors(String asID, String asStage) native global

; --- データ

; このシーンでアニメーションするアクター数を返す。任意ポジションを含めるか除外するか指定できる
int Function GetActorCount(String asID) native global

; シーン内でポジションnとmが同等か確認する。つまり、nを担当できるアクターがmも担当でき、その逆も可能か
bool Function IsSimilarPosition(String asID, int n, int m) native global
bool Function CanFillPosition(String asID, int n, Actor akActor) native global

; このシーンのn番目のポジションに適合する性別を取得する。「use creature sex」設定は無視する
; 次の意味を持つビットフラグを返す:
; Male = 0x1 | Female = 0x2 | Futa = 0x4 | CrtMale = 0x8 | CrtFemale = 0x10
int Function GetPositionSex(String asID, int n) native global
int[] Function GetPositionSexA(String asID) native global
bool Function GetIsMalePosition(String asID, int n) global
  return Math.LogicalAnd(GetPositionSex(asID, n), 0x1)
EndFunction
bool Function GetIsFemalePosition(String asID, int n) global
  return Math.LogicalAnd(GetPositionSex(asID, n), 0x2)
EndFunction
bool Function GetIsFutaPositon(String asID, int n) global
  return Math.LogicalAnd(GetPositionSex(asID, n), 0x4)
EndFunction
bool Function GetIsCreaturePositon(String asID, int n) global
  return Math.LogicalAnd(GetPositionSex(asID, n), 0x24)
EndFunction
bool Function GetIsMaleCreaturePositon(String asID, int n) global
  return Math.LogicalAnd(GetPositionSex(asID, n), 0x8)
EndFunction
bool Function GetIsFemaleCreaturePositon(String asID, int n) global
  return Math.LogicalAnd(GetPositionSex(asID, n), 0x16)
EndFunction
; このシーンのn番目のポジションのRaceKey IDを取得する
; 人間のRaceKey IDは0、クリーチャーは正の値
int Function GetRaceIDPosition(String asID, int n) native global
int[] Function GetRaceIDPositionA(String asID) native global
; RaceKeyを人が読める形式で取得する
String Function GetRaceKeyPosition(String asID, int n) native global
String[] Function GetRaceKeyPositionA(String asID) native global

; 指定されたステージとポジションの脱衣情報を取得する
; 脱衣データは8ビットフラグで表す:
; None = 0 | Helmet = 0x1 | Gloves = 0x2 | Boots = 0x4 | Default = 0x80 | All = 0xFF
int Function GetStripData(String asID, String asStage, int n) native global
int[] Function GetStripDataA(String asID, String asStage) native global

; --- オフセット
; オフセットは配列 [X, Y, Z, Rotation] として格納する
; 以下の配列はすべてこの形式を使用する。インデックス引数にはこの範囲のインデックスを指定する

; シーン全体のオフセット。家具シーンでない場合は[0, 0, 0, 0]を返す
float[] Function GetSceneOffset(String asID) native global
float[] Function GetSceneOffsetRaw(String asID) native global
; 指定されたシーンのオフセットを編集する。シーンで家具を使用しない場合は失敗する
Function SetSceneOffset(String asID, float afValue, int aiOffsetID) native global
Function SetSceneOffsetA(String asID, float[] afNewOffset) native global
Function ResetSceneOffset(String asID) native global
; 指定されたステージのポジションのオフセット。'raw' は未編集の(SLSB)オフセットを無視する
; 注: Rotationのオフセットはラジアンで返される。必要に応じてMath.RadiansToDegrees()を使用する
float[] Function GetStageOffset(String asID, String asStage, int n) native global
float[] Function GetStageOffsetRaw(String asID, String asStage, int n) native global
; 指定されたポジションとステージのオフセットを更新する。空のステージを渡すと、全ステージのオフセットを一括編集する
; 注: Rotationのオフセットは度数で指定し、内部でラジアンに変換される
Function SetStageOffset(String asID, String asStage, int n, float afValue, int aiOffsetID) native global
Function SetStageOffsetA(String asID, String asStage, int n, float[] afNewOffset) native global
Function ResetStageOffset(String asID, String asStage, int n) native global
Function ResetStageOffsetA(String asID, String asStage) native global

; --- シーン注釈

; 指定されたシーンに特定の注釈が存在するか確認する
bool Function HasSceneAnnotation(String asID, String asTag) native global
; 指定されたシーンから特定の注釈を削除する
Function RemoveSceneAnnotation(String asID, String asTag) native global
; 指定されたシーンに特定の注釈を追加する
Function AddSceneAnnotation(String asID, String asTag) native global
; 指定されたシーンのすべての注釈を取得する
String[] Function GetSceneAnnotations(String asID) native global

; --- ポジション注釈

; シーン内の指定されたポジションに特定の注釈が存在するか確認する
bool Function HasPositionAnnotation(String asID, int n, String asTag) native global
; シーン内の指定されたポジションから特定の注釈を削除する
Function RemovePositionAnnotation(String asID, int n, String asTag) native global
; シーン内の指定されたポジションに特定の注釈を追加する
Function AddPositionAnnotation(String asID, int n, String asTag) native global
; シーン内の指定されたポジションのすべての注釈を取得する
String[] Function GetPositionAnnotations(String asID, int n) native global
