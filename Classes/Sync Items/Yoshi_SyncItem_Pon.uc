class Yoshi_SyncItem_Pon extends Yoshi_SyncItem;

function OnCollectedCollectible(Object InCollectible) {
	if(Hat_Collectible_EnergyBit(InCollectible) != None) {
        Sync("Gaming");
    }
}

//This isn't even used here but hey why not!
static function Surface GetHUDIcon(optional Object SyncClass) {
	return Texture2D'HatInTime_Hud.Textures.EnergyBit';
}

function OnReceiveSync(string SyncString, Hat_GhostPartyPlayerStateBase Sender) {
	`GameManager.AddEnergyBits(1);
}

static function bool ShouldBeEnabled() {
	return class'Yoshi_OnlinePartySuperSync_GameMod'.default.SyncPons == 0;
}