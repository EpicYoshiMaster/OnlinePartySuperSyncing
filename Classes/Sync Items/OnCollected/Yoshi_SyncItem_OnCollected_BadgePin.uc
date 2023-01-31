class Yoshi_SyncItem_OnCollected_BadgePin extends Yoshi_SyncItem_OnCollected;

static function bool ShouldBeEnabled() {
	return class'Yoshi_OnlinePartySuperSync_GameMod'.default.SyncGeneralCollectibles == 0;
}

defaultproperties
{
	WhitelistedCollectibles.Add(class'Hat_Collectible_BadgeSlot');
	WhitelistedCollectibles.Add(class'Hat_Collectible_BadgeSlot2');
}