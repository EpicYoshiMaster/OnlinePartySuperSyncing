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

function OnObjectiveCompleted(int i) {
	local string SyncString;
	SyncString = DeathWishBits[i].Contract $ "+" $ DeathWishBits[i].ObjectiveID;

	SyncString $= "|";

	Print("OPSS_LOCALIZE =>" @ `ShowVar(self.class) @ `ShowVar(DeathWishBits[i].Contract) @ "Name: " @ GetLocalization(DeathWishBits[i].Contract) @ "Icon: " $ GetHUDIcon(DeathWishBits[i].Contract));

	Sync(SyncString);
}

function OnObjectiveNewProgress(int i, int NewProgress) {
	local string SyncString;
	DeathWishBits[i].ObjectiveProgress = NewProgress;

	SyncString = DeathWishBits[i].Contract $ "+" $ DeathWishBits[i].ObjectiveID $ "+" $ NewProgress;

	SyncString $= "|";
	if(DeathWishBits[i].ObjectiveID == KILL_EVERYBODY) {
		SyncString $= LastKilledEnemy;
	}

	Print("OPSS_LOCALIZE =>" @ `ShowVar(self.class) @ `ShowVar(DeathWishBits[i].Contract) @ "Name: " @ GetLocalization(DeathWishBits[i].Contract) @ "Icon: " $ GetHUDIcon(DeathWishBits[i].Contract));

	Sync(SyncString);
}

function OnReceiveSync(string SyncString, Hat_GhostPartyPlayerStateBase Sender) {
	local array<string> arr, MainArr, BitArr;
	local class<Hat_SnatcherContract_DeathWish> DW;
	local int ObjectiveID, ObjectiveProgress;
	local bool IsNewKill;

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
		if(ObjectiveID != KILL_EVERYBODY) {
			ObjectiveProgress = int(arr[2]);
			if(DW.static.GetObjectiveProgress(ObjectiveID) >= ObjectiveProgress) return;

			DW.static.SetObjectiveValue(ObjectiveID, ObjectiveProgress);
		}
		else {
			if(BitArr.length <= 0) return;

			ObjectiveProgress = DW.static.GetObjectiveProgress(ObjectiveID);

			IsNewKill = TryListKill(Name(BitArr[0]));

			if(!IsNewKill) return;

			ObjectiveProgress += 1;

			DW.static.SetObjectiveValue(ObjectiveID, ObjectiveProgress);
		}
	}
	//This is a finished stamp sync
	else {
		DW.static.ForceUnlockObjective(ObjectiveID);

		if(ObjectiveID == KILL_EVERYBODY) {
			class'Hat_SnatcherContract_DeathWish_KillEverybody'.static.WipeKillEverybodyProgress();
		}
	}

	FixDeathWishBits();

	CelebrateSync(Sender, GetLocalization(DW), GetHUDIcon(DW));
}

function bool TryListKill(Name n)
{
	local string LevelBitName;

	LevelBitName = class'Hat_SnatcherContract_DeathWish_KillEverybody'.static.GetObjectiveBitID(KILL_EVERYBODY) $ "_Killed_" $ n;

	if (class'Hat_SnatcherContract_DeathWish_KillEverybody'.default.Targets.Find(n) == INDEX_NONE || (n == 'Hat_Boss_Conductor' && n == 'Hat_Boss_DJGrooves')) return false;
	if (class'Hat_SaveBitHelper'.static.HasLevelBit(LevelBitName, 1, `GameManager.HubMapName)) return false;

	class'Hat_SaveBitHelper'.static.AddLevelBit(LevelBitName, 1, `GameManager.HubMapName);
	return true;
}

defaultproperties
{
	WhitelistedDeathWishes.Add(class'Hat_SnatcherContract_DeathWish_KillEverybody');
}