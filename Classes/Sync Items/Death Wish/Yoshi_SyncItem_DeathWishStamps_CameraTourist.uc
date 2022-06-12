class Yoshi_SyncItem_DeathWishStamps_CameraTourist extends Yoshi_SyncItem_DeathWishStamps;

const OBJECTIVE_MAP = "subconforest";
const PICTURE_ENEMIES = 0;
const PICTURE_THREE = 1;
const PICTURE_BOSSES = 2;

var array<string> EnemyBits;
var array<string> BossBits;

function OnPostInitGame() {
	local Hat_Enemy enemy;
	local string ObjectiveBitID, EnemyName, BossName, LevelBitName;

	ObjectiveBitID = class'Hat_SnatcherContract_DeathWish_CameraTourist_1'.static.GetObjectiveBitID();

	foreach class'WorldInfo'.static.GetWorldInfo().DynamicActors(class'Hat_Enemy', enemy) {
		if(enemy != None) {

			EnemyName = GetSnappedID(enemy, false);
			BossName = GetSnappedID(enemy, true);

			Print("OPSS_ENEMY_TEST => " $ `ShowVar(enemy) @ `ShowVar(EnemyName) @ `ShowVar(BossName));
 
			LevelBitName = ObjectiveBitID $ "_" $ EnemyName;
			if(EnemyName != "" && EnemyBits.Find(LevelBitName) == INDEX_NONE && class'Hat_SaveBitHelper'.static.GetLevelBits(LevelBitName, OBJECTIVE_MAP) == 0) {
				Print("OPSS_ENEMY_ADD => " $ `ShowVar(enemy));
				EnemyBits.AddItem(LevelBitName);
			}

			
			LevelBitName = ObjectiveBitID $ "_" $ BossName;
			if(BossName != "" && BossBits.Find(LevelBitName) == INDEX_NONE && class'Hat_SaveBitHelper'.static.GetLevelBits(LevelBitName, OBJECTIVE_MAP) == 0) {
				Print("OPSS_BOSS_ADD => " $ `ShowVar(enemy));
				BossBits.AddItem(LevelBitName);
			}

		}
	}

	Print("OPSS_CAMERATOURIST => " @ `ShowVar(EnemyBits.length) @ `ShowVar(BossBits.length));
}

function string GetObjectiveString(const DeathWishBit DWBit) {
	local string SyncString;

	SyncString = Super.GetObjectiveString(DWBit);

	return SyncString $ "|" $ CheckForNewBits(DWBit.ObjectiveID);
}

function string CheckForNewBits(int ObjectiveID) {
	local int i;
	local string NewBitsString;

	NewBitsString = "";

	if(ObjectiveID == PICTURE_ENEMIES) {
		for(i = 0; i < EnemyBits.length; i++) {
			if(class'Hat_SaveBitHelper'.static.GetLevelBits(EnemyBits[i], OBJECTIVE_MAP) > 0) {
				NewBitsString $= "+" $ EnemyBits[i];

				EnemyBits.Remove(i, 1);
				i--;
			}
		}
	}
	else if(ObjectiveID == PICTURE_BOSSES) {
		for(i = 0; i < BossBits.length; i++) {
			if(class'Hat_SaveBitHelper'.static.GetLevelBits(BossBits[i], OBJECTIVE_MAP) > 0) {
				NewBitsString $= "+" $ BossBits[i];

				BossBits.Remove(i, 1);
				i--;
			}
		}
	}

	return NewBitsString;
}

//Returns TRUE if we should continue syncing the objective, returns FALSE otherwise
function bool ShouldContinueObjectiveSync(const out DeathWishBit DWBit, const out array<string> ExtraArr) {
	local int i;

	if(DWBit.Contract.static.IsContractPerfected() || DWBit.Contract.static.IsObjectiveCompleted(DWBit.ObjectiveID)) return false;
	if(DWBit.ObjectiveProgress == -1) return Super.ShouldContinueObjectiveSync(DWBit, ExtraArr);

	for(i = 0; i < ExtraArr.length; i++) {
		if(ExtraArr[i] == "") continue;

		if(class'Hat_SaveBitHelper'.static.GetLevelBits(ExtraArr[i], OBJECTIVE_MAP) == 0) {
			return true; //We've located a new level bit, we are guaranteed to have progress
		}
	}

	return false;
}

//Should handle unlocking objectives
//Returns TRUE if we should celebrate this sync, returns FALSE otherwise
function bool HandleObjectiveSync(const out DeathWishBit DWBit, const out array<string> ExtraArr) {
	local int i;
	local int NewObjectiveProgress;

	//This is a full clear
	if(DWBit.ObjectiveProgress == -1) {
		DWBit.Contract.static.ForceUnlockObjective(DWBit.ObjectiveID);
	}
	else {
		NewObjectiveProgress = DWBit.Contract.static.GetObjectiveProgress(DWBit.ObjectiveID);

		for(i = 0; i < ExtraArr.length; i++) {
			if(ExtraArr[i] == "") continue;

			if(class'Hat_SaveBitHelper'.static.GetLevelBits(ExtraArr[i], OBJECTIVE_MAP) == 0) {
				class'Hat_SaveBitHelper'.static.SetLevelBits(ExtraArr[i], 1, OBJECTIVE_MAP);

				NewObjectiveProgress += 1;				
			}
		}

		DWBit.Contract.static.SetObjectiveValue(DWBit.ObjectiveID, NewObjectiveProgress);
	}

	return true;
}

function FixDeathWishBits() {
	local int i;
	Super.FixDeathWishBits();

	for(i = 0; i < EnemyBits.length; i++) {
		if(class'Hat_SaveBitHelper'.static.GetLevelBits(EnemyBits[i], OBJECTIVE_MAP) > 0) {
			EnemyBits.Remove(i, 1);
			i--;
		}
	}

	for(i = 0; i < BossBits.length; i++) {
		if(class'Hat_SaveBitHelper'.static.GetLevelBits(BossBits[i], OBJECTIVE_MAP) > 0) {
			BossBits.Remove(i, 1);
			i--;
		}
	}
}

static function String GetSnappedID(Actor a, optional bool CheckBoss)
{
	if (CheckBoss)
	{
		if (a.IsA('Hat_Boss_Mafia') ||
			a.IsA('Hat_Boss_Conductor') ||
			a.IsA('Hat_Enemy_Toilet') ||
			a.IsA('Hat_Boss_SnatcherBoss') ||
			a.IsA('Hat_Boss_MustacheGirl') ||
			a.IsA('Hat_Enemy_BigToxicFlower'))
			return string(a.class);

		if (class'Hat_SeqCond_DeadBirdWinner'.static.GetDeadBirdWinner() == 1)
		{
			if (a.IsA('Hat_Enemy_SecurityGuard_Conductor'))
				return "Hat_Boss_Conductor";
		}
		else if (class'Hat_SeqCond_DeadBirdWinner'.static.GetDeadBirdWinner() == 2)
		{
			if (a.IsA('Hat_Enemy_SecurityGuard_DJGrooves'))
				return "Hat_Boss_DJGrooves";
		}
	}
	else
	{
		if (a.IsA('Hat_Enemy_SecurityGuard_Conductor')) return "";
		if (a.IsA('Hat_Enemy_SecurityGuard_DJGrooves')) return "";

		if (a.IsA('Hat_Enemy_Mobster')) return "Hat_Enemy_Mobster";
		if (a.IsA('Hat_Enemy_ScienceOwl')) return "Hat_Enemy_ScienceOwl";
		return string(a.class);
	}

	return "";
}

defaultproperties
{
	WhitelistedDeathWishes.Add(class'Hat_SnatcherContract_DeathWish_CameraTourist_1');
}