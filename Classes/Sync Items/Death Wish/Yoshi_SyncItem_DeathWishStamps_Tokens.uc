class Yoshi_SyncItem_DeathWishStamps_Tokens extends Yoshi_SyncItem_DeathWishStamps;

var string TokenLevelBit;

var string CurrentLevelBit; //For multiple stamp triggers on the same level bit

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

	CelebrateSyncLocal(GetLocalization(DeathWishBits[i].Contract), GetHUDIcon(DeathWishBits[i].Contract));

	Sync(SyncString);
}

function OnObjectiveNewProgress(int i, int NewProgress) {
	local string SyncString;
	DeathWishBits[i].ObjectiveProgress = NewProgress;

	SyncString = DeathWishBits[i].Contract $ "+" $ DeathWishBits[i].ObjectiveID $ "+" $ NewProgress;

	SyncString $= "|" $ TokenLevelBit $ "+" $ `GameManager.GetCurrentMapFilename();

	CelebrateSyncLocal(GetLocalization(DeathWishBits[i].Contract), GetHUDIcon(DeathWishBits[i].Contract));

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

		if(class'Hat_SaveBitHelper'.static.HasLevelBit(BitArr[0], 1, BitArr[1]) && (BitArr[0] != CurrentLevelBit)) return;

		class'Hat_SaveBitHelper'.static.AddLevelBit(BitArr[0], 1, BitArr[1]);
		CurrentLevelBit = BitArr[0];

		ObjectiveProgress += 1;

		DW.static.SetObjectiveValue(ObjectiveID, ObjectiveProgress);

		UpdateActors();
	}
	//This is a finished stamp sync
	else {
		DW.static.ForceUnlockObjective(ObjectiveID);
	}

	FixDeathWishBits();

	CelebrateSync(Sender, GetLocalization(DW), GetHUDIcon(DW));
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