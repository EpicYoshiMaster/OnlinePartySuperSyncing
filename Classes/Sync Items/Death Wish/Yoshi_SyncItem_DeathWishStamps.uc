class Yoshi_SyncItem_DeathWishStamps extends Yoshi_SyncItem
	abstract;

var array< class<Hat_SnatcherContract_DeathWish> > WhitelistedDeathWishes;
var array< class<Hat_SnatcherContract_DeathWish> > BlacklistedDeathWishes;

struct DeathWishBit {
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

var array<DeathWishBit> DeathWishBits;

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
	//TODO: this is a waste of time?
	if(DeathWishBits.length <= 0) {
		UpdateActiveDWs();
	}

	IterateDeathWishes(true);
}

function IterateDeathWishes(bool ShouldCountCompletion) {
	local int i, NewProgress;

	for(i = 0; i < DeathWishBits.length; i++) {

		NewProgress = DeathWishBits[i].Contract.static.GetObjectiveProgress(DeathWishBits[i].ObjectiveID);

		if(DeathWishBits[i].Contract.static.IsObjectiveCompleted(DeathWishBits[i].ObjectiveID)) {
			if(ShouldCountCompletion) {
				OnObjectiveCompleted(DeathWishBits[i], true);
			}

			DeathWishBits.Remove(i, 1);
			i--;
		}
		else if(DeathWishBits[i].ObjectiveProgress > -1 && NewProgress > DeathWishBits[i].ObjectiveProgress) {
			DeathWishBits[i].ObjectiveProgress = NewProgress;

			if(ShouldCountCompletion) {
				OnObjectiveCompleted(DeathWishBits[i]);
			}
		}		
	}
}

function OnObjectiveCompleted(DeathWishBit DWBit, optional bool IsFullClear = false) {
	local string SyncString;

	if(IsFullClear) {
		DWBit.ObjectiveProgress = -1; //Make sure this sends as an all in one sync
	}
	
	SyncString = GetObjectiveString(DWBit);

	CelebrateSyncLocal(GetLocalization(DWBit.Contract), GetHUDIcon(DWBit.Contract));

	Sync(SyncString);
}

function string GetObjectiveString(const DeathWishBit DWBit) {
	return DWBit.Contract $ "+" $ DWBit.ObjectiveID $ "+" $ DWBit.ObjectiveProgress;
}

function OnReceiveSync(string SyncString, Hat_GhostPartyPlayerStateBase Sender) {
	local array<string> arr, MainArr, ExtraArr;
	local DeathWishBit DWBit;
	local bool ShouldCelebrate;

	arr = SplitString(SyncString, "|");
	if(arr.length >= 1) {
		MainArr = SplitString(arr[0], "+");
	}

	if(arr.length >= 2) {
		ExtraArr = SplitString(arr[1], "+");
	}

	if(MainArr.length >= 3) {

		DWBit.Contract = class<Hat_SnatcherContract_DeathWish>(class'Hat_ClassHelper'.static.ClassFromName(MainArr[0]));
		DWBit.ObjectiveID = int(MainArr[1]);
		DWBit.ObjectiveProgress = int(MainArr[2]);

		//Check if we should continue with handling the sync
		if(!ShouldContinueObjectiveSync(DWBit, ExtraArr)) {
			Print("OPSS_FailContinueObjective " $ `ShowVar(self) @ `ShowVar(DWBit.Contract) @ `ShowVar(DWBit.ObjectiveID) @ `ShowVar(DWBit.ObjectiveProgress));
			return;
		}

		ShouldCelebrate = HandleObjectiveSync(DWBit, ExtraArr);

		FixDeathWishBits();
		
		if(ShouldCelebrate) {
			CelebrateSync(Sender, GetLocalization(DWBit.Contract), GetHUDIcon(DWBit.Contract));
		}	
	}
}

//Returns TRUE if we should continue syncing the objective, returns FALSE otherwise
function bool ShouldContinueObjectiveSync(const out DeathWishBit DWBit, const out array<string> ExtraArr) {
	if(DWBit.Contract.static.IsContractPerfected() || DWBit.Contract.static.IsObjectiveCompleted(DWBit.ObjectiveID)) return false;
	if(DWBit.ObjectiveProgress >= 0 && DWBit.Contract.static.GetObjectiveProgress(DWBit.ObjectiveID) >= DwBit.ObjectiveProgress) return false;

	return true;
}

//Should handle unlocking objectives
//Returns TRUE if we should celebrate this sync, returns FALSE otherwise
function bool HandleObjectiveSync(const out DeathWishBit DWBit, const out array<string> ExtraArr) {
	//This is a full clear
	if(DWBit.ObjectiveProgress == -1) {
		DWBit.Contract.static.ForceUnlockObjective(DWBit.ObjectiveID);
	}
	//This is a progress update
	else {
		DWBit.Contract.static.SetObjectiveValue(DWBit.ObjectiveID, DWBit.ObjectiveProgress);
	}

	return true;
}

static function string GetLocalization(optional Object SyncClass) {
	local class<Hat_SnatcherContract> ContractClass;

	ContractClass = class<Hat_SnatcherContract>(SyncClass);

	if(ContractClass != None) {
		return ContractClass.static.GetLocalizedTitle();
	}

	return Super.GetLocalization(SyncClass);	
}

static function Surface GetHUDIcon(optional Object SyncClass) {
	local class<Hat_SnatcherContract> ContractClass;

	ContractClass = class<Hat_SnatcherContract>(SyncClass);

	if(ContractClass != None && ContractClass.default.HUDIcon != None) {
		return ContractClass.default.HUDIcon;
	}

	return Super.GetHUDIcon(SyncClass);
}

function FixDeathWishBits() {
	IterateDeathWishes(false);
}

function UpdateActiveDWs()
{
	local int i, j;
	local Hat_SnatcherContract_DeathWish DW;
	local DeathWishBit NewDWBit;
	
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
				else {
					NewDWBit.ObjectiveProgress = -1;
				}

				DeathWishBits.AddItem(NewDWBit);

				Print("OPSS_NEWDEATHWISHBIT =>" @ `ShowVar(self) @ `ShowVar(NewDWBit.Contract) @ `ShowVar(NewDWBit.ObjectiveID) @ `ShowVar(NewDWBit.ObjectiveProgress));
			}
		}
	}
}

static function bool ShouldBeEnabled() {
	return class'Yoshi_OnlinePartySuperSync_GameMod'.default.SyncDeathWishStamps == 0;
}