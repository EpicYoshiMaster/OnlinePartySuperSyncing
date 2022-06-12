class Yoshi_SyncItem_DeathWishStamps_KillEverybody extends Yoshi_SyncItem_DeathWishStamps;

const KILL_EVERYBODY = 2;

var Name LastKilledEnemy;

function OnPawnCombatDeath(Pawn PawnCombat, Controller Killer, class<Object> DamageType, Vector HitLocation)
{
	if (Hat_PlayerController(Killer) == None && !PawnCombat.IsA('Hat_Enemy_Shromb_Egg')) return;

	LastKilledEnemy = PawnCombat.class.Name;

	if (PawnCombat.IsA('Hat_Enemy_Mobster')) LastKilledEnemy = 'Hat_Enemy_Mobster';
	if (PawnCombat.IsA('Hat_Enemy_AlleyCat')) LastKilledEnemy = 'Hat_Enemy_NinjaCat';
	if (PawnCombat.IsA('Hat_Enemy_AlleyRat')) LastKilledEnemy = 'Hat_Enemy_Rat';
}

function string GetObjectiveString(const DeathWishBit DWBit) {
	local string SyncString;

	SyncString = Super.GetObjectiveString(DWBit);

	if(DWBit.ObjectiveID == KILL_EVERYBODY) {
		SyncString $= "|" $ LastKilledEnemy;
	}

	return SyncString;
}

//Returns TRUE if we should continue syncing the objective, returns FALSE otherwise
function bool ShouldContinueObjectiveSync(const out DeathWishBit DWBit, const out array<string> ExtraArr) {
	if(DWBit.ObjectiveID == KILL_EVERYBODY && ExtraArr.length > 0) {
		return IsNewKill(Name(ExtraArr[0])); //Kill Everybody is the only objective that uses the extra array
	}

	return Super.ShouldContinueObjectiveSync(DWBit, ExtraArr);
}

//Should handle unlocking objectives
//Returns TRUE if we should celebrate this sync, returns FALSE otherwise
function bool HandleObjectiveSync(const out DeathWishBit DWBit, const out array<string> ExtraArr) {
	//This is a full clear
	if(DWBit.ObjectiveProgress == -1) {

		DWBit.Contract.static.ForceUnlockObjective(DWBit.ObjectiveID);

		if(DWBit.ObjectiveID == KILL_EVERYBODY) {
			class'Hat_SnatcherContract_DeathWish_KillEverybody'.static.WipeKillEverybodyProgress();
		}
	}
	//This is a progress update
	else {
		if(DWBit.ObjectiveID == KILL_EVERYBODY) {
			AddNewKill(Name(ExtraArr[0])); //This is verified by the precondition function
			DWBit.Contract.static.SetObjectiveValue(DWBit.ObjectiveID, DWBit.Contract.static.GetObjectiveProgress(DWBit.ObjectiveID) + 1);
		}
		else {
			DWBit.Contract.static.SetObjectiveValue(DWBit.ObjectiveID, DWBit.ObjectiveProgress);
		}
	}

	return true;
}

function bool IsNewKill(Name n)
{
	local string LevelBitName;

	LevelBitName = class'Hat_SnatcherContract_DeathWish_KillEverybody'.static.GetObjectiveBitID(KILL_EVERYBODY) $ "_Killed_" $ n;

	if (class'Hat_SnatcherContract_DeathWish_KillEverybody'.default.Targets.Find(n) == INDEX_NONE || (n == 'Hat_Boss_Conductor' && n == 'Hat_Boss_DJGrooves')) return false;
	if (class'Hat_SaveBitHelper'.static.HasLevelBit(LevelBitName, 1, `GameManager.HubMapName)) return false;

	return true;
}

function AddNewKill(Name n) {
	local string LevelBitName;

	LevelBitName = class'Hat_SnatcherContract_DeathWish_KillEverybody'.static.GetObjectiveBitID(KILL_EVERYBODY) $ "_Killed_" $ n;

	class'Hat_SaveBitHelper'.static.AddLevelBit(LevelBitName, 1, `GameManager.HubMapName);
}

defaultproperties
{
	WhitelistedDeathWishes.Add(class'Hat_SnatcherContract_DeathWish_KillEverybody');
}