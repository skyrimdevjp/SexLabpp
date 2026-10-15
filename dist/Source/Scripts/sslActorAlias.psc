ScriptName sslActorAlias extends ReferenceAlias
{
	SexLab Threadでアニメーションするアクター用のAliasスクリプト
	このクラスへの正しいアクセス方法と関数についてはSexLabThread.pscを参照
}

String Function GetActorName()
	return _ActorRef.GetLeveledActorBase().GetName()
EndFunction

bool function IsVictim()
	return _victim
endFunction

bool Function IsAggressor()
	return _Thread.IsAggressive && !IsVictim()
EndFunction

Function SetVictim(bool Victimize)
	_victim = Victimize
EndFunction

int Function GetSex()
	return _sex
EndFunction

int Function GetRaceID()
	return _raceID
EndFunction

bool Function GetIsDead()
	return _livestatus == LIVESTATUS_DEAD
EndFunction

; ------------------------------------------------------- ;
; --- 絶頂                                            --- ;
; ------------------------------------------------------- ;

function DisableOrgasm(bool bNoOrgasm)
	_CanOrgasm = !bNoOrgasm
endFunction

bool function IsOrgasmAllowed()
	return _CanOrgasm
endFunction

int function GetOrgasmCount()
	return _OrgasmCount
EndFunction

; ------------------------------------------------------- ;
; --- 快感                                            --- ;
; ------------------------------------------------------- ;

int Function GetEnjoyment()
	return _FullEnjoyment
EndFunction

; 快感値は常に-100から100の範囲内に保たれる。負の快感値は痛みとして扱われる。
Function SetEnjoyment(int aiSet)
	_FullEnjoyment = PapyrusUtil.ClampInt(aiSet, -100, 100)
EndFunction

Function AdjustEnjoyment(int AdjustBy)
	_FullEnjoyment = PapyrusUtil.ClampInt(_FullEnjoyment + AdjustBy, -100, 100)
EndFunction

Function ModEnjoymentMult(float afSet, bool bAdjust)
	If bAdjust
		_ModEnjMult += afSet
	Else
		_ModEnjMult = afSet
	EndIf
EndFunction

; ------------------------------------------------------- ;
; --- インタラクション情報                            --- ;
; ------------------------------------------------------- ;

bool[] Function GetCurrentInteractionFlags()
	return _CurrentInteractions
EndFunction

; ------------------------------------------------------- ;
; --- 特定の検出                                      --- ;
; ------------------------------------------------------- ;

bool Function IsVaginalComplex()
	return (_CurrentInteractions[_Thread.aVaginal] || _CurrentInteractions[_Thread.pVaginal] \
	|| _CurrentInteractions[_Thread.aGrinding] || _CurrentInteractions[_Thread.pGrinding])
EndFunction

bool Function IsAnalComplex()
	return (_CurrentInteractions[_Thread.aAnal] || _CurrentInteractions[_Thread.pAnal])
EndFunction

bool Function IsOralComplex()
	return (_CurrentInteractions[_Thread.aOral] || _CurrentInteractions[_Thread.pOral] \
	|| _CurrentInteractions[_Thread.aLickingShaft] || _CurrentInteractions[_Thread.pLickingShaft] \
	|| _CurrentInteractions[_Thread.aDeepthroat] || _CurrentInteractions[_Thread.pDeepthroat])
EndFunction

bool Function ShouldMouthOpen()
	bool condNonCrotch = (_CurrentInteractions[_Thread.aSuckingToes] || _CurrentInteractions[_Thread.pAnimObjFace])
	bool condCrotch = (_CurrentInteractions[_Thread.aOral] || _CurrentInteractions[_Thread.aLickingShaft] || _CurrentInteractions[_Thread.aDeepthroat])
	If (!condNonCrotch && !condCrotch)
		return false
	ElseIf (condNonCrotch)
		return true
	EndIf
	bool FemInNonGayScene = ((_sex==1 || _sex==4) && !_HomoTypes[2])
	bool NonFemInGayScene = ((_sex==0 || _sex==2 || _sex==3) && (_HomoTypes[0] || _HomoTypes[4]))
	return (FemInNonGayScene || NonFemInGayScene)
EndFunction

bool Function IsAnalPenetrated()
	return _CurrentInteractions[_Thread.pAnal]
EndFunction

bool Function IsGenitalInteraction()
	int pSex = SexLabRegistry.GetSex(_ActorRef, false)
	bool handjob = _CurrentInteractions[_Thread.pHandJob]
	bool footjob = _CurrentInteractions[_Thread.pFootJob]
	bool oral = _CurrentInteractions[_Thread.pOral]
	If (handjob || footjob || oral)
		return true
	EndIf
	If (pSex != 0)
		bool vaginal = _CurrentInteractions[_Thread.pVaginal]
		bool grinding = _CurrentInteractions[_Thread.pGrinding]
		If (vaginal || grinding)
			return true
		EndIf
	EndIf
	If (pSex != 1)
		bool anal = _CurrentInteractions[_Thread.aAnal]
		bool vaginal = _CurrentInteractions[_Thread.aVaginal]
		bool grinding = _CurrentInteractions[_Thread.aGrinding]
		bool skull = _CurrentInteractions[_Thread.aSkullfuck]
		bool shaft = _CurrentInteractions[_Thread.pLickingShaft]
		If (anal || vaginal || grinding || skull || shaft)
			return true
		EndIf
	EndIf
	return false
EndFunction

; ------------------------------------------------------- ;
; --- 脱衣                                            --- ;
; ------------------------------------------------------- ;

Function SetStripping(int aiSlots, bool abStripWeapons, bool abApplyNow)
	_stripCstm = new int[2]
	_stripCstm[0] = aiSlots
	_stripCstm[1] = abStripWeapons as int
	If (abApplyNow && GetState() == STATE_PLAYING)
		int[] set
		_equipment = StripByDataEx(0x80, set, _stripCstm, _equipment)
		_ActorRef.QueueNiNodeUpdate()
	EndIf
EndFunction

Function DeleteCustomStripping()
	_stripCstm = new int[1]
EndFunction

Function DisableStripAnimation(bool abDisable)
	_DoUndress = !abDisable
EndFunction

Function SetAllowRedress(bool abAllowRedress)
	_AllowRedress = abAllowRedress
EndFunction

; ------------------------------------------------------- ;
; --- ストラップオン                                  --- ;
; ------------------------------------------------------- ;

Form function GetStrapon()
	return _Strapon
endFunction

bool function IsUsingStrapon()
	return _useStrapon && _Strapon && _ActorRef.IsEquipped(_Strapon)
endFunction

Function SetStrapon(Form ToStrapon)
	Error("Called from invalid state", "SetStrapon()")
EndFunction

; ------------------------------------------------------- ;
; --- 音声                                            --- ;
; ------------------------------------------------------- ;

String Function GetActorVoice() native

Function SetActorVoiceImpl(String asNewVoice) native
Function SetActorVoice(String asNewVoice, bool abForceSilent)
	SetActorVoiceImpl(asNewVoice)
	_IsForcedSilent = abForceSilent
EndFunction

bool Function IsSilent()
	return IsSilent
EndFunction

; ------------------------------------------------------- ;
; --- 表情                                            --- ;
; ------------------------------------------------------- ;

String Function GetActorExpression() native

Function SetActorExpressionImpl(String asExpression) native
Function SetActorExpression(String asExpression)
	SetActorExpressionImpl(asExpression)
	TryRefreshExpression()
EndFunction

Function SetMouthForcedOpen(bool abForceOpen)
	OpenMouth = abForceOpen
EndFunction

; ------------------------------------------------------- ;
; --- 経路探索                                        --- ;
; ------------------------------------------------------- ;

int Property PATHING_DISABLE = -1 AutoReadOnly
int Property PATHING_ENABLE = 0 AutoReadOnly
int Property PATHING_FORCE = 1 AutoReadOnly

Function SetPathing(int aiPathingFlag)
	_PathingFlag = PapyrusUtil.ClampInt(_PathingFlag, PATHING_DISABLE, PATHING_FORCE)
EndFunction

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

sslThreadModel _Thread
sslSystemConfig _Config

Faction _AnimatingFaction
Actor _PlayerRef

; 定数
String Property STATE_IDLE 		= "Empty" AutoReadOnly
String Property STATE_SETUP		= "Ready" AutoReadOnly
String Property STATE_PAUSED	= "Paused" AutoReadOnly
String Property STATE_PLAYING = "Animating" AutoReadOnly

String Property TRACK_ADDED 	= "Added" AutoReadOnly
String Property TRACK_START 	= "Start" AutoReadOnly
String Property TRACK_ORGASM 	= "Orgasm" AutoReadOnly
String Property TRACK_END		 	= "End" AutoReadOnly

int Property LIVESTATUS_ALIVE 			= 0 AutoReadOnly
int Property LIVESTATUS_DEAD 				= 1 AutoReadOnly
int Property LIVESTATUS_UNCONSCIOUS = 2 AutoReadOnly

; ------------------------------------------------------- ;
; --- Aliasデータ                                     --- ;
; ------------------------------------------------------- ;

; アクター
Actor _ActorRef
Actor Property ActorRef
	Actor Function Get()
		return _ActorRef
	EndFunction
EndProperty

int _sex
int _raceID
bool _victim

int _livestatus
Actor _killer

int _AnimVarIsNPC
bool _AnimVarbHumanoidFootIKDisable

bool _ActorLocked

; 絶頂
int _OrgasmCount
bool _CanOrgasm
bool _hasOrgasm

; 脱衣
int _stripData		; アニメーションから渡された脱衣データ
int[] _stripCstm	; 作者が指定した脱衣データ -> [ArmorFlag, bStripWeapon]	
Form[] _equipment	; [HighHeelSpell, WeaponRight, WeaponLeft, Armor...]

bool _AllowRedress
bool property DoRedress
	bool function get()
		return _AllowRedress && (!IsVictim() || _Config.RedressVictim)
	endFunction
	function set(bool value)
		_AllowRedress = value
	endFunction
endProperty

bool _DoUndress
bool property DoUndress
	bool function get()
		return _Config.UndressAnimation && _DoUndress && GetState() != STATE_PLAYING
	endFunction
	function set(bool value)
		_DoUndress = value
	endFunction
endProperty

; ストラップオン
bool _useStrapon
Form _Strapon			; アニメーションで使用するストラップオン
Form _HadStrapon	; アニメーション開始前に装備していたストラップオン

; 音声
bool _IsForcedSilent
float _VoiceDelay
float _ExpressionDelay

bool property IsSilent hidden
	bool function get()
		return _IsForcedSilent || GetActorVoice() == ""
	endFunction
endProperty

; 表情
bool Property ForceOpenMouth Auto Hidden
bool Property OpenMouth
	bool Function Get()
		If (ForceOpenMouth)
			return true
		EndIf
		return ShouldMouthOpen()
	EndFunction
	Function Set(bool abSet)
		ForceOpenMouth = abSet
	EndFunction
EndProperty

; 経路探索
int _PathingFlag
bool property DoPathToCenter
	bool function get()
		return _PathingFlag == PATHING_FORCE || (_PathingFlag == PATHING_ENABLE && _Config.DisableTeleport)
	endFunction
endProperty

; 時刻
float _StartedAt
float _LastOrgasm

; ------------------------------------------------------- ;
; --- Alias待機中                                     --- ;
; ------------------------------------------------------- ;
;/
	所有元スレッドの初期化を待つIdle状態
	この状態では参照がnullで、関連データはすべて無効

	この状態でAliasと関連データを設定し、その後"Ready"状態へ移行する
/;

Auto State Empty
	bool Function SetActor(Actor ProspectRef)
		ForceRefTo(ProspectRef)
		_ActorRef = ProspectRef
		If (_ActorRef.IsDead())
			_livestatus = LIVESTATUS_DEAD
			_killer = _ActorRef.GetKiller()
		ElseIf (_ActorRef.IsUnconscious())
			_livestatus = LIVESTATUS_UNCONSCIOUS
		Else
			_livestatus = LIVESTATUS_ALIVE
		EndIf
		_sex = SexLabRegistry.GetSex(_ActorRef, true)
		_raceID = SexLabRegistry.GetRaceID(_ActorRef)
		_ActorRef.SetFactionRank(_AnimatingFaction, 1)
		TrackedEvent(TRACK_ADDED)
		GoToState(STATE_SETUP)
		return true
	EndFunction

	Function Clear()
		If (GetIsDead())
			If (_ActorRef.IsEssential())
				_ActorRef.GetActorBase().SetEssential(false)
			EndIf
			_ActorRef.KillSilent(_killer)
		Else
			_Thread.RequestStatisticUpdate(_ActorRef, _StartedAt)
		EndIf
		_ActorRef.SetFactionRank(_AnimatingFaction, -1)
		_Thread.UpdateAnimatingActorMovement(_ActorRef) ;MOVEMENT_RELEASE
		Parent.Clear()
	EndFunction

	String Function GetActorName()
		return "EMPTY"
	EndFunction

	Event OnEndState()
		RegisterForModEvent("SSL_CLEAR_Thread" + _Thread.tid, "OnRequestClear")
	EndEvent
EndState

bool Function SetActor(Actor ProspectRef)
	Error("Not in idle phase", "SetActor")
	return false
EndFunction

Function NativeActorLockApplied()
	If (_ActorLocked)
		return
	EndIf
	_Thread.UpdateAnimatingActorMovement(_ActorRef) ;MOVEMENT_LOCK
	If (_ActorRef == _PlayerRef)
		_Config.ToggleVRIK(true, _Config.VRIK_FPP_HMD)
		If(_Config.AutoTFC)
			SexLabUtil.ToggleFreeCamera(1) ;TFC_ON
		EndIf
	EndIf
	Log("Locked Actor: " + GetActorName())
	_ActorLocked = True
EndFunction

; ------------------------------------------------------- ;
; --- Alias準備中                                     --- ;
; ------------------------------------------------------- ;
;/
	アニメーション開始前。Aliasは基盤となるスレッドがアニメーションを開始するのを待機する
/;

State Ready
	Event OnBeginState()
		RegisterForModEvent("SSL_PREPARE_Thread" + _Thread.tid, "OnDoPrepare")
	EndEvent

	Function SetStrapon(Form ToStrapon)
		_Strapon = ToStrapon
	EndFunction
	
	Function SetActorVoice(String asNewVoice, bool abForceSilent)
		_IsForcedSilent = abForceSilent
		If (asNewVoice)
			sslVoiceSlots.StoreVoice(ActorRef, asNewVoice)
		EndIf
	EndFunction

	Event OnDoPrepare(string asEventName, string asStringArg, float afNumArg, form akPathTo)
		UnregisterForModEvent("SSL_PREPARE_Thread" + _Thread.tid)
		WaitForPathToCenter(akPathTo)
		If (_sex <= 2)
			_AnimVarIsNPC = _ActorRef.GetAnimationVariableInt("IsNPC")
			_AnimVarbHumanoidFootIKDisable = _ActorRef.GetAnimationVariableBool("bHumanoidFootIKDisable")
		EndIf		
		GoToState(STATE_PAUSED)
		; 遅延初期化
		If (_sex <= 2)
			If (_sex == 0)
				_VoiceDelay = _Config.MaleVoiceDelay
			Else
				_VoiceDelay = _Config.FemaleVoiceDelay
				If (_sex == 1)
					_HadStrapon = _Config.WornStrapon(_ActorRef)
					If (!_HadStrapon)
						_Strapon = _Config.GetStrapon()
					ElseIf (!_Strapon)
						_Strapon = _HadStrapon
					EndIf
				EndIf
			EndIf
		Else	; クリーチャー
			_VoiceDelay = 3.0
		EndIf
		_ExpressionDelay = 1.0
		If (_Config.DebugMode)
			Log("Strapon[" + _Strapon + "] Voice[" + GetActorVoice() + "] Expression[" + GetActorExpression() + "]")
		EndIf
		If (asStringArg != "skip")
			_Thread.PrepareDone()
		EndIf
	EndEvent

	Function WaitForPathToCenter(form akPathTo)	
		If(_ActorRef == _PlayerRef)
			bool bVRTPP = _Config.HasVRIK && (_Config.POVModeVR == 2)
			Game.DisablePlayerControls(abMovement=!bVRTPP, abFighting=false, abCamSwitch=false, abLooking=false, abSneaking=false, abMenu=false, abActivate=false, abJournalTabs=false)
			return
		EndIf
		_Config.CheckBardAudience(_ActorRef, true)
		If(!akPathTo || !DoPathToCenter)
			return
		EndIf
		ObjectReference target = akPathTo as ObjectReference
		float distance = _ActorRef.GetDistance(target)		
		float target_distance = _Thread.CalcPathingTargetDistance(_raceID)
		If(distance > target_distance && distance <= 6144.0)
			_ActorRef.SetFactionRank(_AnimatingFaction, 2)
			_Thread.UpdateAnimatingActorMovement(_ActorRef) ;MOVEMENT_UNLOCK
			float fallback_timer = 15.0
			float prev_dist = distance + 1.0
			Utility.Wait(2.0)
			float interval = 0.05
			While (distance > target_distance && Math.abs(prev_dist - distance) > 0.5 && fallback_timer > 0)
				fallback_timer -= interval
				Utility.Wait(interval)
				prev_dist = distance
				distance = _ActorRef.GetDistance(target)
			EndWhile
		EndIf
	EndFunction

	Function Clear()
		GoToState(STATE_IDLE)
		Clear()
	EndFunction
	Function Initialize()
		Clear()
		Initialize()
	EndFunction

EndState

Event OnDoPrepare(string asEventName, string asStringArg, float afNumArg, form akPathTo)
	Error("Preparation request outside a valid state", "OnDoPrepare()")
EndEvent
Function WaitForPathToCenter(form akPathTo)
	Error("Pathing request outside a valid state", "WaitForPathToCenter()")
EndFunction

; --- レガシー

Event PrepareActor()
EndEvent
Function PathToCenter()
EndFunction

; ------------------------------------------------------- ;
; --- Alias一時停止                                   --- ;
; ------------------------------------------------------- ;
;/
	Aliasが設定された後、実際のアニメーション開始中または直前に入る2つ目のIdle状態
	この状態のアクターは自由に歩き回ることができる

	この状態が最初に呼び出された時点で、関連データはすべて設定済みであり、アクターは
	装備解除情報と実際のアニメーション呼び出しを待っているものとする
/;

State Paused
	Function LockActor()
		If (_ActorLocked)
			return
		EndIf
		_ActorRef.SetActorValue("Paralysis", 0.0)
		_ActorRef.SetFactionRank(_AnimatingFaction, 1)
		_ActorRef.SetAnimationVariableInt("IsNPC", 0)
		_ActorRef.SetAnimationVariableBool("bHumanoidFootIKDisable", 1)
		_Thread.UpdateAnimatingActorMovement(_ActorRef) ;MOVEMENT_LOCK
		If (_ActorRef == _PlayerRef)
			_Config.ToggleVRIK(true, _Config.VRIK_FPP_HMD)
			If(_Config.AutoTFC)
				SexLabUtil.ToggleFreeCamera(1) ;TFC_ON
			EndIf
		EndIf
		Log("Locked Actor: " + GetActorName())
		_ActorLocked = True
	EndFunction
	Function TryLockAndUnpause()
		LockActor()
		GoToState(STATE_PLAYING)
	EndFunction

	bool Function InitiateUndressing()
		If (_sex <= 2)
			If (DoUndress)
				If (_sex == 0)
					Debug.SendAnimationEvent(_ActorRef, "SexLab_MaleUndress")
				Else
					Debug.SendAnimationEvent(_ActorRef, "SexLab_FemaleUndress")
				EndIf
				return true
			EndIf
		EndIf
		return false
	EndFunction
	Function ReadyActor(int aiStripData, int aiPositionGenders)
		_stripData = aiStripData
		_useStrapon = _sex == 1 && Math.LogicalAnd(aiPositionGenders, 0x2) == 0
		If (_sex <= 2)
			_equipment = StripByData(_stripData, GetStripSettings(), _stripCstm)
			ResolveStrapon()
			_ActorRef.QueueNiNodeUpdate()
		EndIf
		Debug.SendAnimationEvent(_ActorRef, "SOSBend0")
		RegisterForModEvent("SSL_READY_Thread" + _Thread.tid, "OnStartPlaying")
	EndFunction

	Event OnStartPlaying(string asEventName, string asStringArg, float afNumArg, form akSender)
		UnregisterForModEvent("SSL_READY_Thread" + _Thread.tid)
		GoToState(STATE_PLAYING)
		TrackedEvent(TRACK_START)
		_StartedAt = SexLabUtil.GetCurrentGameRealTime()
		_LastOrgasm = _StartedAt
		_Thread.AnimationStart()
		If (_sex != 1 && _sex != 4)
			Utility.Wait(0.5)	; 勃起を確実にするための追加の非同期呼び出し
			Debug.SendAnimationEvent(_ActorRef, "SOSBend0")
		EndIf
		_HomoTypes = _Thread.CheckActiveHomoTypes()
		UpdateBaseEnjoymentCalculations()
	EndEvent

	Function SetStrapon(Form ToStrapon)
		SetStraponAnimationImpl(ToStrapon)
	EndFunction
	Function ResolveStrapon(bool force = false)
		ResolveStraponImpl()
	EndFunction
	Function RemoveStrapon()
		If(_Strapon && !_HadStrapon)
			_ActorRef.RemoveItem(_Strapon, 1, true)
		EndIf
	EndFunction

	Function UnlockActor()
		_ActorRef.SetAnimationVariableInt("IsNPC", _AnimVarIsNPC)
		_ActorRef.SetAnimationVariableBool("bHumanoidFootIKDisable", _AnimVarbHumanoidFootIKDisable)
		If (_ActorRef == _PlayerRef)
			SexLabUtil.ToggleFreeCamera(0) ;TFC_OFF
			_Config.ToggleVRIK(false)
		EndIf
		SetActorCollisions(true)
		_ActorRef.SetFactionRank(_AnimatingFaction, 0)
		_Thread.UpdateAnimatingActorMovement(_ActorRef) ;MOVEMENT_UNLOCK
		Log("Unlocked Actor: " + GetActorName())
		_ActorLocked = False
	EndFunction
	Function TryPauseAndUnlock()
		UnlockActor()
	EndFunction

	Function Clear()
		If (_sex <= 2)
			Redress()
			RemoveStrapon()
			_ActorRef.ClearExpressionOverride() ;_sexが2より大きい場合にエラー
		EndIf
		If (_ActorLocked)
			UnlockActor()
		EndIf
		If (sslLovense.IsLovenseInstalled())
			sslLovense.StopAllActions()
		EndIf
		_Thread.SetAnimationPlaybackSpeed(1.0)
		UnregisterForModEvent("SSL_ORGASM_Thread" + _Thread.tid)
		StoreExcitementState("Backup")
		sslBaseExpression.CloseMouth(_ActorRef)
		_ActorRef.ResetExpressionOverrides()
		sslBaseExpression.ClearMFG(_ActorRef)
		SendDefaultAnimEvent()
		TrackedEvent(TRACK_END)
		GoToState(STATE_IDLE)
		Clear()
	EndFunction
	Function Initialize()
		Clear()
		Initialize()
	EndFunction
EndState

bool Function InitiateUndressing()
	Error("Cannot undress actors outside of idle state", "InitiateUndressing()")
	return false
EndFunction
Function ReadyActor(int aiStripData, int aiPositionGenders)
	Error("Cannot ready outside of idle state", "ReadyActor()")
EndFunction
Event OnStartPlaying(string asEventName, string asStringArg, float afNumArg, form akSender)
	Error("Playing request outside of idle state", "OnStartPlaying()")
EndEvent
Function RemoveStrapon()
	Error("Removing strapon from invalid state", "RemoveStrapon()")
EndFunction

;	待機状態の場合はアクターをロック／ロック解除し、それ以外の場合は何もしない
Function LockActor()
	Error("Cannot lock actor outside of paused state", "LockActor()")
EndFunction
Function UnlockActor()
	Error("Cannot unlock actor outside of paused state", "UnlockActor()")
EndFunction
Function TryLockAndUnpause()
EndFunction
; これはSTATE_PLAYING中も機能する
Function TryPauseAndUnlock()
EndFunction

Function SetActorCollisions(bool abEnable) native

Form[] Function StripByData(int aiStripData, int[] aiDefaults, int[] aiOverwrites) native

; ------------------------------------------------------- ;
; --- Alias再生中                                     --- ;
; ------------------------------------------------------- ;
;/
	アニメーション中のアクターに対するメイン処理ループ
	この状態では装備状態、オーガズム、サウンドなどを処理する

	このセクションは2つの部分に分かれる:
	まず"paused"部分ではアクターが自由に歩き回れ、それ以上の処理は適用されない。
	Setup状態から最初に移行する状態であり、装備解除や位置固定などの指示を待つ
	次に"Playing"状態では、アクターがアニメーション中であるものとして、ボイス処理などが適用される
/;

float Property UPDATE_INTERVAL = 0.250 AutoReadOnly Hidden

float _LoopVoiceDelay
float _LoopExpressionDelay
float _LoopLovenseDelay
bool _LovenseGenital
bool _LovenseAnal

bool[] _CurrentInteractions
bool[] _HomoTypes

int _VRIKRestoreInTicks

State Animating
	Event OnBeginState()
		RegisterForModEvent("SSL_ORGASM_Thread" + _Thread.tid, "OnOrgasm")
		_LoopLovenseDelay = 0
		_LovenseGenital = false
		_LovenseAnal = false
		RegisterForSingleUpdate(UPDATE_INTERVAL)
	EndEvent

	Function UpdateNext(int aiStripData)
		If (_stripData != aiStripData)
			_stripData = aiStripData
			_equipment = StripByDataEx(_stripData, GetStripSettings(), _stripCstm, _equipment)
			_ActorRef.QueueNiNodeUpdate()
		EndIf
		_VoiceDelay -= Utility.RandomFloat(0.1, 0.3)
		if _VoiceDelay < 0.8
			_VoiceDelay = 0.8
		endIf
	EndFunction

	Function SetStrapon(Form ToStrapon)
		SetStraponAnimationImpl(ToStrapon)
	EndFunction
	Function ResolveStrapon(bool force = false)
		ResolveStraponImpl()
	EndFunction

	Event OnUpdate()
		If ((_Thread.GetStatus() != _Thread.STATUS_INSCENE) || (GetState() != STATE_PLAYING))
			return
		EndIf
		If (SexLabUtil.IsGamePausedOrFrozen())
			RegisterForSingleUpdate(UPDATE_INTERVAL)
			return
		EndIf
		_CurrentInteractions = _Thread.ListDetectedInteractionsInternal(_ActorRef)
		UpdateEffectiveEnjoymentCalculations()
		If (_bEnjEnabled && !_Thread.EnjoymentPaused && _Thread.ElementUI_EnjBars)
			EnjBarsUpdateSlider(_FullEnjoyment as float, _Thread.GetCurrentInteractionString(_ActorRef))
		EndIf
		int strength = CalcReaction()
		If (strength == 100)
			DoOrgasm()
		EndIf
		If (_LoopVoiceDelay >= _VoiceDelay && !IsSilent)
			_LoopVoiceDelay = 0.0
			bool lipsync = !OpenMouth && _Config.UseLipSync && _sex <= 2
			Sound snd = _Thread.GetAliasSound(Self, GetActorVoice(), strength)
			sslBaseVoice.PlaySound(_ActorRef, snd, strength, lipsync)
		EndIf
		If (_LoopExpressionDelay >= _ExpressionDelay)
			_LoopExpressionDelay = 0.0
			RefreshExpressionEx(strength)
		EndIf
		If (_LoopLovenseDelay <= 0)
			RefreshLovenseActions()
		Else
			_LoopLovenseDelay -= UPDATE_INTERVAL
		EndIf
		; VRIK（再検討: 常に必要か、オフセット変更時のみか？）（視点切り替えにどう影響するか？）
		If ((_ActorRef == _PlayerRef) && (_Config.POVModeVR == _Config.VRIK_FPP_FREE))
			_VRIKRestoreInTicks = _Config.UpdatePositioningVRIK(_VRIKRestoreInTicks)
			If (_VRIKRestoreInTicks < 0)
				_VRIKRestoreInTicks = 0
				_Config.RestoreHmdVRIK()
			EndIf
			If (_VRIKRestoreInTicks > 0)
				_VRIKRestoreInTicks -= 1
				If _VRIKRestoreInTicks <= 1
					_VRIKRestoreInTicks = -1
				EndIf
			EndIf
		EndIf
		; ループ
		_LoopVoiceDelay += UPDATE_INTERVAL
		_LoopExpressionDelay += UPDATE_INTERVAL
		_LoopEnjoymentDelay += UPDATE_INTERVAL
		RegisterForSingleUpdate(UPDATE_INTERVAL)
	EndEvent

	Function TryRefreshExpression()
		RefreshExpression()
	EndFunction
	Function RefreshExpressionEx(float afStrength)
		If (_sex > 2)
			return
		ElseIf (sslBaseExpression.IsMouthOpen(_ActorRef))
			If (!OpenMouth)
				sslBaseExpression.CloseMouth(_ActorRef)
			EndIf
		ElseIf (OpenMouth)
			sslBaseExpression.OpenMouth(_ActorRef)
			Utility.Wait(0.7)
		EndIf
		String expression = GetActorExpression()
		If (expression && _Config.UseExpressions && _livestatus == LIVESTATUS_ALIVE)
			sslBaseExpression.ApplyExpression(expression, _ActorRef, afStrength)
		EndIf
		If (_Config.DebugMode)
			Log("Expression? " + expression + "; Strength? " + afStrength + "; OpenMouth? " + OpenMouth, "sslBaseExpression.ApplyExpression()")
		EndIf
	EndFunction

	Function RefreshLovenseActions()
		If ((_ActorRef != _PlayerRef) || (!sslLovense.IsLovenseInstalled()))
			return
		EndIf
		int lovenseStrength = sslSystemConfig.GetSettingInt("iLovenseStrength")
		bool LovenseGenital = IsGenitalInteraction()
		bool LovenseAnal = IsAnalPenetrated()
		If (!LovenseGenital && !LovenseAnal && (_LovenseGenital || _LovenseAnal))
			sslLovense.StopAllActions()
		Else
			If (LovenseGenital)
				If (!_LovenseGenital)
					sslLovense.StartGenitalAction(lovenseStrength)
				EndIf
			ElseIf (_LovenseGenital)
				sslLovense.StopGenitalAction(!LovenseAnal)
			EndIf
			If (LovenseAnal)
				If (!_LovenseAnal)
					sslLovense.StartAnalAction(lovenseStrength)
				EndIf
			ElseIf (_LovenseAnal)
				sslLovense.StopAnalAction(!LovenseGenital)
			EndIf
		EndIf
		_LovenseGenital = LovenseGenital
		_LovenseAnal = LovenseAnal
	EndFunction

	Function PlayLouder(Sound SFX, ObjectReference FromRef, float Volume)
		Sound.SetInstanceVolume(SFX.Play(FromRef), Volume)
	EndFunction

	Event OnOrgasm(string eventName, string strArg, float numArg, Form sender)
		If (numArg > 0.0)
			; ステージによる絶頂（レガシーの絶頂タイプ）: 快感に基づく絶頂のクールダウンに
			; 抑制されてはならないが、DisableOrgasm()の設定には従う
			If (_CanOrgasm)
				DoOrgasm(true)
			EndIf
		Else
			DoOrgasm()
		EndIf
	EndEvent
	Function DoOrgasm(bool Forced = false)
		If (_hasOrgasm)
			return
		EndIf
		_hasOrgasm = true
		If (!Forced)
			If (!_CanOrgasm)
				_hasOrgasm = false
				return
			EndIf
			float time = SexLabUtil.GetCurrentGameRealTime()
			int cmp = 10
			If (_sex == 0 || _sex == 3)
				cmp = 20
			EndIf
			If (time - _LastOrgasm < cmp)
				_hasOrgasm = false
				return
			EndIf
		EndIf
		UnregisterForUpdate()
		_OrgasmCount += 1
		; 効果音
		If(_Config.OrgasmEffects)
			If (_ActorRef == _PlayerRef)
				If (_Config.HasVRIK)
					_Config.DoWhiteOutEfffect(_OrgasmCount)
				ElseIf (_Config.ShakeStrength > 0 && Game.GetCameraState() >= 8)
					Game.ShakeCamera(none, _Config.ShakeStrength, _Config.ShakeStrength + 1.0)
				EndIf
			EndIf
			If (!IsSilent)
				Sound snd = _Thread.GetAliasOrgasmSound(Self, GetActorVoice())
				PlayLouder(snd, _ActorRef, _Config.VoiceVolume)
			EndIf
			PlayLouder(_Config.OrgasmFX, _ActorRef, _Config.SFXVolume)
			If (sslLovense.IsLovenseInstalled())
				_LoopLovenseDelay = sslSystemConfig.GetSettingFlt("fLovenseDurationOrgasm")
				int strength = sslSystemConfig.GetSettingInt("iLovenseStrengthOrgasm")
				float duration = sslSystemConfig.GetSettingInt("fLovenseDurationOrgasm")
				sslLovense.StartOrgasmAction(strength, duration)
			EndIf
		EndIf
		If (_sex != 1 && _sex != 4)
			_Thread.ApplyCumFX(_ActorRef)
		EndIf
		; イベント
		int eid = ModEvent.Create("SexLabOrgasm")
		ModEvent.PushForm(eid, _ActorRef)
		ModEvent.PushInt(eid, _FullEnjoyment)
		ModEvent.PushInt(eid, _OrgasmCount)
		ModEvent.Send(eid)
		Int handle = ModEvent.Create("SexlabOrgasmSeparate")
		ModEvent.PushForm(handle, _ActorRef)
		ModEvent.PushInt(handle, _Thread.tid)
		ModEvent.Send(handle)
		TrackedEvent(TRACK_ORGASM)
		_LastOrgasm = SexLabUtil.GetCurrentGameRealTime()
		; 快感
		If (_bEnjEnabled)
			_FullEnjoyment = 0
			_arousalBase = 0
			SexlabStatistics.SetStatistic(_ActorRef, 17, _arousalBase)
			_EnjFactor = _BaseFactor
			If (_sex == 0 || _sex == 3)
				If (_OrgasmCount > _Config.MaxNoPainOrgasmMale)
					_FullEnjoyment -= (_OrgasmCount - _Config.MaxNoPainOrgasmMale) * 20
				EndIf
				_Thread.EnjBasedSkipToLastStage(_Config.MaleOrgasmEndsScene)
			Else
				If (_OrgasmCount > _Config.MaxNoPainOrgasmFemale)
					_FullEnjoyment -= (_OrgasmCount - _Config.MaxNoPainOrgasmFemale) * 20
				EndIf
			EndIf
			; 追加の絶頂ペナルティは累積するが、-100未満にならないようにする。
			_FullEnjoyment = PapyrusUtil.ClampInt(_FullEnjoyment, -100, 100)
			UpdateEffectiveEnjoymentCalculations()
		EndIf
		RegisterForSingleUpdate(UPDATE_INTERVAL)
		_hasOrgasm = false
		Log(GetActorName() + ": Orgasms[" + _OrgasmCount + "] FullEnjoyment [" + _FullEnjoyment + "]")
	EndFunction
	
	Function ResetPosition(int aiStripData, int aiPositionGenders)
		_stripData = aiStripData
		_equipment = StripByDataEx(_stripData, GetStripSettings(), _stripCstm, _equipment)
		_useStrapon = _sex == 1 && Math.LogicalAnd(aiPositionGenders, 0x2) == 0
		ResolveStrapon()
		_ActorRef.QueueNiNodeUpdate()
	EndFunction

	Function TryPauseAndUnlock()
		GoToState(STATE_PAUSED)
		UnlockActor()
	EndFunction

	Function Clear()
		GoToState(STATE_PAUSED)
		Clear()
	EndFunction
	Function Initialize()
		Clear()
		Initialize()
	EndFunction

	Event OnEndState()
		UnregisterForUpdate()
		SendDefaultAnimEvent()
	EndEvent
EndState

Function UpdateNext(int aiStripData)
	Error("Cannot update to next stage outside of playing state", "UpdateNext()")
EndFunction
Function ResetPosition(int aiStripData, int aiPositionGenders)
	Error("Cannot reset position outside of playing state", "ResetPosition()")
EndFunction
function RefreshExpression()
	int strength = CalcReaction()
	RefreshExpressionEx(strength)
endFunction
Function RefreshExpressionEx(float afStrength)
	Error("Cannot refresh expression outside of playing state", "RefreshExpressionEx()")
EndFunction
Function RefreshLovenseActions()
	Error("Cannot process lovense actions outside of playing state", "RefreshLovenseActions()")
EndFunction

function DoOrgasm(bool Forced = false)
	Error("Cannot create an orgasm outside of playing state", "DoOrgasm()")
endFunction
Function PlayLouder(Sound SFX, ObjectReference FromRef, float Volume)
	Error("Cannot play sound outside of playing state", "PlayLouder()")
EndFunction
Event OnOrgasm(string eventName, string strArg, float numArg, Form sender)
	Error("Cannot create orgasm effects outside of playing state", "OnOrgasm()")
EndEvent

Function TryRefreshExpression()
EndFunction

Form[] Function StripByDataEx(int aiStripData, int[] aiDefaults, int[] aiOverwrites, Form[] akMergeWith) native

; ------------------------------------------------------- ;
; --- 状態に依存しない処理                            --- ;
; ------------------------------------------------------- ;
;/
	アニメーション中のアクターに対するメイン処理ループ
	この状態では装備状態、オーガズム、サウンドなどを処理する
/;

Function SendDefaultAnimEvent(bool Exit = False)
	Debug.SendAnimationEvent(_ActorRef, "AnimObjectUnequip")
	Debug.SendAnimationEvent(_ActorRef, "IdleForceDefaultState")
	If(_sex <= 2)
		return
	EndIf
	Debug.SendAnimationEvent(_ActorRef, "ReturnDefaultState")		; "ReturnToDefault"前のニワトリ、野ウサギ、スローターフィッシュ
	Debug.SendAnimationEvent(_ActorRef, "ReturnToDefault")			; 休止状態のクリーチャー／動物
	Debug.SendAnimationEvent(_ActorRef, "FNISDefault")				; ドワーフスパイダーとシャウラス
	Debug.SendAnimationEvent(_ActorRef, "IdleReturnToDefault")		; ウェアウルフと吸血鬼の王
	Debug.SendAnimationEvent(_ActorRef, "ForceFurnExit")			; "ReturnToDefault"後のトロール、ドラウグル、デイドラ、スパイダー以外のドワーフ
	Debug.SendAnimationEvent(_ActorRef, "Reset")					; "ReturnToDefault"後のハグレイヴンとドラゴン
EndFunction

function TrackedEvent(string EventName)
	sslThreadLibrary.SendTrackingEvents(_ActorRef, EventName, _Thread.tid)
endFunction

Function ResolveStrapon(bool force = false)
	Error("Called from invalid state", "ResolveStrapon()")
EndFunction
Function SetStraponAnimationImpl(Form akNewStrapon)
	If (_Strapon == akNewStrapon)
		return
	ElseIf (_Strapon && !_HadStrapon)
		_ActorRef.RemoveItem(_Strapon, 1, true)
	EndIf
	_Strapon = akNewStrapon
	ResolveStrapon()
EndFunction
Function ResolveStraponImpl()
	If (!_Strapon)
		return
	EndIf
	bool equipped = _ActorRef.IsEquipped(_Strapon)
	If(!equipped && _useStrapon)
		_ActorRef.EquipItem(_Strapon, true, true)
	ElseIf(equipped && !_useStrapon)
		_ActorRef.UnequipItem(_Strapon, true, true)
	EndIf
EndFunction

int[] Function GetStripSettings()
	If (_Thread.IsConsent())
		return sslSystemConfig.GetStripForms(_sex == 1 || _sex == 2, false)
	Else
		return sslSystemConfig.GetStripForms(IsVictim(), true)
	EndIf
EndFunction

Function Redress()
	If (!DoRedress)
		return
	EndIf
	; _equipment := [HighHeelSpell, WeaponRight, WeaponLeft, Armor...]
	If(_equipment[1])
		_ActorRef.EquipItemEx(_equipment[1], _ActorRef.EquipSlot_RightHand, equipSound = false)
	EndIf
	If(_equipment[2])
		_ActorRef.EquipItemEx(_equipment[2], _ActorRef.EquipSlot_LeftHand, equipSound = false)
	EndIf
	int i = 3
	While (i < _equipment.Length)
		_ActorRef.EquipItemEx(_equipment[i], _ActorRef.EquipSlot_Default, equipSound = false)
		i += 1
	EndWhile
	Spell HDTHeelSpell = _equipment[0] as Spell
	If(HDTHeelSpell && _ActorRef.GetWornForm(0x00000080) && !_ActorRef.HasSpell(HDTHeelSpell))
		_ActorRef.AddSpell(HDTHeelSpell, false)
	EndIf
EndFunction

; ------------------------------------------------------- ;
; --- 初期化                                          --- ;
; ------------------------------------------------------- ;
;/
	再初期化／初期化用の関数
/;

; 所有元Threadの初期化／再初期化時のみ呼び出される
Function Setup()
	Form SexLabQuestFramework = Game.GetFormFromFile(0xD62, "SexLab.esm")
	_Config = SexLabQuestFramework as sslSystemConfig

	_Thread = GetOwningQuest() as sslThreadModel
	_AnimatingFaction = _Config.AnimatingFaction
	_PlayerRef = Game.GetPlayer()

	Initialize()
EndFunction

; InitializeはAliasをクリアし、すべてのデータをリセットする
Function Initialize()
	UnregisterForAllModEvents()
	TryToClear()
	; Form
	_ActorRef = none
	_HadStrapon = none
	_Strapon = none
	; 音声
	_IsForcedSilent = false
	; フラグ
	_victim = false
	_CanOrgasm = true
	_hasOrgasm = false
	_DoUndress = true
	_AllowRedress = true
	ForceOpenMouth = false
	_ActorLocked = false
	; 整数
	_sex = -1
	_raceID = -1
	_livestatus = 0
	_PathingFlag = 0
	_OrgasmCount = 0
	_stripCstm = new int[1]
	; 浮動小数点数
	_LastOrgasm = 0.0
	_StartedAt = 0.0
	; 配列
	_CurrentInteractions = Utility.CreateBoolArray(_Thread.SUPPORTED_INTER_COUNT, false)
	_HomoTypes = Utility.CreateBoolArray(5, false)
	ResetEnjoymentVariables()
	_VRIKRestoreInTicks = 0
EndFunction

Event OnRequestClear(string asEventName, string asStringArg, float afDoStatistics, form akSender)
	Clear()
EndEvent

; ------------------------------------------------------- ;
; --- 中断イベント                                    --- ;
; ------------------------------------------------------- ;
;/
	発生すると基盤となるアニメーションを停止するイベント
/;

Event OnCellDetach()
	Log("An Alias is out of range and cannot be animated anymore. Stopping Thread...")
	_Thread.EndAnimation()
EndEvent
Event OnUnload()
	Log("An Alias is out of range and cannot be animated anymore. Stopping Thread...")
	_Thread.EndAnimation()
EndEvent
Event OnDying(Actor akKiller)
	Log("An Alias is dying and cannot be animated anymore. Stopping Thread...")
	_Thread.EndAnimation()
EndEvent

; ------------------------------------------------------- ;
; --- ログ                                            --- ;
; ------------------------------------------------------- ;
;/
	汎用ログユーティリティ
/;

function Log(string msg, string src = "")
	msg = "Thread[" + _Thread.tid + "] ActorAlias[" + GetActorName() + "] State [" + GetState() + "] " + msg
	sslLog.Log(msg)
endFunction

Function Error(String msg, string src = "")
	msg = "Thread[" + _Thread.tid + "] ActorAlias[" + GetActorName() + "] State [" + GetState() + "] " + msg
	sslLog.Error(msg)
EndFunction

; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;
; --------------------------------------------------------------------------------------- ;
;  ███████╗███╗   ██╗     ██╗ ██████╗ ██╗   ██╗███╗     ╔███╗███████╗███╗   ██╗████████╗  ;
;  ██╔════╝████╗  ██║     ██║██╔═══██╗╚██╗ ██╔╝████╗   ╔████║██╔════╝████╗  ██║╚══██╔══╝  ;
;  █████╗  ██╔██╗ ██║     ██║██║   ██║ ╚████╔╝ ██╔██╗ ╔██╔██║█████╗  ██╔██╗ ██║   ██║     ;
;  ██╔══╝  ██║╚██╗██║██   ██║██║   ██║  ╚██╔╝  ██║╚██ ██╔╝██║██╔══╝  ██║╚██╗██║   ██║     ;
;  ███████╗██║ ╚████║╚█████╔╝╚██████╔╝   ██║   ██║ ╚███╔╝ ██║███████╗██║ ╚████║   ██║     ;
;  ╚══════╝╚═╝  ╚═══╝ ╚════╝  ╚═════╝    ╚═╝   ╚═╝  ╚══╝  ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝     ;
; --------------------------------------------------------------------------------------- ;
; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;
; 再検討: C++インスタンスに移した方がよい可能性がある。快感処理の完了時に対応したい。

Function EnjBarsUpdateSlider(float afEnjoyment, string asInteractions) native
Function RegisterRaiseEnjAttempt(float afNextTimeCycle) native

; 既定値
float _EnjoymentDelay
float _LoopEnjoymentDelay
; 基本値
bool _bEnjEnabled
bool _CrtMaleHugePP
int _ConSubStatus
float _PainContext
float _EnjFactor
float _BaseFactor
float _arousalBase
; インタラクション
float _InterFactor
; 有効値
float _ModEnjMult
float _arousalStat
float _PainInterTimer
float _PainInterBackup
float _PainInterDecayBackup
float _PainInterCur
int _FullEnjoyment

Function ResetEnjoymentVariables()
	; 既定値
	_EnjoymentDelay = 0.8
	_LoopEnjoymentDelay = 0.0
	; 基本値
	_bEnjEnabled = False
	_CrtMaleHugePP = False
	_ConSubStatus = _Thread.CONSENT_CONNONSUB
	_PainContext = 0.0
	_EnjFactor = 0.0
	_BaseFactor = 0.0
	_arousalBase = 0.0
	; インタラクション
	_InterFactor = 0.0
	; 有効値
	_ModEnjMult = 1.0
	_arousalStat = 0.0
	_PainInterTimer = 0.0
	_PainInterBackup = 0.0
	_PainInterDecayBackup = 0.0
	_PainInterCur = 0.0
	_FullEnjoyment = 0
EndFunction

Function UpdateBaseEnjoymentCalculations()
	If (!_Config.InternalEnjoymentEnabled || !_Config.SeparateOrgasms || GetIsDead() || !_Thread.HasPlayer)
		return
	EndIf
	ResetEnjoymentVariables()
	_bEnjEnabled = True
	StoreExcitementState("Restore")
	_CrtMaleHugePP = _Thread.CrtMaleHugePP()
	_ConSubStatus = _Thread.IdentifyConsentSubStatus()
	bool SameSexThread = (_HomoTypes[1] || _HomoTypes[2] || _HomoTypes[3])
	bool WithLover  = _Thread.ActorIsWithLover(_ActorRef)
	_arousalBase = PapyrusUtil.ClampFloat(SexlabStatistics.GetStatistic(_ActorRef, 17), 0.0, 100.0)
	_PainContext = CalcContextPain()
	_EnjFactor = CalcContextEnjFactor(SameSexThread, WithLover)
	_BaseFactor = _EnjFactor
	If (_Config.DebugMode)
		DebugBaseCalcVariables()
	EndIf
EndFunction

Function UpdateEffectiveEnjoymentCalculations()
	If (!_bEnjEnabled)
		return
	EndIf
	If (_FullEnjoyment >= 100)
		_FullEnjoyment = 100
		DoOrgasm()
		return
	EndIf
	If ((_Thread.EnjoymentPaused) || (_LoopEnjoymentDelay < _EnjoymentDelay))
		return
	EndIf
	bool NoStaminaEndScenario = (_Config.NoStaminaEndsScene && !_victim && _ActorRef.GetActorValuePercentage("Stamina") < 0.10)
	If (NoStaminaEndScenario)
		_Thread.EnjBasedSkipToLastStage(true)
		return
	EndIf
	_LoopEnjoymentDelay = 0.0
	_InterFactor = _Thread.CalculateInteractionFactor(_ActorRef, _CurrentInteractions)
	; 1回の更新で範囲の端を超える場合があるため、他で使用する前にクランプする。
	_FullEnjoyment = PapyrusUtil.ClampInt(CalcEffectiveEnjoyment() as int, -100, 100)
	UpdateArousalStat()
	If (_Config.DebugMode)
		DebugEffectiveCalcVariables()
	EndIf
EndFunction

float Function CalcContextPain()
	float PainContext = 0.0
	bool SubsPresent = _Thread.GetSubmissives().Length
	If (!SubsPresent || (SubsPresent && !_victim))
		return 0
	ElseIf (_Thread.HasSceneTag("Humiliation"))
		return 25
	ElseIf (_Thread.HasSceneTag("Forced"))
		return 35
	ElseIf (_Thread.HasSceneTag("Ryona"))
		return 45
	EndIf
	If (_Thread.HasSceneTag("Spanking"))
		PainContext += 5
	EndIf
	If (_Thread.HasSceneTag("Dominant"))
		PainContext += 10
	EndIf
	If (_Thread.HasSceneTag("Asphyxiation"))
		PainContext += 15
	EndIf
	return PainContext
EndFunction

float Function CalcContextEnjFactor(bool SameSexThread, bool WithLover)
	float EnjMult = 1.0
	; 興奮
	EnjMult += (_arousalBase / 50)
	; クリーチャー
	if (_raceID > 0)
		return (EnjMult + 0.5)
	EndIf
	; 関係性
	If WithLover
		EnjMult += 1.0
	EndIf
	; 性的嗜好
	int actorSexuality = SexlabStatistics.GetSexuality(_ActorRef)
	If (actorSexuality == 0 && SameSexThread) || (actorSexuality == 1 && !SameSexThread)
		EnjMult -= 0.5
	EndIf
	; コンテキスト
	If _ConSubStatus > _Thread.CONSENT_NONCONNONSUB
		If _victim
			EnjMult -= 0.35
		ElseIf !_victim
			EnjMult += 0.30
		EndIf
	EndIf
	return EnjMult
EndFunction

float Function CalcInteractionPain()
	float vaginalXP = SexlabStatistics.GetStatistic(_ActorRef, 2)
	float analXP = SexlabStatistics.GetStatistic(_ActorRef, 3)
	bool PainCondVaginal = _CurrentInteractions[_Thread.pVaginal] && (vaginalXP < _Config.NoPainRequiredXP as float)
	bool PainCondAnal = _CurrentInteractions[_Thread.pAnal] && (analXP < _Config.NoPainRequiredXP as float)
	float PainInter = 0.0
	If (PainCondVaginal || PainCondAnal)
		_PainInterTimer += _EnjoymentDelay
		float PainFactor = (2 - (0.01 * (analXP + vaginalXP)))
		PainFactor = PapyrusUtil.ClampFloat(PainFactor, 0, 2)
		If (_CrtMaleHugePP)
			PainFactor += _Config.PainHugePPMult
		EndIf
		PainInter = (PainFactor * _InterFactor * _Config.EnjRaiseMultInter)
	EndIf
	return PainInter
EndFunction

float Function CalcEffectivePain()
	float NoPainTime = _Config.NoPainRequiredTime as float
	float SceneDuration = _Thread.GetTimeTotal()
	float DecayMult = 0.0
	float _PainContextCur = 0.0
	_PainInterCur = 0
	If (NoPainTime < 1)
		NoPainTime = 1
	EndIF
	; コンテキストによる痛み
	If (SceneDuration < NoPainTime)
		DecayMult = 1.0 - (SceneDuration / NoPainTime)
		DecayMult = PapyrusUtil.ClampFloat(DecayMult, 0, 1)
		_PainContextCur = _PainContext * DecayMult
	EndIf
	; インタラクションによる痛み
	If (_PainInterTimer < NoPainTime)
		float tmp_pain = (CalcInteractionPain() * 5)
		If (tmp_pain || _PainInterBackup)
			float decay_cur = tmp_pain * (_PainInterTimer / NoPainTime)
			float decay_incr = decay_cur - _PainInterDecayBackup
			float cur_pain = tmp_pain - decay_incr
			_PainInterCur = cur_pain - _PainInterBackup 
			_PainInterBackup = cur_pain
			_PainInterDecayBackup = decay_cur
		EndIf
	EndIf
	return (_PainContextCur + _PainInterCur)
EndFunction

float Function CalcEffectiveEnjoyment()
	; ConSubMult [既定: 0.8～1.2]、EnjRaiseMultInter [既定: 0.8]、EnjFactor [範囲: 0.17～4.3]
	float ConSubMult = EnjFindConSubStatusMult()
	float EffectivePain = CalcEffectivePain()
	If ((_PainInterCur > 10) || (_Config.GameRequiredOnHighEnj && (_FullEnjoyment > 80) && (_ActorRef == _PlayerRef)))
		return (_FullEnjoyment - EffectivePain)
	EndIf
	float EnjInter = (_EnjFactor * _InterFactor * _Config.EnjRaiseMultInter * ConSubMult * _ModEnjMult)
	return (_FullEnjoyment + EnjInter - EffectivePain)
EndFunction

Function UpdateArousalStat()
	_arousalStat = _arousalBase + (_FullEnjoyment as float / 2)
	SexlabStatistics.SetStatistic(_ActorRef, 17, _arousalStat)
EndFunction

float Function EnjFindConSubStatusMult()
	float ret = 1.0
	If _ConSubStatus == _Thread.CONSENT_NONCONSUB
		If _victim
			ret = _Config.EnjMultVictim
		Else
			ret = _Config.EnjMultAggressor
		EndIf
	ElseIf _ConSubStatus == _Thread.CONSENT_CONSUB
		If _victim
			ret = _Config.EnjMultSub
		Else
			ret = _Config.EnjMultDom
		EndIf
	EndIf
	return ret
EndFunction

int function CalcReaction()
	If (_bEnjEnabled)
		int ret = Math.Abs(_FullEnjoyment) as int
		return PapyrusUtil.ClampInt(ret, 0, 100)
	EndIf
	return 50
EndFunction

bool Function WaitForOrgasm()
	If (!_bEnjEnabled)
		return False
	EndIf
	bool EnjScenario = (_Config.HighEnjOrgasmWait && (_FullEnjoyment > 80))
	bool PlayerSceanrio = (_Config.PlayerMustOrgasm && (_ActorRef == _PlayerRef) && _OrgasmCount == 0)
	bool DomScenario = (_Config.DomMustOrgasm && !_victim && _OrgasmCount == 0 && \
	(_ConSubStatus == _Thread.CONSENT_CONSUB || _ConSubStatus == _Thread.CONSENT_NONCONSUB))
	If (EnjScenario || DomScenario || PlayerSceanrio)
		return True
	EndIf
	return False
EndFunction

Function StoreExcitementState(String arg = "")
	string ActorName = GetActorName()
	If (arg == "Backup")
		StorageUtil.SetFloatValue(None, ("EnjBackupTime_" + ActorName),  SexLabUtil.GetCurrentGameRealTime())
		StorageUtil.SetIntValue(None, ("LastOrgasmCount_" + ActorName), _OrgasmCount)
		If _FullEnjoyment > 10
			StorageUtil.SetIntValue(None, ("LastEnjoyment_" + ActorName), _FullEnjoyment)
		EndIf
	ElseIf (arg == "Restore")
		float TimeSinceEnjBackup = (SexLabUtil.GetCurrentGameRealTime() - StorageUtil.GetFloatValue(None, ("EnjBackupTime_" + ActorName)))
		If (TimeSinceEnjBackup < 60)
			_OrgasmCount = StorageUtil.GetIntValue(None, ("LastOrgasmCount_" + ActorName))
			int LastEnjoyment = StorageUtil.GetIntValue(None, ("LastEnjoyment_" + ActorName))
			; 保存された快感値を減衰させてから、通常の範囲内に収める。
			_FullEnjoyment = PapyrusUtil.ClampInt((LastEnjoyment as float * (1 - (TimeSinceEnjBackup/60))) as int, -100, 100)
		EndIf
	EndIf
EndFunction

Function InitRaiseEnjAttempt()
	If (_ActorRef != _PlayerRef)
		return
	EndIf
	If (_FullEnjoyment >= 100)
		_FullEnjoyment = 100
		DoOrgasm()
		return
	EndIf
	; 快感値が高くなるほど「グリーンゾーン」は狭くなる
	; Enjが80（nextTimeCycleは2.0秒）の場合: 範囲はバーの25%（0.375～0.625）
	; Enjが100（nextTimeCycleは0.8秒）の場合: 範囲はバーの15%（0.425～0.575）
	float nextTimeCycle = 6.8 - (_FullEnjoyment * 0.06)
	RegisterRaiseEnjAttempt(nextTimeCycle)
EndFunction

Function OnRaiseEnjAttemptResult(bool abSuccess)
	; 被弾や連打ペナルティでは一度に数ポイント変動するため、範囲の端を超えないようにする。
	If (abSuccess)
		_FullEnjoyment = PapyrusUtil.ClampInt(_FullEnjoyment + _Config.GameEnjAdjAmount * 2, -100, 100)
		_PlayerRef.RestoreActorValue("Stamina", _Config.GameStaminaCost)
		_PlayerRef.RestoreActorValue("Magicka", _Config.GameMagickaCost)
		If (_FullEnjoyment == 100)
			DoOrgasm()
		EndIf
	ElseIf (_Config.GameSpamDelayPenalty)
		If (_EnjFactor > 0)
			_FullEnjoyment = PapyrusUtil.ClampInt(_FullEnjoyment - _Config.GameEnjAdjAmount * 2, -100, 100)
			_EnjFactor -= 0.04
		Else ; タイミングの悪い試行が多すぎる場合のペナルティ
			_FullEnjoyment = PapyrusUtil.ClampInt(_FullEnjoyment - 50, -100, 100)
			_EnjFactor = (_BaseFactor / 2)
		EndIf
		If (!SexLabUtil.IsGodModeEnabled())
			_PlayerRef.DamageActorValue("Stamina", 2 * _Config.GameStaminaCost)
			_PlayerRef.DamageActorValue("Magicka", 2 * _Config.GameMagickaCost)
		EndIf
	EndIf
EndFunction

Function DebugBaseCalcVariables()
	string BaseCalcLog = "[ENJ] EnjFactor: " + _EnjFactor + ", BaseArousal: " + _arousalBase + ", SameSexThread: " \
	+ (_HomoTypes[2]||_HomoTypes[3]||_HomoTypes[4]) + ", Sexuality: " + SexlabStatistics.GetSexuality(_ActorRef) + ", ConSubStatus: " \
	+ _ConSubStatus + ", IsVictim: " + _victim + ", HugePP: " + _CrtMaleHugePP + ", ContextPain: " + _PainContext as int
	Log(BaseCalcLog)
EndFunction

Function DebugEffectiveCalcVariables()
	string EffectiveCalcLog = "[ENJ] Enjoyment: " + _FullEnjoyment + ", IntFactor: " \
	+ _InterFactor + ", EnjFactor: " + _EnjFactor + ", PainInterCur: " + _PainInterCur
	Log(EffectiveCalcLog)
EndFunction

; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;
; ----------------------------------------------------------------------------- ;
;				██╗     ███████╗ ██████╗  █████╗  ██████╗██╗   ██╗				;
;				██║     ██╔════╝██╔════╝ ██╔══██╗██╔════╝╚██╗ ██╔╝				;
;				██║     █████╗  ██║  ███╗███████║██║      ╚████╔╝ 				;
;				██║     ██╔══╝  ██║   ██║██╔══██║██║       ╚██╔╝  				;
;				███████╗███████╗╚██████╔╝██║  ██║╚██████╗   ██║   				;
;				╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝   ╚═╝   				;
; ----------------------------------------------------------------------------- ;
; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;

function OffsetCoords(float[] Output, float[] CenterCoords, float[] OffsetBy) global
	If (OffsetBy.Length != 4 && CenterCoords.Length != 6 && Output.Length != 6)
		return
	EndIf
	float pi = 2.0 * Math.asin(1.0)
	float x2 = CenterCoords[0]
	float y2 = CenterCoords[1]

	float argX = CenterCoords[5] * pi / 180
	x2 += Math.sin(argX) * OffsetBy[0]
	y2 += Math.cos(argX) * OffsetBy[0]
	If (OffsetBy[1] != 0) 
		float argY = CenterCoords[5] + 90
		argY = argY * pi / 180
		x2 += Math.sin(argY) * OffsetBy[1]
		y2 += Math.cos(argY) * OffsetBy[1]
	EndIf
	
	Output[0] = x2
	Output[1] = y2
	Output[2] = CenterCoords[2] + OffsetBy[2]
	Output[3] = CenterCoords[3]
	Output[4] = CenterCoords[4]
	Output[5] = CenterCoords[5] + OffsetBy[3]
EndFunction
bool function IsInPosition(Actor CheckActor, ObjectReference CheckMarker, float maxdistance = 30.0) global
	return CheckActor.GetDistance(CheckMarker) < maxdistance
EndFunction
int function CalcEnjoyment(float[] XP, float[] SkillsAmounts, bool IsLeadin, bool IsFemaleActor, float Timer, int OnStage, int MaxStage) global
	return 0
EndFunction

int Property Position
	int Function Get()
		return _Thread.Positions.Find(_ActorRef)
	EndFunction
EndProperty

bool property UseStrapon hidden
	bool function get()
		return _useStrapon
	endFunction
endProperty

bool _DoRagdoll
bool property DoRagdoll hidden
	bool function get()
		return !_DoRagdoll ; && _Config.RagdollEnd
	endFunction
	function set(bool value)
		_DoRagdoll = !value
	endFunction
endProperty

int property Schlong hidden
	int function get()
		return 0
	endFunction
endProperty

bool property MalePosition hidden
	bool function get()
		return _Thread.Animation.GetGender(Position) == 0
	endFunction
endProperty

sslBaseExpression function GetExpression()
	return _Config.ExpressionSlots.GetByRegistrar(GetActorExpression())
endFunction
Function SetExpression(sslBaseExpression ToExpression)
	SetActorExpression(ToExpression.Registry)
EndFunction

sslBaseVoice function GetVoice()
	return _Config.VoiceSlots.GetByRegistrar(GetActorVoice())
endFunction
Function SetVoice(sslBaseVoice ToVoice = none, bool ForceSilence = false)
	If (ToVoice)
		SetActorVoice(ToVoice.Registry, ForceSilence)
	Else
		SetActorVoice("", ForceSilence)
	EndIf
EndFunction

int function GetGender()
	int ret = SexLabRegistry.GetSex(_ActorRef, false)
	If (ret >= 2)
		ret -= 1
	EndIf
	return ret
endFunction

function DisablePathToCenter(bool disabling)
	If (disabling)
		_PathingFlag = PATHING_DISABLE
	ElseIf (_PathingFlag == PATHING_DISABLE)
		_PathingFlag = PATHING_ENABLE
	EndIf
endFunction

function ForcePathToCenter(bool forced)
	If (forced)
		_PathingFlag = PATHING_FORCE
	Else
		_PathingFlag = PATHING_ENABLE
	EndIf
endFunction

function AttachMarker()
endFunction
function SyncThread()
endFunction

function OverrideStrip(bool[] SetStrip)
	if SetStrip.Length != 33
		_Thread.Log("Invalid strip override bool[] - Must be length 33 - was "+SetStrip.Length, "OverrideStrip()")
		return
	endif
	_stripCstm = new int[2]
	int i = 0
	int ii = 0
	While(i < 32)
		If(SetStrip[i])
			ii += Math.LeftShift(1, i)
		EndIF
		i += 1
	EndWhile
	_stripCstm[0] = ii
	_stripCstm[1] = SetStrip[32] as int
endFunction

Function Strip()
	_equipment = StripByDataEx(0x80, GetStripSettings(), _stripCstm, _equipment)
	_ActorRef.QueueNiNodeUpdate()
EndFunction
Function UnStrip()
	Redress()
EndFunction

function SetEndAnimationEvent(string EventName)
endFunction
function SetStartAnimationEvent(string EventName, float PlayTime)
endFunction

int function GetPain()
	if (_FullEnjoyment < 0)
		return Math.Abs(_FullEnjoyment) as int
	endIf
	return 0	
endFunction

; SLSOベースのModとの互換性のため
int function GetFullEnjoyment()
	return _FullEnjoyment
endFunction
function BonusEnjoyment(Actor akActor = none, int AdjustBy = 0)
	return _Thread.AdjustEnjoyment(akActor, AdjustBy)
endFunction

function OrgasmEffect()
	DoOrgasm()
endFunction
event OrgasmStage()
	DoOrgasm()
endEvent
bool function NeedsOrgasm()
	return _FullEnjoyment >= 100
endFunction
function SetOrgasmCount(int value)
	; 内部の快感値に干渉するため、不要と判断！
EndFunction

function RegisterEvents()
endFunction
function ClearEvents()
endFunction

function EquipStrapon()
	; if _Strapon && !_ActorRef.IsEquipped(_Strapon)
	; 	_ActorRef.EquipItem(_Strapon, true, true)
	; endIf
endFunction
function UnequipStrapon()
	; if _Strapon && _ActorRef.IsEquipped(_Strapon)
	; 	_ActorRef.UnequipItem(_Strapon, true, true)
	; endIf
endFunction

function RefreshLoc()
	_Thread.RealignActors()
endFunction
function SyncLocation(bool Force = false)
	_Thread.RealignActors()
endFunction
function Snap()
	_Thread.RealignActors()
endFunction

function SetAdjustKey(string KeyVar)
endfunction
function LoadShares()
endFunction

bool function ContinueStrip(Form ItemRef, bool DoStrip = true)
	return sslActorLibrary.ContinueStrip(ItemRef, DoStrip)
endFunction

int function IntIfElse(bool check, int isTrue, int isFalse)
	if check
		return isTrue
	endIf
	return isFalse
endfunction

function ClearAlias()
	Clear()
endFunction

bool function PregnancyRisk()
	return _Thread.PregnancyRisk(_ActorRef)
endFunction

Function DoStatistics()
	; Threadが履歴と参加者に基づいてポジション統計を処理する
EndFunction

String function GetActorKey()
	return ""
endFunction

; 以下の関数はすべて明確に冗長である
; 機能が不要であるか、別の関数に統合されている
; これらの多くは基底のアクターを操作する専用機能を持ち、誤った呼び出しを許すと
; フレームワーク自体に問題を起こす。無言で失敗させると呼び出し側のコードにも問題が生じるため、
; すべてエラーメッセージを出して失敗する
Function LogRedundant(String asFunction)
	Debug.MessageBox("[SexLab]\nState '" + GetState() + "'; Function '" + asFunction + "' is a strictiyl redundant function that should not be called under any circumstance. See Papyrus Logs for more information.")
	Debug.TraceStack("[SexLab] Invoking Legacy Function " + asFunction)
EndFunction

function GetPositionInfo()
	LogRedundant("GetPositionInfo")
endFunction
function SyncActor()
	LogRedundant("SyncActor")
endFunction
function SyncAll(bool Force = false)
	LogRedundant("SyncAll")
endFunction
function RefreshActor()
	LogRedundant("RefreshActor")
endFunction
function RestoreActorDefaults()
	LogRedundant("RestoreActorDefaults")
endFunction
function SendAnimation()
	LogRedundant("SendAnimation")
endFunction
function StopAnimating(bool Quick = false, string ResetAnim = "IdleForceDefaultState")
	LogRedundant("StopAnimating")
endFunction
function StartAnimating()
	LogRedundant("OnBeginState")
endFunction
event ResetActor()
	LogRedundant("ResetActor")
endEvent
function ClearEffects()
	LogRedundant("ClearEffects")
endFunction
