class Yoshi_SyncItem_ActorLevelBit_Bonfire extends Yoshi_SyncItem_ActorLevelBit;

function SyncActor(Actor a) {
	if(Hat_Bonfire_Base(a) != None) {
		Hat_Bonfire_Base(a).OnCompleted(true);
	}
}

defaultproperties
{
	ActorClasses.Add(class'Hat_Bonfire_Base');
}