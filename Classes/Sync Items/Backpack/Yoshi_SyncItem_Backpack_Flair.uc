class Yoshi_SyncItem_Backpack_Flair extends Yoshi_SyncItem_Backpack;

defaultproperties
{
	WhitelistedCollectibles.Add(class'Hat_CosmeticItemQualityInfo');
	BlacklistedCollectibles.Add(class'Hat_CosmeticItemQualityInfo_SearchAny');

	UseItemQualityInfo=true
}