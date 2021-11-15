class Yoshi_SyncItem_ChestOpen extends Yoshi_SyncItem;

var array<Hat_TreasureChest_Base> ChestActors; 

function OnPostInitGame() {
	local Hat_TreasureChest_Base Chest;
	local string BitID;

	ChestActors.length = 0;

	foreach class'WorldInfo'.static.GetWorldInfo().DynamicActors(class'Hat_TreasureChest_Base', Chest) {
		if(Chest != None) {
			BitID = class'Hat_SaveBitHelper'.static.GetBitId(Chest, Chest.UpdateVersion);
        	if(!class'Hat_SaveBitHelper'.static.HasLevelBit(BitID, 1)) {
            	ChestActors.AddItem(Chest);
        	}
		}
	}

	Print("OPSS_ONPOSTINITGAME " @ `ShowVar(ChestActors.length));
}

function Update(float delta) {
	local int i, UpdateVersion;
	local string BitID, SyncString;

	for(i = 0; i < ChestActors.length; i++) {
		if(ChestActors[i] == None) {
			ChestActors.Remove(i, 1);
			i--;
			continue;
		}

		UpdateVersion = ChestActors[i].UpdateVersion;
        BitID = class'Hat_SaveBitHelper'.static.GetBitId(ChestActors[i], UpdateVersion);

		if(class'Hat_SaveBitHelper'.static.HasLevelBit(BitID, 1)) {

			SyncString = BitID $ "+" $ `GameManager.GetCurrentMapFilename();
			Sync(SyncString);

			ChestActors.Remove(i, 1);
			i--;
		}
	}	
}

function UpdateActors(string BitID) {
	local int i, UpdateVersion;
	local string BitID;

	for(i = 0; i < ChestActors.length; i++) {

		UpdateVersion = ChestActors[i].UpdateVersion;
        BitID = class'Hat_SaveBitHelper'.static.GetBitId(ChestActors[i], UpdateVersion);

		if(class'Hat_SaveBitHelper'.static.HasLevelBit(BitID, 1)) {
			ChestActors[i].Empty();
		}
	}
}

function OnReceiveSync(string SyncString, Hat_GhostPartyPlayerStateBase Sender) {
	local array<string> arr;
	local string BitID;

	arr = SplitString(SyncString, "+");

	if(arr.length < 3) return;
	if(class'Hat_SaveBitHelper'.static.HasLevelBit(arr[0], 1, arr[1])) return;

	class'Hat_SaveBitHelper'.static.AddLevelBit(arr[0], 1, arr[1]);
	
	if(`GameManager.GetCurrentMapFilename() ~= arr[1]) {
		UpdateActors(arr[0]);
	}

}