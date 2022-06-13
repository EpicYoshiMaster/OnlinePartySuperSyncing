
class Yoshi_SyncItem_Backpack extends Yoshi_SyncItem
	abstract;

var const array< class<Object> > WhitelistedCollectibles; //Use most general class of a collectible that can be handled here
var const array< class<Object> > BlacklistedCollectibles; //Use for subclasses of a Whitelisted Collectible that should not go through

var bool UseItemQualityInfo; //Specified by Subclasses

var bool IgnoringReceivedItem; //State variable, ignore calls to OnNewBackpackItem that result from received syncs

function OnNewBackpackItem(Hat_BackpackItem item) {
	local class<Object> CheckClass;
	local int i;

	if(IgnoringReceivedItem) return;

	if(!UseItemQualityInfo) {
		CheckClass = item.BackpackClass;
	}
	else {
		CheckClass = Hat_LoadoutBackpackItem(item).ItemQualityInfo;
	}

	//Check whitelist
	for(i = 0; i < WhitelistedCollectibles.length; i++) {
		if(ClassIsChildOf(CheckClass, WhitelistedCollectibles[i])) {

			if(IsBlacklisted(CheckClass)) return;

			//We found a valid collectible!
			OnValidCollectible(CheckClass);
			return;
		}
	}
}

function bool IsBlacklisted(class<Object> CheckClass) {
	local int i;

	for(i = 0; i < BlacklistedCollectibles.length; i++) {
		if(ClassIsChildOf(CheckClass, BlacklistedCollectibles[i])) {
			return true;
		}
	}

	return false;
}

function OnValidCollectible(class<Object> CheckClass) {
	local string collectibleString;

	CelebrateSyncLocal(GetLocalization(CheckClass), GetHUDIcon(CheckClass));

	//Send the class
	collectibleString = string(CheckClass);
	Sync(collectibleString);
}

function OnReceiveSync(string SyncString, Hat_GhostPartyPlayerStateBase Sender) {
	local array<string> arr;
	local bool AddedItemToBackpack;
	local Hat_Player ply;
	local class<Object> ItemBackpackClass;
	local class<Hat_CosmeticItemQualityInfo> ItemQualityInfo;

	arr = SplitString(SyncString, "+");
	ply = Hat_Player(class'Engine'.static.GetEngine().GamePlayers[0].Actor.Pawn);

	if(!UseItemQualityInfo) {
		ItemBackpackClass = class'Hat_ClassHelper'.static.ClassFromName(arr[0]);
	}
	else {
		ItemQualityInfo = class<Hat_CosmeticItemQualityInfo>(class'Hat_ClassHelper'.static.ClassFromName(arr[0]));
		ItemBackpackClass = ItemQualityInfo.default.CosmeticItemWeApplyTo;
	}

	//Wrap up ignoring this item so we don't send it back to who we just got it from
	IgnoringReceivedItem = true;
	AddedItemToBackpack = Hat_PlayerController(ply.Controller).GetLoadout().AddBackpack(class'Hat_Loadout'.static.MakeLoadoutItem(ItemBackpackClass, ItemQualityInfo), false);
	IgnoringReceivedItem = false;

	if(!AddedItemToBackpack) return;

	if(!UseItemQualityInfo) {
		CelebrateSync(Sender, GetLocalization(ItemBackpackClass), GetHUDIcon(ItemBackpackClass));
	}
	else {
		CelebrateSync(Sender, GetLocalization(ItemQualityInfo), GetHUDIcon(ItemQualityInfo));
	}
}

static function string GetLocalization(optional Object SyncClass) {
	local class<Hat_CosmeticItem> InventoryClass;
	local class<Hat_CosmeticItemQualityInfo> CosmeticQualityInfoClass;

	InventoryClass = class<Hat_CosmeticItem>(SyncClass);
	if(InventoryClass != None) {
		return InventoryClass.static.GetLocalizedName(InventoryClass.default.MyItemQualityInfo);
	}

	CosmeticQualityInfoClass = class<Hat_CosmeticItemQualityInfo>(SyncClass);

	if(CosmeticQualityInfoClass != None) {
		InventoryClass = class<Hat_CosmeticItem>(CosmeticQualityInfoClass.default.CosmeticItemWeApplyTo);

		if(InventoryClass != None) {
			return InventoryClass.Static.GetLocalizedName(CosmeticQualityInfoClass);
		}
	}

	//Backpack items can end up being collectibles, this is a bit weird but it gets the job done
	return class'Yoshi_SyncItem_OnCollected'.static.GetLocalization(SyncClass);
}

static function Surface GetHUDIcon(optional Object SyncClass) {
	local class<Hat_CosmeticItem> CosmeticClass;
	local class<Hat_CosmeticItemQualityInfo> CosmeticQualityInfoClass;

	CosmeticClass = class<Hat_CosmeticItem>(SyncClass);

	if(CosmeticClass != None && CosmeticClass.default.HUDIcon != None) {
		return CosmeticClass.default.HUDIcon;
	}

	CosmeticQualityInfoClass = class<Hat_CosmeticItemQualityInfo>(SyncClass);

	if(CosmeticQualityInfoClass != None && CosmeticQualityInfoClass.default.HUDIcon != None) {
		return CosmeticQualityInfoClass.default.HUDIcon;
	}

	//Backpack items can end up being collectibles, this is a bit weird but it gets the job done
	return class'Yoshi_SyncItem_OnCollected'.static.GetHUDIcon(SyncClass);
}