class Yoshi_SyncItem_DeathWishStamps_NoAPresses extends Yoshi_SyncItem_DeathWishStamps;

const TimePieceIDPrefix = "_TimePieceCollected_";

var string CollectedIdentifier;

//If we grab a time piece and the stamp ticks up, this identifier HAS to be the one for the stamp unless they're dumb and cheating
//The identifier will happen first and the stamp will be checked on the next frame
function OnTimePieceCollected(string Identifier) {
	CollectedIdentifier = Identifier;
}

function OnObjectiveCompleted(int i) {
	local string SyncString;

	SyncString = DeathWishBits[i].Contract $ "+" $ DeathWishBits[i].ObjectiveID;
	SyncString $= "|";

	Print("OPSS_LOCALIZE =>" @ `ShowVar(self.class) @ `ShowVar(DeathWishBits[i].Contract) @ "Name: " @ GetLocalization(DeathWishBits[i].Contract) @ "Icon: " $ GetHUDIcon(DeathWishBits[i].Contract));

	Sync(SyncString);
}

//Only the 4 time pieces bonus will use this
function OnObjectiveNewProgress(int i, int NewProgress) {
	local string SyncString;
	DeathWishBits[i].ObjectiveProgress = NewProgress;

	SyncString = DeathWishBits[i].Contract $ "+" $ DeathWishBits[i].ObjectiveID $ "+" $ NewProgress;
	SyncString $= "|" $ CollectedIdentifier;

	Print("OPSS_LOCALIZE =>" @ `ShowVar(self.class) @ `ShowVar(DeathWishBits[i].Contract) @ "Name: " @ GetLocalization(DeathWishBits[i].Contract) @ "Icon: " $ GetHUDIcon(DeathWishBits[i].Contract));

	Sync(SyncString);
}

function OnReceiveSync(string SyncString, Hat_GhostPartyPlayerStateBase Sender) {
	local array<string> arr, MainArr, BitArr;
	local class<Hat_SnatcherContract_DeathWish> DW;
	local int ObjectiveID, ObjectiveProgress;
	local bool IsNewIdentifier;

	//Step 1: Check for the extra enemy attachment
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
		if(BitArr.length <= 0) return;
		ObjectiveProgress = DW.static.GetObjectiveProgress(ObjectiveID);

		IsNewIdentifier = class'Hat_SnatcherContract_DeathWish_NoAPresses'.static.CheckAndSetUnobtainedTimePiece(BitArr[0]);

		if(!IsNewIdentifier) return;

		ObjectiveProgress += 1;

		DW.static.SetObjectiveValue(ObjectiveID, ObjectiveProgress);
	}
	//This is a finished stamp sync
	else {
		//We allow this case to be a failsafe if enemies ever desync, everyone still gets the objective as completed
		//No point worrying about enemy tallys
		DW.static.ForceUnlockObjective(ObjectiveID);
	}

	FixDeathWishBits();

	CelebrateSync(Sender, GetLocalization(DW), GetHUDIcon(DW));
}

defaultproperties
{
	WhitelistedDeathWishes.Add(class'Hat_SnatcherContract_DeathWish_NoAPresses');
}