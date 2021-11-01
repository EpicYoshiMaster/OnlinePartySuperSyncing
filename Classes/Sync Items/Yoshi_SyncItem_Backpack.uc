
class Yoshi_SyncItem_Backpack extends Yoshi_SyncItem
	abstract;

var const array< class<Object> > WhitelistedCollectibles; //Use most general class of a collectible that can be handled here
var const array< class<Object> > BlacklistedCollectibles; //Use for subclasses of a Whitelisted Collectible that should not go through

function OnNewBackpackItem(Hat_BackpackItem item) {
	local class<Object> ItemBackpackClass;
	local int i;

	ItemBackpackClass = item.BackpackClass;

	//Check whitelist
	for(i = 0; i < WhitelistedCollectibles.length; i++) {
		if(ClassIsChildOf(ItemBackpackClass, WhitelistedCollectibles[i])) {

			if(IsBlacklisted(ItemBackpackClass)) return;

			//We found a valid collectible!
			OnValidCollectible(ItemBackpackClass);
			return;
		}
	}
}

function bool IsBlacklisted(class<Object> ItemBackpackClass) {
	local int i;

	for(i = 0; i < BlacklistedCollectibles.length; i++) {
		if(ClassIsChildOf(ItemBackpackClass, WhitelistedCollectibles[i])) {
			return true;
		}
	}

	return false;
}

function OnValidCollectible(class<Object> ItemBackpackClass) {
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