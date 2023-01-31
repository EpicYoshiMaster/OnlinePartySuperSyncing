class Yoshi_SyncItem_ActorLevelBit_Chest extends Yoshi_SyncItem_ActorLevelBit;

function SyncActor(Actor a) {
	if(Hat_TreasureChest_Base(a) != None) {
		Hat_TreasureChest_Base(a).Empty();
	}
}

static function bool ShouldBeEnabled() {
	return class'Yoshi_OnlinePartySuperSync_GameMod'.default.SyncGeneralCollectibles == 0;
}

defaultproperties
{
	ActorClasses.Add(class'Hat_TreasureChest_Base');
	ShouldCelebrateSync=false
	LocalizedNameKey="ChestName"
}