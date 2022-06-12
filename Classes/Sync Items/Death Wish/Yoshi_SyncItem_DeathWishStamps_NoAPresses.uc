class Yoshi_SyncItem_DeathWishStamps_NoAPresses extends Yoshi_SyncItem_DeathWishStamps;

const TimePieceIDPrefix = "_TimePieceCollected_";

var string CollectedIdentifier;

//If we grab a time piece and the stamp ticks up, this identifier HAS to be the one for the stamp unless they're dumb and cheating
//The identifier will happen first and the stamp will be checked on the next frame
function OnTimePieceCollected(string Identifier) {
	CollectedIdentifier = Identifier;
}

function string GetObjectiveString(const DeathWishBit DWBit) {
	local string SyncString;

	SyncString = Super.GetObjectiveString(DWBit);

	SyncString $= "|" $ CollectedIdentifier;
	return SyncString;
}

//Returns TRUE if we should continue syncing the objective, returns FALSE otherwise
function bool ShouldContinueObjectiveSync(const out DeathWishBit DWBit, const out array<string> ExtraArr) {
	if(DWBit.Contract.static.IsContractPerfected() || DWBit.Contract.static.IsObjectiveCompleted(DWBit.ObjectiveID)) return false;
	if(DWBit.ObjectiveProgress >= 0 && HasTimePiece(ExtraArr[0])) return false;

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
		SetUnobtainedTimePiece(ExtraArr[0]);
		DWBit.Contract.static.SetObjectiveValue(DWBit.ObjectiveID, DWBit.Contract.static.GetObjectiveProgress(DWBit.ObjectiveID) + 1);
	}

	return true;
}

static function bool HasTimePiece(string Identifier) {
	local string bitid;

	bitid = class'Hat_SnatcherContract_DeathWish_NoAPresses'.static.GetObjectiveBitID() $ TimePieceIDPrefix $ Identifier;
	return class'Hat_SaveBitHelper'.static.HasLevelBit(bitid, 1, class'Hat_SnatcherContract_DeathWish_NoAPresses'.default.ObjectiveMapName);
}

static function SetUnobtainedTimePiece(string Identifier) {
	local string bitid;
	
	bitid = class'Hat_SnatcherContract_DeathWish_NoAPresses'.static.GetObjectiveBitID() $ TimePieceIDPrefix $ Identifier;

	class'Hat_SaveBitHelper'.static.SetLevelBits(bitid, 1, class'Hat_SnatcherContract_DeathWish_NoAPresses'.default.ObjectiveMapName);
}

defaultproperties
{
	WhitelistedDeathWishes.Add(class'Hat_SnatcherContract_DeathWish_NoAPresses');
}