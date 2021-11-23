class Yoshi_SyncItem_ActorLevelBit_Bonfire extends Yoshi_SyncItem_ActorLevelBit;

function SyncActor(Actor a) {
	if(Hat_Bonfire_Base(a) != None) {
		Hat_Bonfire_Base(a).OnCompleted(true);
	}
}

static function Surface GetHUDIcon(optional Object SyncClass) {
	local class<Hat_Bonfire_Base> BonfireClass;

	BonfireClass = class<Hat_Bonfire_Base>(SyncClass);

	if(BonfireClass != None && BonfireClass.default.HUDIcon != None) {
		return BonfireClass.default.HUDIcon;
	}

	return Super.GetHUDIcon(SyncClass);
}

defaultproperties
{
	ActorClasses.Add(class'Hat_Bonfire_Base');
	LocalizedNameKey="BonfireName"
}