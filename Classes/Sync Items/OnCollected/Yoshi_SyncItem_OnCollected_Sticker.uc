class Yoshi_SyncItem_OnCollected_Sticker extends Yoshi_SyncItem_OnCollected;

function bool IsBlacklisted(Object InCollectible) {
	if(Hat_Collectible_Sticker(InCollectible).IsHolo) {
		return true;
	}

	return Super.IsBlacklisted(InCollectible);
}

static function bool ShouldBeEnabled() {
	return class'Yoshi_OnlinePartySuperSync_GameMod'.default.SyncCosmetics == 0;
}

defaultproperties
{
	WhitelistedCollectibles.Add(class'Hat_Collectible_Sticker');
}