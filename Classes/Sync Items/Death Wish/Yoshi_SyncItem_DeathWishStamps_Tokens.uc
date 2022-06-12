class Yoshi_SyncItem_DeathWishStamps_Tokens extends Yoshi_SyncItem_DeathWishStamps;

var string TokenLevelBit;

var string CurrentLevelBit; //For multiple stamp triggers on the same level bit

function OnCollectedCollectible(Object InCollectible) {
	if (InCollectible.IsA('Hat_Collectible_DeathWishLevelToken'))
	{
		TokenLevelBit = Hat_Collectible_DeathWishLevelToken(InCollectible).OnCollectLevelBit.Id;
	}
}

function string GetObjectiveString(const DeathWishBit DWBit) {
	local string SyncString;

	SyncString = Super.GetObjectiveString(DWBit);

	SyncString $= "|" $ TokenLevelBit $ "+" $ `GameManager.GetCurrentMapFilename();

	return SyncString;
}

//Returns TRUE if we should continue syncing the objective, returns FALSE otherwise
function bool ShouldContinueObjectiveSync(const out DeathWishBit DWBit, const out array<string> ExtraArr) {
	//When cascading already tracked level bits, check to see if this is one we're currently adding to multiple objectives
	if(DWBit.ObjectiveProgress >= 0 && class'Hat_SaveBitHelper'.static.HasLevelBit(ExtraArr[0], 1, ExtraArr[1]) && (ExtraArr[0] != CurrentLevelBit)) return false;

	return Super.ShouldContinueObjectiveSync(DWBit, ExtraArr);
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
		DWBit.Contract.static.SetObjectiveValue(DWBit.ObjectiveID, DWBit.Contract.static.GetObjectiveProgress(DWBit.ObjectiveID) + 1);
	}

	class'Hat_SaveBitHelper'.static.AddLevelBit(ExtraArr[0], 1, ExtraArr[1]);
	CurrentLevelBit = ExtraArr[0];
	UpdateActors();

	return true;
}

function UpdateActors() {
	local Hat_Collectible_DeathWishLevelToken token;

	foreach class'WorldInfo'.static.GetWorldInfo().DynamicActors(class'Hat_Collectible_DeathWishLevelToken', token) {
		if(token != None) {
			token.PostBeginPlay();
		}
	}
}

defaultproperties
{
	WhitelistedDeathWishes.Add(class'Hat_SnatcherContract_DeathWish_Tokens_MafiaTown');
}