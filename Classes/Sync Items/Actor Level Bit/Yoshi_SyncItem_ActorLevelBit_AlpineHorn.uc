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

defaultproperties
{
	ActorClasses.Add(class'Hat_SandStationHorn_Base');
}