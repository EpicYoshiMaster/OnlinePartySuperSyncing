
class Yoshi_SyncItem extends Object 
	implements(Hat_GameEventsInterface)
	abstract;

const HAT_PACKAGE_NAME = "hatintimegamecontent";
const OPSS_LOCALIZATION_FILENAME = "opss";
const DEBUG_CELEBRATEHUD_LOCAL = true;
const DEBUG_SPAWNPARTICLE_LOCAL = true;

var Yoshi_OnlinePartySuperSync_GameMod GameMod;
var const MaterialInterface SyncMaterial;
var const ParticleSystem SyncParticle;
var float ParticleScale;

var bool AddedToGEI;

function OnAdded() {

	if(GameMod == None) {
		GameMod = GetGameMod();
	}

	if(!AddedToGEI) {
		`GameManager.GameEventObjects.AddItem(self);
		AddedToGEI = true;
	}
}

function Update(float delta) {}

function Sync(string SyncString) {
	if(GameMod != None) {
		GameMod.SendSync(self, SyncString, GetCommandChannel());
	}
}

function OnReceiveSync(string SyncString, Hat_GhostPartyPlayerStateBase Sender) {

}

//TODO: Implement this function everywhere
function bool IsValidPackage(Object obj) {
	//TODO: Check Config value for mod collectibles
	return string(obj.GetPackageName()) ~= HAT_PACKAGE_NAME;
}

//TODO: SCFOS != Mafia Town
function bool IsInSameWorld(string MapName) {
	return `GameManager.GetCurrentMapFilename() ~= MapName;
}

function CelebrateSyncLocal(string LocalizedItemName, Surface Icon) {
	local Hat_Player ply;

	Print("OPSS_LOCALIZE => " @ self.class @ "(Name: " $ LocalizedItemName $ ", Icon: " $ Icon $ ")");

	if(DEBUG_CELEBRATEHUD_LOCAL && GameMod != None) {
		ply = Hat_Player(class'Engine'.static.GetEngine().GamePlayers[0].Actor.Pawn);
		GameMod.OnCelebrateSync(class'Hat_GhostPartyPlayerStateBase'.static.GetLocalPlayerState(ply.GetPlayerIndex()), LocalizedItemName, Icon);
	}

	if(DEBUG_SPAWNPARTICLE_LOCAL && Texture(Icon) != None) {
		SpawnParticle(Texture(Icon));
	}
}

function CelebrateSync(Hat_GhostPartyPlayerStateBase Sender, string LocalizedItemName, Surface Icon) {

	if(GameMod != None) {
		GameMod.OnCelebrateSync(Sender, LocalizedItemName, Icon);
	}

	if(Texture(Icon) != None) {
		SpawnParticle(Texture(Icon));
	}
}

function SpawnParticle(Texture Tex) {
	local MaterialInstanceConstant GenMat;
	local LinearColor TeamColor;

	if(GameMod == None) return;
	//Check Sync Icon Config

	GenMat = new class'MaterialInstanceConstant';
    GenMat.SetParent(SyncMaterial);
	TeamColor = GameMod.GetTeamColor();
    GenMat.SetVectorParameterValue('TeamColor', TeamColor);
    GenMat.SetTextureParameterValue('Diffuse', Tex);

	CreateParticle(SyncParticle, GenMat, ParticleScale);
}

static function Name GetCommandChannel() {
	return class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSItem;
}

//This function should be overridden by child classes to determine how to grab Localization for various sync types.
static function string GetLocalization(optional Object SyncClass) {
	Print("OPSS_ERR_LOCALIZE => GetLocalization: Failed to grab Localized Name! " @ `ShowVar(SyncClass));

	return "NULL";
}

//This function should be overridden by child classes to determine the HUD Icons for various sync types.
static function Surface GetHUDIcon(optional Object SyncClass) {
	Print("OPSS_ERR_HUDICON => GetHUDIcon: Failed to grab Icon! " @ `ShowVar(SyncClass));

	return Texture2D'HatInTime_Hud_Loadout.Item_Icons.itemicon_unknown';
}

//Makes the cool icon that shows up when you get a sync
function CreateParticle(ParticleSystem P, optional MaterialInterface MI, optional float PartScale = 0.5) {
	local ParticleSystemComponent psc;
    local Hat_Player ply;

	if(GameMod == None) return;

    foreach GameMod.DynamicActors(class'Hat_Player', ply) {
        if(P != None && ply.IsLocallyControlled()) {
            psc = class'WorldInfo'.static.GetWorldInfo().MyEmitterPool.SpawnEmitter(P, ply.Location + vect(0,0,30));
            if(MI != None) {
                psc.SetMaterialParameter('CollectibleOverride', MI);
            }
		    psc.SetScale(PartScale);
        }
    }
}

static function Yoshi_OnlinePartySuperSync_GameMod GetGameMod() {
	local Yoshi_OnlinePartySuperSync_GameMod GM;

	foreach class'WorldInfo'.static.GetWorldInfo().DynamicActors(class'Yoshi_OnlinePartySuperSync_GameMod', GM) {
		if(GM != None) {
			return GM;
		}
	}

	return GM;
}

static final function Print(const string msg)
{
    class'Yoshi_OnlinePartySuperSync_GameMod'.static.Print(msg);
}

defaultproperties
{
	SyncMaterial=MaterialInstanceConstant'Yoshi_OPSuperSync_Content.Yoshi_YarnMaterial_Sync_INST'
	SyncParticle=ParticleSystem'Yoshi_OPSuperSync_Content.Yoshi_YarnType_Sync'
	ParticleScale=0.25
}