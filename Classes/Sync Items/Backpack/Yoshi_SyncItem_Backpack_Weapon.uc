class Yoshi_SyncItem_Backpack_Weapon extends Yoshi_SyncItem_Backpack;

static function Surface GetHUDIcon(optional class<Object> SyncClass) {
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