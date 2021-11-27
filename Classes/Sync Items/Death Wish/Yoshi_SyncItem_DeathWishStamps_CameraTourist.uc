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
			LevelBitName = ObjectiveBitID $ "_" $ EnemyName;
			if(EnemyName != "" && EnemyBits.Find(LevelBitName) == INDEX_NONE && class'Hat_SaveBitHelper'.static.GetLevelBits(LevelBitName, OBJECTIVE_MAP) == 0) {
				EnemyBits.AddItem(LevelBitName);
			}

			BossName = GetSnappedID(enemy, true);
			LevelBitName = ObjectiveBitID $ "_" $ BossName;
			if(BossName != "" && BossBits.Find(LevelBitName) == INDEX_NONE && class'Hat_SaveBitHelper'.static.GetLevelBits(LevelBitName, OBJECTIVE_MAP) == 0) {
				BossBits.AddItem(LevelBitName);
			}

		}
	}

	Print("OPSS_CAMERATOURIST => " @ `ShowVar(EnemyBits.length) @ `ShowVar(BossBits.length));
}

function OnObjectiveCompleted(int i) {
	local string SyncString;
	SyncString = DeathWishBits[i].Contract $ "+" $ DeathWishBits[i].ObjectiveID;

	//Check for enemy pictures
	SyncString $= "|" $ CheckForNewBits(DeathWishBits[i].ObjectiveID);

	CelebrateSyncLocal(GetLocalization(DeathWishBits[i].Contract), GetHUDIcon(DeathWishBits[i].Contract));

	Sync(SyncString);
}

function OnObjectiveNewProgress(int i, int NewProgress) {
	local string SyncString;
	DeathWishBits[i].ObjectiveProgress = NewProgress;

	SyncString = DeathWishBits[i].Contract $ "+" $ DeathWishBits[i].ObjectiveID $ "+" $ NewProgress;

	//Check for enemy pictures
	SyncString $= "|" $ CheckForNewBits(DeathWishBits[i].ObjectiveID);

	CelebrateSyncLocal(GetLocalization(DeathWishBits[i].Contract), GetHUDIcon(DeathWishBits[i].Contract));

	Sync(SyncString);
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

function OnReceiveSync(string SyncString, Hat_GhostPartyPlayerStateBase Sender) {
	local array<string> arr, MainArr, BitArr;
	local class<Hat_SnatcherContract_DeathWish> DW;
	local int ObjectiveID, OriginalObjectiveProgress, ObjectiveProgress, i;

	arr = SplitString(SyncString, "|");

	if(arr.length < 2) return;

	MainArr = SplitString(arr[0], "+");
	BitArr = SplitString(arr[1], "+");

	if(MainArr.length < 2) return;

	DW = class<Hat_SnatcherContract_DeathWish>(class'Hat_ClassHelper'.static.ClassFromName(MainArr[0]));
	ObjectiveID = int(MainArr[1]);

    if(DW.static.IsContractPerfected() || DW.static.IsObjectiveCompleted(ObjectiveID)) return;

	//This is a sync with objective progress
	if(arr.length >= 3) {
		ObjectiveProgress = DW.static.GetObjectiveProgress(ObjectiveID);
		OriginalObjectiveProgress = ObjectiveProgress;

		for(i = 0; i < BitArr.length; i++) {
			if(BitArr[i] == "") continue;

			if(class'Hat_SaveBitHelper'.static.GetLevelBits(BitArr[i], OBJECTIVE_MAP) == 0) {
				class'Hat_SaveBitHelper'.static.SetLevelBits(BitArr[i], 1, OBJECTIVE_MAP);

				ObjectiveProgress += 1;
				DW.static.SetObjectiveValue(ObjectiveID, ObjectiveProgress);
			}
		}

		if(ObjectiveProgress <= OriginalObjectiveProgress) return; //We didn't actually gain any progress from this sync
	}
	//This is a finished stamp sync
	else {
		DW.static.ForceUnlockObjective(ObjectiveID);
	}

	FixDeathWishBits();

	CelebrateSync(Sender, GetLocalization(DW), GetHUDIcon(DW));
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
	if (a.bHidden) return "";

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