class Yoshi_SyncItem_DeathWishStamps extends Yoshi_SyncItem
	abstract;

var array< class<Hat_SnatcherContract_DeathWish> > WhitelistedDeathWishes;
var array< class<Hat_SnatcherContract_DeathWish> > BlacklistedDeathWishes;

//Special Death Wishes?

//TODO:
//Need Extra Level Bits
//Camera Tourist
//Kill Everybody
//A Presses
//Fix the coins

struct OPSS_DeathWishBit {
	var class<Hat_SnatcherContract_DeathWish> Contract;
	var int ObjectiveID;
	//If -1, this should only sync as an all-or-nothing objective
	//If > -1, this should sync any time it increases and then update
	var int ObjectiveProgress; 
	structdefaultproperties
	{
		ObjectiveProgress=-1;
	}
};

var array<OPSS_DeathWishBit> DeathWishBits;

function bool IsAllowed(class<Hat_SnatcherContract_DeathWish> DW) {
	local int i;

	//Check whitelist
	for(i = 0; i < WhitelistedDeathWishes.length; i++) {
		if(ClassIsChildOf(DW, WhitelistedDeathWishes[i])) {

			if(IsBlacklisted(DW)) return false;
			return true;
		}
	}

	return false;
}

function bool IsBlacklisted(class<Hat_SnatcherContract_DeathWish> DW) {
	local int i;

	for(i = 0; i < BlacklistedDeathWishes.length; i++) {
		if(ClassIsChildOf(DW, BlacklistedDeathWishes[i])) {
			return true;
		}
	}

	return false;
}

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

function UpdateActiveDWs()
{
	local int i, j;
	local Hat_SnatcherContract_DeathWish DW;
	local OPSS_DeathWishBit NewDWBit;
	
	DeathWishBits.length = 0;
	for (i = 0; i < `GameManager.DeathWishes.Length; i++)
	{
		DW = `GameManager.DeathWishes[i];

		for(j = 0; j < DW.default.Objectives.length; j++) {
			if(!DW.static.IsObjectiveCompleted(j) && IsAllowed(DW.class)) {
				NewDWBit.Contract = DW.class;
				NewDWBit.ObjectiveID = j;

				if(DW.default.Objectives[j].MaxTriggerCount > 1 && !DW.default.Objectives[j].ResetProgressOnLevelEntry) {
					NewDWBit.ObjectiveProgress = DW.static.GetObjectiveProgress(j);
				}

				DeathWishBits.AddItem(NewDWBit);

				Print("OPSS_NEWDEATHWISHBIT => " @ `ShowVar(self) @ `ShowVar(NewDWBit.Contract) @ `ShowVar(NewDWBit.ObjectiveID) @ `ShowVar(NewDWBit.ObjectiveProgress));
			}
		}
	}
}