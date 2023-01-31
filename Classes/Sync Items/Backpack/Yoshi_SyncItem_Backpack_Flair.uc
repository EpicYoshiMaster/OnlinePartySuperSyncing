class Yoshi_SyncItem_Backpack_Flair extends Yoshi_SyncItem_Backpack;

static function bool ShouldBeEnabled() {
	return class'Yoshi_OnlinePartySuperSync_GameMod'.default.SyncCosmetics == 0;
}

defaultproperties
{
	WhitelistedCollectibles.Add(class'Hat_CosmeticItemQualityInfo');
	BlacklistedCollectibles.Add(class'Hat_CosmeticItemQualityInfo_SearchAny');

	UseItemQualityInfo=true
}