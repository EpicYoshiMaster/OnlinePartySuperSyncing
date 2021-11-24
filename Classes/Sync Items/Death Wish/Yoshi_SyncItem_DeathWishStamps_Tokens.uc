class Yoshi_SyncItem_DeathWishStamps_Tokens extends Yoshi_SyncItem_DeathWishStamps;

//TODO: Tokens likely won't sync properly due to the same actor level bit being used multiple times

var string TokenLevelBit;

function OnCollectedCollectible(Object InCollectible) {
	if (InCollectible.IsA('Hat_Collectible_DeathWishLevelToken'))
	{
		TokenLevelBit = Hat_Collectible_DeathWishLevelToken(InCollectible).OnCollectLevelBit.Id;
	}
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

	SyncString $= "|" $ TokenLevelBit $ "+" $ `GameManager.GetCurrentMapFilename();

	Print("OPSS_LOCALIZE =>" @ `ShowVar(self.class) @ `ShowVar(DeathWishBits[i].Contract) @ "Name: " @ GetLocalization(DeathWishBits[i].Contract) @ "Icon: " $ GetHUDIcon(DeathWishBits[i].Contract));

	Sync(SyncString);
}

function OnReceiveSync(string SyncString, Hat_GhostPartyPlayerStateBase Sender) {
	local array<string> arr, MainArr, BitArr;
	local class<Hat_SnatcherContract_DeathWish> DW;
	local int ObjectiveID, ObjectiveProgress;

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
		if(BitArr.length < 2) return;

		ObjectiveProgress = DW.static.GetObjectiveProgress(ObjectiveID);

		if(class'Hat_SaveBitHelper'.static.HasLevelBit(BitArr[0], 1, BitArr[1])) return;

		class'Hat_SaveBitHelper'.static.AddLevelBit(BitArr[0], 1, BitArr[1]);

		ObjectiveProgress += 1;

		DW.static.SetObjectiveValue(ObjectiveID, ObjectiveProgress);

		//TODO: Fix the Token in-world
	}
	//This is a finished stamp sync
	else {
		DW.static.ForceUnlockObjective(ObjectiveID);
	}

	FixDeathWishBits();

	CelebrateSync(Sender, GetLocalization(DW), GetHUDIcon(DW));
}

defaultproperties
{
	WhitelistedDeathWishes.Add(class'Hat_SnatcherContract_DeathWish_Tokens_MafiaTown');
}