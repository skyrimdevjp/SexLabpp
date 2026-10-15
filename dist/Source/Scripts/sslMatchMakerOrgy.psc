Scriptname sslMatchMakerOrgy extends ActiveMagicEffect
{アクターがSexLabで有効か確認し、効果終了時にSexを開始する非常に基本的な呪文エフェクト。}

SexLabFramework property SexLab auto
sslMatchMakerMain Property MatchMakerMain Auto

Event OnEffectStart(Actor TargetRef, Actor CasterRef)
  If (!MatchMakerMain.AddActors(TargetRef))
    Debug.Notification("Could not add Actor: " + SexLabUtil.ActorName(TargetRef))
  EndIf
EndEvent