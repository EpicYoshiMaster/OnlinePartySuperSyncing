class Yoshi_SyncItem_Backpack_Weapon extends Yoshi_SyncItem_Backpack;

static function string GetLocalization(optional Object SyncClass) {
	local class<Hat_Weapon> WeaponClass;

	WeaponClass = class<Hat_Weapon>(SyncClass);

	if(WeaponClass != None) {
		return WeaponClass.static.GetLocalizedName();
	}

	return Super.GetLocalization(SyncClass);
}

static function Surface GetHUDIcon(optional Object SyncClass) {
	local class<Hat_Weapon> WeaponClass;

	WeaponClass = class<Hat_Weapon>(SyncClass);

	if(WeaponClass != None && WeaponClass.default.HUDIcon != None) {
		return WeaponClass.default.HUDIcon;
	}

	return Super.GetHUDIcon(SyncClass);
}

defaultproperties
{
	WhitelistedCollectibles.Add(class'Hat_Weapon');
}