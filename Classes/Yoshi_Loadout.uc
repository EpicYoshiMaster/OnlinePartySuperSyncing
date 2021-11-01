
class Yoshi_Loadout extends Hat_Loadout;

var Yoshi_OnlinePartySuperSync_GameMod GameMod;

function bool AddBackpack(Hat_BackpackItem l, optional bool equip, optional bool surpress_error, optional Hat_Player owner) {
	local bool ShouldSync;

	ShouldSync = Super.AddBackpack(l, equip, surpress_error, owner);

	if(ShouldSync && GameMod != None) {
		GameMod.OnNewBackpackItem(l);
	}

	return ShouldSync;
}