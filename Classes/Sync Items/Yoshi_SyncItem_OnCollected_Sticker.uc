class Yoshi_SyncItem_OnCollected_Sticker extends Yoshi_SyncItem_OnCollected;

function bool IsBlacklisted(Object InCollectible) {
	if(Hat_Collectible_Sticker(InCollectible).IsHolo) {
		return true;
	}

	return Super.IsBlacklisted(InCollectible);
}

defaultproperties
{
	WhitelistedCollectibles.Add(class'Hat_Collectible_Sticker');
}