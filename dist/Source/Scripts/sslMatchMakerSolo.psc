Scriptname sslMatchMakerSolo extends ActiveMagicEffect
{1人のみを対象に、現代的な方法でSexLabシーンを開始する非常に基本的な呪文エフェクト。}

SexLabFramework property SexLab auto
sslMatchMakerMain Property MatchMakerMain Auto

Event OnEffectStart(Actor TargetRef, Actor CasterRef)

    Actor[] sceneActors = new Actor[1]
    sceneActors[0] = CasterRef

	MatchMakerMain.TriggerSex(sceneActors)
EndEvent