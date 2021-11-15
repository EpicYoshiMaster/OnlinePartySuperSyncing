class Yoshi_SyncItem_DeathWishStamps_CameraTourist extends Yoshi_SyncItem_DeathWishStamps;

//TODO: All the stuffs
function Update(float delta) {
	local int i;
	local int NewProgress;
	local string SyncString;
	
	if(DeathWishBits.length <= 0) {
		UpdateActiveDWs();
	}

	for(i = 0; i < DeathWishBits.length; i++) {

		NewProgress = DeathWishBits[i].Contract.static.GetObjectiveProgress(DeathWishBits[i].ObjectiveID);

		if(DeathWishBits[i].Contract.static.IsObjectiveCompleted(DeathWishBits[i].ObjectiveID)) {
			//Print("OPSS_DEATHWISH =>" @ `ShowVar(DeathWishBits[i].Contract) @ `ShowVar(DeathWishBits[i].ObjectiveID));
			SyncString = DeathWishBits[i].Contract $ "+" $ DeathWishBits[i].ObjectiveID;

			Sync(SyncString);

			DeathWishBits.Remove(i, 1);
			i--;
		}
		else if(DeathWishBits[i].ObjectiveProgress > -1 && NewProgress > DeathWishBits[i].ObjectiveProgress) {
			DeathWishBits[i].ObjectiveProgress = NewProgress;

			SyncString = DeathWishBits[i].Contract $ "+" $ DeathWishBits[i].ObjectiveID $ "+" $ NewProgress;

			Sync(SyncString);
		}		
	}
}

function OnReceiveSync(string SyncString, Hat_GhostPartyPlayerStateBase Sender) {

}

defaultproperties
{
	//WhitelistedDeathWishes.Add(class'Hat_SnatcherContract_DeathWish_CameraTourist_1');
}