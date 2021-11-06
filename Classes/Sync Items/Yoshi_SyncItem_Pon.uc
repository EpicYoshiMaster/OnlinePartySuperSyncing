class Yoshi_SyncItem_Pon extends Yoshi_SyncItem;

function OnCollectedCollectible(Object InCollectible) {
	if(Hat_Collectible_EnergyBit(InCollectible) != None) {
        Sync("Gaming");
    }
}

function OnReceiveSync(string SyncString, Hat_GhostPartyPlayerStateBase Sender) {
	`GameManager.AddEnergyBits(1);
}