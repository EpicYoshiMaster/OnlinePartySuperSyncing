
class Yoshi_SyncItem_Backpack extends Yoshi_SyncItem_ClassWhitelist
	abstract;

function OnNewBackpackItem(Hat_BackpackItem item) {
	local class<Object> ItemBackpackClass;

	ItemBackpackClass = item.BackpackClass;

	if(ShouldSync(item)) {
		OnValidItem(ItemBackpackClass);
	}
}

function OnValidItem(class<Object> ItemBackpackClass) {
	local string collectibleString;

	//Send the class and the map
	collectibleString = ItemBackpackClass $ "+" $ `GameManager.GetCurrentMapFilename();
	Sync(collectibleString);
}

function OnReceiveSync(string SyncString) {
	local array<string> arr;
	local Hat_Player ply;
	local class<Object> ItemBackpackClass;

	arr = SplitString(SyncString, "+");
	ply = Hat_Player(class'Engine'.static.GetEngine().GamePlayers[0].Actor.Pawn);
	ItemBackpackClass = class'Hat_ClassHelper'.static.ClassFromName(arr[0]);

	Hat_PlayerController(ply.Controller).GetLoadout().AddBackpack(class'Hat_Loadout'.static.MakeBackpackItem(ItemBackpackClass),false);

    SpawnParticle(GetTextureByName(arr[0]));
}