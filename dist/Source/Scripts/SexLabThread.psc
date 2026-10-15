ScriptName SexLabThread extends Quest
{
  個々のSexLabスレッドを直接操作するAPIスクリプト
}

; 現在のスレッドID
; これは一意であり、フレームワークの他の部分からこのスレッドを参照するために使用できる
int Function GetThreadID()
EndFunction

; ------------------------------------------------------- ;
; --- スレッドの状態                                  --- ;
; ------------------------------------------------------- ;
;/
	実行時データの参照と操作
/;

int Property STATUS_UNDEF	= 0 AutoReadOnly  ; 未定義
int Property STATUS_IDLE	= 1 AutoReadOnly  ; 待機中（非アクティブ）
int Property STATUS_SETUP	= 2 AutoReadOnly  ; アニメーションを準備中。利用可能なデータが不完全な場合がある
int Property STATUS_INSCENE	= 3 AutoReadOnly  ; アニメーションを再生中
int Property STATUS_ENDING	= 4 AutoReadOnly  ; 終了中。データはまだ利用できるが、ほとんどの機能は無効

; スレッドの現在の状態を返す。この状態に応じてスレッドの機能が区分される
; 一部の機能は現在のスレッド状態に依存する
int Function GetStatus()
EndFunction

; 現在実行中のシーンを取得する
String Function GetActiveScene()
EndFunction
; 現在実行中のステージを取得する
String Function GetActiveStage()
EndFunction

; 現在のアニメーションで使用可能なすべてのシーンを取得する
String[] Function GetPlayingScenes()
EndFunction

; 現在のシーンの代わりに、引数で指定されたシーンを強制的に再生する
; 成功するとステージ履歴を削除し、新しいシーンに合わせてアクターを並べ替える
bool Function ResetScene(String asScene)
EndFunction

; 現在再生中のステージから分岐またはスキップする。再生状態以外で呼び出すと失敗する
; 指定された分岐／ステージが存在しない場合はシーンを終了する
Function BranchTo(int aiNextBranch)
EndFunction
Function SkipTo(String asNextStage)
EndFunction

; 再生済みの全ステージ（現在再生中のものを含む）の一覧を返す
; シーンがループした場合（例: A -> B -> C -> A）、一覧に重複が含まれることがあり、シーン変更時にリセットされる
; 内部履歴のコピーを作成するため、結果をキャッシュできる場合は繰り返し呼び出さないこと
String[] Function GetStageHistory()
EndFunction
; 上記と同じだが、履歴の長さのみを返す
int Function GetStageHistoryLength()
EndFunction

; このスレッドのアニメーションを停止する。スレッドが待機中／終了中の場合は失敗する
Function StopAnimation()
EndFunction

; ------------------------------------------------------- ;
; --- タグ                                            --- ;
; ------------------------------------------------------- ;
;/
	タグはシーンをさらに詳しく説明するために使われ、適用範囲が異なる:
		- ThreadTagsはスレッドで開始されたすべてのシーンに共通するタグをまとめる。例として、2つのシーンがある場合:
				["doggy", "loving", "behind"] と ["doggy", "loving", "hugging", "kissing"] の場合、スレッドタグは ["doggy", "loving"] となる
		- SceneTagsは再生中のシーンを大まかに表す。各タグは少なくとも1つのステージで使われる
		- StageTagsは現在再生中のステージのみを表す
/;

; このスレッドに指定されたタグが付いているか
bool Function HasTag(String asTag)
EndFunction
; アクティブなシーンに指定されたタグが付いているか
bool Function HasSceneTag(String asTag)
EndFunction
; アクティブなステージに指定されたタグが付いているか
bool Function HasStageTag(String asTag)
EndFunction

bool Function IsSceneVaginal()
	return HasSceneTag("Vaginal")
EndFunction
bool Function IsSceneAnal()
	return HasSceneTag("Anal")
EndFunction
bool Function IsSceneOral()
	return HasSceneTag("Oral")
EndFunction

; ------------------------------------------------------- ;
; --- コンテキスト                                    --- ;
; ------------------------------------------------------- ;
;/
	コンテキストデータはスレッドが所有する。シーンのコンテキストを指定するカスタムタグである
    カスタムコンテキストを使うと、他のModと間接的に通信できる
/;

; スレッドがコンテキストを所有しているか
bool Function HasContext(String asTag)
EndFunction

; シーンにコンテキストを追加／削除する
Function AddContext(String asContext)
EndFunction
Function RemoveContext(String asContext)
EndFunction

; 現在のアニメーションが合意のもとで行われているとみなされるか
bool Function IsConsent()
EndFunction
Function SetConsent(bool abIsConsent)
EndFunction

; ------------------------------------------------------- ;
; --- 衝突タイプの推定（物理）                        --- ;
; ------------------------------------------------------- ;
;/
	リアルタイムの衝突タイプ推定に基づいてインタラクションデータを検索する
	このデータはアクターの3D形状に基づく。信頼性は高いが、アニメーションの位置合わせに大きく左右される
/;

int Property CTYPE_ANY				= -1 	AutoReadOnly
int Property CTYPE_Vaginal			= 1 	AutoReadOnly	; 相手に挿入されているポジション
int Property CTYPE_Anal				= 2 	AutoReadOnly	; 相手に挿入されているポジション
int Property CTYPE_Oral				= 3 	AutoReadOnly	; 相手を舐める／吸うポジション
int Property CTYPE_Grinding			= 4 	AutoReadOnly	; 相手の股間に擦り付けられているポジション
int Property CTYPE_Deepthroat		= 5 	AutoReadOnly	; Oralを含み、相手のペニスが最大深度付近まで挿入されている
int Property CTYPE_Skullfuck		= 6 	AutoReadOnly	; 相手が通常とは異なる形で頭部に挿入しているポジション（通常はゴア表現）
int Property CTYPE_LickingShaft		= 7 	AutoReadOnly	; 相手のペニスを舐めるポジション
int Property CTYPE_FootJob			= 8 	AutoReadOnly	; 少なくとも片足を使って相手を刺激するポジション
int Property CTYPE_HandJob			= 9 	AutoReadOnly	; 少なくとも片手を使って相手を刺激するポジション
int Property CTYPE_Kissing			= 10 	AutoReadOnly	; 相手とキスをするポジション
int Property CTYPE_Facial			= 11 	AutoReadOnly	; 相手のペニスの前に顔を置くポジション
int Property CTYPE_AnimObjFace		= 12 	AutoReadOnly	; 相手のアニメーションオブジェクトノードの近くに口を置くポジション
int Property CTYPE_SuckingToes		= 13	AutoReadOnly	; 相手のつま先の近くに口を置くポジション

; 衝突関連データが現在利用可能か
bool Function IsInteractionRegistered()
EndFunction

; 2人のアクター間で発生している全タイプのインタラクション一覧を取得する
; akPartnerがnoneの場合、任意の相手との全インタラクションを返す
; この関数は可換ではない。インタラクションの方向についてはタイプの説明を参照
int[] Function GetInteractionTypes(Actor akPosition, Actor akPartner)
EndFunction

; akPositionが指定されたタイプでakPartnerとインタラクションしているか
; akPartnerがnoneの場合、利用可能なすべての相手を確認する
; akPositionがnoneの場合、すべてのポジションを調べる
; 両方がnoneの場合、いずれかのポジションに指定タイプがあるかを返す
bool Function HasInteractionType(int aiType, Actor akPosition, Actor akPartner)
EndFunction

; 指定されたタイプでakPositionとインタラクションする最初のアクターを返す
; 配列版にNONEを指定すると、そのタイプに関与する全アクターを返す
; この場合、GetPartnersByType() == GetPartnersByTypeRev() が成立する
; （タイプで定義されたインタラクションの方向を考慮する）
; （返される値はシーン内の全ポジションの部分集合）
Actor Function GetPartnerByType(Actor akPosition, int aiType)
EndFunction
Actor[] Function GetPartnersByType(Actor akPosition, int aiType)
EndFunction
; 上記と同様だが、逆方向から情報を取得する。例:
; GetPartnersByType(Act, ORAL)は、Actがオーラルを受けている相手をすべて返す
; GetPartnersByTypeRev(Act, ORAL)は、Actがオーラルをしている相手をすべて返す
Actor Function GetPartnerByTypeRev(Actor akPartner, int aiType)
EndFunction
Actor[] Function GetPartnersByTypeRev(Actor akPartner, int aiType)
EndFunction

; 指定されたインタラクションタイプの速度を返す
; 移動方向に応じて速度は正または負になる
float Function GetVelocity(Actor akPosition, Actor akPartner, int aiType)
EndFunction

; ------------------------------------------------------- ;
; --- インタラクション情報                            --- ;
; ------------------------------------------------------- ;
;/
	シーン中の任意の時点における、アクターのインタラクションの詳細な判定。
	この判定は衝突タイプの推定に基づき、必要に応じて位置タグを代替手段として利用する。
/;

;--> アクターが陰茎以外による刺激を受けている
int Property pStimulation			= 0  AutoReadOnly Hidden	;pos_crotchを指、拳、または玩具で刺激されている
int Property aAnimObjFace			= 1  AutoReadOnly Hidden	;pos_anim_objが相手の顔の前にある
int Property pAnimObjFace			= 2  AutoReadOnly Hidden	;pos_faceが相手のanim_objの前にある
;--> アクターの身体が刺激を受けている／何かをしている
int Property pSuckingToes			= 3  AutoReadOnly Hidden	;pos_toesが相手の口に近い
int Property pGrinding				= 4  AutoReadOnly Hidden	;pos_bodyを相手の股間に擦り付けられている
int Property pSkullfuck				= 5  AutoReadOnly Hidden	;pos_headに相手のppが挿入されている
int Property aHandJob				= 6  AutoReadOnly Hidden	;pos_handが相手のppの周りを動いている
int Property aFootJob				= 7  AutoReadOnly Hidden	;pos_footが相手のppの周りを動いている
int Property aBoobJob				= 8  AutoReadOnly Hidden	;pos_boobが相手のppの周りを動いている
;--> アクターが口で何かをしている
int Property bKissing				= 9  AutoReadOnly Hidden	;pos_faceが相手の顔の前にある
int Property aSuckingToes			= 10  AutoReadOnly Hidden	;pos_faceが相手のつま先の前にある
int Property pFacial				= 11  AutoReadOnly Hidden	;pos_faceが相手のppの前にある
int Property aOral					= 12  AutoReadOnly Hidden	;pos_mouthで相手の股間を舐める／吸う
int Property aLickingShaft			= 13  AutoReadOnly Hidden	;pos_mouthで相手のppの shaft を舐める
int Property aDeepthroat			= 14  AutoReadOnly Hidden	;pos_mouthで相手のppをディープスロートする
;--> アクターが陰茎による挿入を受けている
int Property pVaginal				= 15  AutoReadOnly Hidden	;pos_vagに相手のppが挿入されている
int Property pAnal					= 16  AutoReadOnly Hidden	;pos_anusに相手のppが挿入されている
;--> アクターのppが何かをしている
int Property aFacial				= 17  AutoReadOnly Hidden	;pos_ppが相手の顔の前にある
int Property aGrinding				= 18  AutoReadOnly Hidden	;pos_crotchを相手の身体に擦り付けている
int Property pHandJob				= 19  AutoReadOnly Hidden	;pos_ppを相手の手で刺激されている
int Property pFootJob				= 20  AutoReadOnly Hidden	;pos_ppを相手の足で刺激されている
int Property pBoobJob				= 21  AutoReadOnly Hidden	;pos_ppを相手の胸で刺激されている
int Property pLickingShaft			= 22  AutoReadOnly Hidden	;pos_ppのshaftを相手の舌で舐められている
int Property pOral					= 23  AutoReadOnly Hidden	;pos_crotchを相手の口で舐める／吸う
int Property pDeepthroat			= 24  AutoReadOnly Hidden	;pos_ppが相手の口の奥深くに入っている
int Property aSkullfuck				= 25  AutoReadOnly Hidden	;pos_ppで相手の頭部に挿入している
int Property aVaginal				= 26  AutoReadOnly Hidden	;pos_ppで相手の膣に挿入している
int Property aAnal					= 27  AutoReadOnly Hidden	;pos_ppで相手の肛門に挿入している

int Property SUPPORTED_INTER_COUNT	= 28  AutoReadOnly Hidden

; 指定されたアクターについて、上記の順序で28個のboolを含む配列を返す
; アクターが関与している要素のみTRUEになる
; フラグはAliasのOnUpdate()で快感値とともに更新されるため、頻繁に呼び出しても安全
; 使用例: 女性が二重挿入を受けているか判定する
;		SexLabThread _Thread = SexLab.GetThreadByActor(akPosition)
;		bool[] interFlags = _Thread.GetCurrentInteractionFlags(akPosition)
;	 	If (interFlags[15] && interFlags[16]) // 15:pVaginal, 16:pAnal
;			// DO_SOMETHING
; ヒント: インデックスには_Thread.pVaginalも使用できる:
;		If (interFlags[_Thread.pVaginal] && interFlags[_Thread.pAnal])
;			// DO_SOMETHING
bool[] Function GetCurrentInteractionFlags(Actor akPosition)
EndFunction

; 指定されたアクターについて、指定されたInterType（範囲: 0～27）が検出されているか確認する
; 使用例: アクターが現在オーラルを受けているか判定する
;		If (_Thread.HasCurrentInteractionFlag(akPosition, _Thread.pOral)
;			// DO_SOMETHING
; 使用例: アクターが足コキをしている、または受けているか判定する
;		int[] typesFJ = new int[2]
;		typesFJ[0] = _Thread.aFootJob
;		typesFJ[1] = _Thread.pFootJob
;		If (_Thread.HasCurrentInteractionFlagsAny(akPosition, typesFJ)
;			// DO_SOMETHING
bool Function HasCurrentInteractionFlag(Actor akPosition, int InterType)
EndFunction
bool Function HasCurrentInteractionFlagsAll(Actor akPosition, int[] InterTypes)
EndFunction
bool Function HasCurrentInteractionFlagsAny(Actor akPosition, int[] InterTypes)
EndFunction

; 検出されたInterTypeを含む、カンマ区切りの文字列（または文字列配列）を返す
; 要求時に生成するため、bool[]を使う方法より呼び出し効率が低い
; 使用例: デバッグ用に検出されたインタラクションを人が読める一覧で取得する
;		MiscUtil.PrintConsole(GetCurrentInteractionString(akPosition))
; 使用例: boolではなく文字列で検出済みインタラクションを検索する
;		string[] interStr = GetCurrentInteractionStringA(akPosition)
;		If interStr.Find("aOral") 
;			/ DO_SOMETHING
string Function GetCurrentInteractionString(Actor akPosition)
EndFunction
string[] Function GetCurrentInteractionStringA(Actor akPosition)
EndFunction

; ------------------------------------------------------- ;
; --- 特定の検出                                      --- ;
; ------------------------------------------------------- ;
;/
	タグベースの検出方法より優れた代替手段
/;

bool Function IsVaginalComplex(Actor akPosition)
EndFunction
bool Function IsAnalComplex(Actor akPosition)
EndFunction
bool Function IsOralComplex(Actor akPosition)
EndFunction

; ------------------------------------------------------- ;
; --- 時刻データ                                      --- ;
; ------------------------------------------------------- ;
;/
	時間関連データ
/;

; スレッドが開始した時刻
; セーブデータ作成からの実時間（秒）で返される
float Function GetTime()
EndFunction
; スレッドの現在までの合計実行時間を返す
float Function GetTimeTotal()
EndFunction

; ------------------------------------------------------- ;
; --- ポジション情報                                  --- ;
; ------------------------------------------------------- ;
;/
	ポジション関連データを参照・操作する関数
/;

; このアクターがシーンに参加しているか
bool Function HasActor(Actor akActor)
EndFunction
bool Function HasPlayer()
EndFunction

; 現在のシーンの全ポジションを取得する。アクターの順序は規定されない
Actor[] Function GetPositions()
EndFunction

; スレッド内におけるこのアクターのポジションのインデックスを取得する
int Function GetPositionIdx(Actor akActor)
EndFunction

; スレッドで使用される、このポジションの性別を取得する
int Function GetActorSex(Actor akActor)
EndFunction
int Function GetNthPositionSex(int n)
EndFunction
int[] Function GetPositionSexes()
EndFunction

; --- 服従状態

; 指定されたアクターが受け手かどうかを返す
bool Function GetSubmissive(Actor akActor)
EndFunction
Function SetIsSubmissive(Actor akActor, bool abIsSubmissive)
EndFunction
; 現在のアニメーションにおけるすべての受け手を取得する
Actor[] Function GetSubmissives()
EndFunction

; --- 脱衣

; このアクターのカスタム脱衣設定を行う
; aiSlotsは、可能な場合に装備解除するスロットすべてのマスクを表す
Function SetCustomStrip(Actor akActor, int aiSlots, bool abWeapon, bool abApplyNow)
EndFunction
Function ResetCustomStrip(Actor akActor)
EndFunction
; シーン開始時の脱衣中に短いアニメーションを再生するか。再生状態に入る前のみ使用される
bool Function IsUndressAnimationAllowed(Actor akActor)
EndFunction
Function SetIsUndressAnimationAllowed(Actor akActor, bool abAllowed)
EndFunction
; アニメーション後に装備を再装着するか（受け手でない場合）
bool Function IsRedressAllowed(Actor akActor)
EndFunction
Function SetIsRedressAllowed(Actor akActor, bool abAllowed)
EndFunction

; --- 音声

; 指定されたアクターの音声を更新する
Function SetActorVoice(Actor akActor, String asVoice, bool abForceSilent)
EndFunction
String Function GetActorVoice(Actor akActor)
EndFunction

; --- 表情

; 指定されたアクターの表情を更新する
Function SetActorExpression(Actor akActor, String asExpression)
EndFunction
String Function GetActorExpression(Actor akActor)
EndFunction

; --- 快感

; このアクターの現在の快感／興奮度を返す
int Function GetEnjoyment(Actor ActorRef)
EndFunction
; このアクターの現在の快感を指定値に設定／指定値分調整する
Function SetEnjoyment(Actor ActorRef, int aiSet)
EndFunction
Function AdjustEnjoyment(Actor ActorRef, int AdjustBy)
EndFunction
; アクターの快感上昇率を変更する
; afSet == 2でEnjRaiseが2倍になり、afSet == 0でEnjRaiseが停止する
Function ModEnjoymentMult(Actor ActorRef, float afSet, bool bAdjust = False)
EndFunction

; --- 絶頂

; 指定されたアクターの絶頂イベントを無効化／有効化する
Function DisableOrgasm(Actor ActorRef, bool OrgasmDisabled = true)
EndFunction
bool Function IsOrgasmAllowed(Actor ActorRef)
EndFunction
; 指定されたアクターの絶頂イベントを作成する
Function ForceOrgasm(Actor ActorRef)
EndFunction

; シーン中に指定されたアクターが妊娠する可能性があるか。シーン中にこのアクターが絶頂した男性アクターと
; 直接または間接的に膣で接触したかを確認する
; この関数は、すでに再生されたステージのみを対象とする
; --- 引数
; abAllowFutaImpregnation - akActorがFutaの場合でも妊娠可能か
; abFutaCanPregnate - 絶頂したアクターがFutaの場合、相手を妊娠させられるか
; abCreatureCanPregnate - 絶頂したアクターがクリーチャーの場合、相手を妊娠させられるか
; --- 戻り値
; 指定されたアクターと膣性交したすべてのアクター
Actor[] Function CanBeImpregnated(Actor akActor, bool abAllowFutaImpregnation, bool abFutaCanPregnate, bool abCreatureCanPregnate)
EndFunction

; --- ストラップオン

; このアクターが使用するストラップオンを設定する。使用対象として無効な場合は失敗する
Function SetStrapon(Actor ActorRef, Form ToStrapon)
endfunction
Form Function GetStrapon(Actor ActorRef)
endfunction
; 指定されたアクターが現在ストラップオンを使用しているか
bool Function IsUsingStrapon(Actor ActorRef)
EndFunction

; --- 経路探索
int Property PATHING_DISABLE = -1 AutoReadOnly	; 常にテレポートする
int Property PATHING_ENABLE = 0 AutoReadOnly		; ユーザー設定に従う（既定）
int Property PATHING_FORCE = 1 AutoReadOnly			; 距離が遠すぎない限り、必ず歩かせる

; ポジションの経路探索フラグを設定し、このアクターが中心まで歩くか、テレポートするかを決める
; 再生状態に入る前のみ設定できる
Function SetPathingFlag(Actor akActor, int aiPathingFlag)
EndFunction

; ------------------------------------------------------- ;
; --- VRIK設定と初期化                                --- ;
; ------------------------------------------------------- ;

; アクティブなシーンの実行中、SLのVRIK設定を一時的に指定する関数
; 使用例: アニメーションに合わせて手を拘束する: SexLabUtil.SetConfigsVRIK(true, true, aiTrackHands=0)
Function SetConfigsVRIK(bool abEnabled=true, bool abOverrideConfig=false, int aiPOVMode=-1, \
	int abLockHeight=-1, float afHeightAdjSpeed=-1.0, int abTrackHead=-1, int aiTrackHands=-1, \
	float afDistHideHead=-1.0, float afDistNearClip=-1.0, int aiLockHmdToBody=-1, \
	float afLockHmdDistance=-1.0, float afLockHmdTolerance=-1.0, float afLockHmdSpeed=-1.0)
EndFunction