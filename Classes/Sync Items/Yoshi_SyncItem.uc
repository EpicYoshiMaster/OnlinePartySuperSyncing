
class Yoshi_SyncItem extends Object 
	implements(Hat_GameEventsInterface)
	abstract;

const HAT_PACKAGE_NAME = "hatintimegamecontent";

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

function CelebrateSync(Hat_GhostPartyPlayerStateBase Sender, string LocalizedItemName, Texture2D Texture) {

	if(GameMod != None) {
		GameMod.OnCelebrateSync(Sender.GetDisplayName(), LocalizedItemName, Texture);
	}

	SpawnParticle(Texture);
}

function SpawnParticle(Texture2D Texture) {
	local MaterialInstanceConstant GenMat;
	local LinearColor TeamColor;

	if(GameMod == None) return;
	//Check Sync Icon Config

	GenMat = new class'MaterialInstanceConstant';
    GenMat.SetParent(SyncMaterial);
	TeamColor = GameMod.GetTeamColor();
    GenMat.SetVectorParameterValue('TeamColor', TeamColor);
    GenMat.SetTextureParameterValue('Diffuse', Texture);

	CreateParticle(SyncParticle, GenMat, ParticleScale);
}

static function Name GetCommandChannel() {
	return class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSItem;
}

//Where we get the icon, if you ever see a ? then I missed an approach to find the HUDIcon
static function Texture2D GetTextureByName(string Collectible) {
    local Class<Object> CollectibleClass;
    CollectibleClass = class'Hat_ClassHelper'.static.ClassFromName(Collectible);
    if(class<Hat_Collectible_Important>(CollectibleClass) != None) {
        if(Texture2D(class<Hat_Collectible_Important>(CollectibleClass).default.HUDIcon) != None) {
            return Texture2D(class<Hat_Collectible_Important>(CollectibleClass).default.HUDIcon);
        }

        if(class<Hat_Collectible_Important>(CollectibleClass).default.InventoryClass != None) {
            if(Texture2D(class<Hat_CosmeticItem>(class<Hat_Collectible_Important>(CollectibleClass).default.InventoryClass).default.HUDIcon) != None) {
                return Texture2D(class<Hat_CosmeticItem>(class<Hat_Collectible_Important>(CollectibleClass).default.InventoryClass).default.HUDIcon);
            }
        }
    }

    if(class<Hat_CosmeticItem>(CollectibleClass) != None) {
        if(Texture2D(class<Hat_CosmeticItem>(CollectibleClass).default.HUDIcon) != None) {
            return Texture2D(class<Hat_CosmeticItem>(CollectibleClass).default.HUDIcon);
        }
    }

    if(class<Hat_CosmeticItemQualityInfo>(CollectibleClass) != None) {
        if(Texture2D(class<Hat_CosmeticItemQualityInfo>(CollectibleClass).default.HUDIcon) != None) {
            return Texture2D(class<Hat_CosmeticItemQualityInfo>(CollectibleClass).default.HUDIcon);
        }
    }

    if(class<Hat_Bonfire_Base>(CollectibleClass) != None) {
        if(class<Hat_Bonfire_Base>(CollectibleClass).default.HUDIcon != None) {
            return class<Hat_Bonfire_Base>(CollectibleClass).default.HUDIcon;
        }
        
    }

    if(class<Hat_SandStationHorn_Base>(CollectibleClass) != None) {
        return Texture2D'HatInTime_Hud_LocationBanner.Textures.vikinghorn';
    }

    if(class<Hat_Weapon>(CollectibleClass) != None) {
        if(class<Hat_Weapon>(CollectibleClass).default.HUDIcon != None) {
            return class<Hat_Weapon>(CollectibleClass).default.HUDIcon;
        }
    }

    if(class<Hat_Collectible_EnergyBit>(CollectibleClass) != None) {
        return Texture2D'HatInTime_Hud.Textures.EnergyBit';
    }

    if(class<Hat_Collectible_HealthBit>(CollectibleClass) != None) {
        return Texture2D'HatInTime_Hud2.Textures.health_pon';
    }

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