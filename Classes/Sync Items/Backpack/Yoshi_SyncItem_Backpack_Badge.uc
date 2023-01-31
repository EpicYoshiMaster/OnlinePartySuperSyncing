
class Yoshi_SyncItem_Backpack_Badge extends Yoshi_SyncItem_Backpack;

static function bool ShouldBeEnabled() {
	return class'Yoshi_OnlinePartySuperSync_GameMod'.default.SyncGeneralCollectibles == 0;
}

defaultproperties
{
	WhitelistedCollectibles.Add(class'Hat_Ability');
	BlacklistedCollectibles.Add(class'Hat_Ability_Trigger'); //This should get rid of hats which we don't want to sync
}