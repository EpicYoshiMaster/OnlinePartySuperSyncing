class Yoshi_SyncItem_TimePiece extends Yoshi_SyncItem;

var bool ShouldBlockTimePiece;

//Time Pieces are probably the simplest of them all.
function OnTimePieceCollected(string Identifier) {
    local String SyncString;

    if(ShouldBlockTimePiece) { 
		ShouldBlockTimePiece = false; 
		return; 
	}
    if(class'Hat_SnatcherContract_DeathWish'.static.IsAnyActive(false) || class'GameMod'.static.HasActiveLevelMod()) return;

    SyncString = Identifier;
    SyncString $= `GameManager.GetCurrentAct() > 0 ? "+1" : "+0";

	Sync(SyncString);
}

function OnReceiveSync(string SyncString) {
	local array<string> arr;

	arr = SplitString(SyncString, "+");

	if(`GameManager.HasTimePiece(arr[0])) return;

	ShouldBlockTimePiece = true; //Otherwise an infinite loop of OP Commands occurs
    `GameManager.GiveTimePiece(arr[0], 1 == int(arr[1]));

	SpawnParticle();
	UpdatePowerPanels();
}

function UpdatePowerPanels() {
    local Hat_SpaceshipPowerPanel SPP;

	if(GameMod == None) return;

    if(`GameManager.GetCurrentMapFilename() ~= `GameManager.HubMapName) {
        foreach GameMod.DynamicActors(class'Hat_SpaceshipPowerPanel', SPP) {
            if(SPP.isA('Hat_SpaceshipPowerPanel')) {
                SPP.PostBeginPlay();
            }
        }
    }

}

defaultproperties
{
	ParticleScale=0.5
}