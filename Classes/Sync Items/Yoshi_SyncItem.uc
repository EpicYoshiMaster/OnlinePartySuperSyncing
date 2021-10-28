
class Yoshi_SyncItem extends Hat_StatusEffect 
	implements(Hat_GameEventsInterface)
	abstract;

var Yoshi_OnlinePartySuperSync_GameMod GameMod;
var const MaterialInterface SyncMaterial;
var const ParticleSystem SyncParticle;
var float ParticleScale;

var bool AddedToGEI;

function OnAdded(Actor a) {
	Super.OnAdded(a);

	if(GameMod == None) {
		GameMod = GetGameMod();
	}

	if(!AddedToGEI) {
		`GameManager.GameEventObjects.AddItem(self);
		AddedToGEI = true;
	}
}

function bool Update(float delta) {

}

function string ConvertToSync() {
	return "Gaming";
}

function Sync(string SyncString) {
	if(GameMod != None) {
		GameMod.SendSync(self, SyncString, GetCommandChannel());
	}
}

function OnReceiveSync(string SyncString) {

}

function SpawnParticle(Texture2D Texture) {
	local Texture2D ParticleTex;
	local MaterialInstanceConstant GenMat;
	local ParticleSystemComponent psc;
    local Hat_Player ply;

	if(GameMod == None) return;
	//Check Sync Icon Config

	ParticleTex = Texture;

	GenMat = new class'MaterialInstanceConstant';
    GenMat.SetParent(SyncMaterial);
    GenMat.SetVectorParameterValue('TeamColor', GameMod.GetTeamColor());
    GenMat.SetTextureParameterValue('Diffuse', Texture);

	CreateParticle(SyncParticle, GenMat, ParticleScale);
}

static function Name GetCommandChannel() {
	return class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSItem;
}

function Texture2D GetSyncTexture() {
	return Texture2D'HatInTime_Hud_Loadout.Item_Icons.itemicon_unknown';
}

//Makes the cool icon that shows up when you get a sync
function CreateParticle(ParticleSystem P, optional MaterialInterface MI, optional float ParticleScale = 0.5) {
	local ParticleSystemComponent psc;
    local Hat_Player ply;

	if(GameMod == None) return;

    foreach GameMod.DynamicActors(class'Hat_Player', ply) {
        if(P != None && ply.IsLocallyControlled()) {
            psc = class'WorldInfo'.static.GetWorldInfo().MyEmitterPool.SpawnEmitter(P, ply.Location + vect(0,0,30));
            if(MI != None) {
                psc.SetMaterialParameter('CollectibleOverride', MI);
            }
		    psc.SetScale(ParticleScale);
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



defaultproperties
{
	Infinite=true
	SyncMaterial=MaterialInstanceConstant'Yoshi_OPSuperSync_Content.Yoshi_YarnMaterial_Sync_INST'
	SyncParticle=ParticleSystem'Yoshi_OPSuperSync_Content.Yoshi_YarnType_Sync'
	ParticleScale=0.25
}