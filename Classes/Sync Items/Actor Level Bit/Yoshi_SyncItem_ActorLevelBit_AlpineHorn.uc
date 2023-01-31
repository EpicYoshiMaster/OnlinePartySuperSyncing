class Yoshi_SyncItem_ActorLevelBit_AlpineHorn extends Yoshi_SyncItem_ActorLevelBit;

function SyncActor(Actor a) {
	local int i;
	local Hat_SandStationHorn_Base horn;

	horn = Hat_SandStationHorn_Base(a);
	if(horn != None) {
		horn.isActivated = true;
		
        for(i = 0; i < ArrayCount(horn.TargetUnlocks); i++) {
            if(horn.TargetUnlocks[i] != None) {
                Hat_SandTravelNode(horn.TargetUnlocks[i]).UpdateHookStatus();
            }
        }
	}
}

static function Surface GetHUDIcon(optional Object SyncClass) {
	return Texture2D'HatInTime_Hud_LocationBanner.Textures.vikinghorn';
}

static function bool ShouldBeEnabled() {
	return class'Yoshi_OnlinePartySuperSync_GameMod'.default.SyncLevelEvents == 0;
}

defaultproperties
{
	ActorClasses.Add(class'Hat_SandStationHorn_Base');
	LocalizedNameKey="AlpineHornName"
}