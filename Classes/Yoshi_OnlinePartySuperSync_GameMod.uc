/*
* Code by EpicYoshiMaster
*/
class Yoshi_OnlinePartySuperSync_GameMod extends GameMod;

const DEBUG_MODE = true;

//0 is Enabled, 1 is Disabled
var config int ShowSyncIcons;
var config int SyncTimePieces;
var config int SyncDeathWishStamps;
var config int SyncPons;
var config int SyncGeneralCollectibles;
var config int SyncCosmetics;
var config int SyncLevelEvents;

var config int SelectedOPSSTeam;

var bool HasControllerSpawned;

var Yoshi_HUDElement_OnlineSync SyncHUD;

var array<Yoshi_SyncItem> Syncs;

function SendSync(Yoshi_SyncItem SyncItem, string SyncString, Name CommandChannel) {
	CommandChannel = Name(GetTeamCode() $ "+" $ CommandChannel $ "+" $ SyncItem.class);

	Print("OPSS_SEND => " @ `ShowVar(SyncString) @ `ShowVar(CommandChannel));
    SendOnlinePartyCommand(SyncString, CommandChannel);
}

event OnOnlinePartyCommand(string Command, Name CommandChannel, Hat_GhostPartyPlayerStateBase Sender) {
	local int i;
	local array<string> CommandInfo;

	CommandInfo = SplitString(String(CommandChannel), "+");

	if(CommandInfo.Length < 3 || GetTeamCode() != CommandInfo[0]) return;
	if(Name(CommandInfo[1]) != class'Yoshi_SyncItem'.static.GetCommandChannel()) return;

	for(i = 0; i < Syncs.length; i++) {
		if(CommandInfo[2] ~= string(Syncs[i].class)) {
			Print("OPSS_RECEIVE => " @ `ShowVar(Command) @ `ShowVar(CommandChannel));
			Syncs[i].OnReceiveSync(Command, Sender);
		}
	}
}

function OnNewBackpackItem(Hat_BackpackItem item) {
	local int i;

	for(i = 0; i < Syncs.length; i++) {
		if(Yoshi_SyncItem_Backpack(Syncs[i]) != None) {
			Yoshi_SyncItem_Backpack(Syncs[i]).OnNewBackpackItem(item);
		}
	}
}

event OnModLoaded() {
	local int i;
	local array< class<Yoshi_SyncItem> > AllSyncClasses;

	Syncs.length = 0;
	AllSyncClasses = GetAllSyncClasses();

	for(i = 0; i < AllSyncClasses.length; i++) {

		//TODO: Add Config Checks
		Syncs.AddItem(new AllSyncClasses[i]);
		Syncs[Syncs.length - 1].OnAdded();
	}

	HookActorSpawn(class'Hat_PlayerController', 'Hat_PlayerController');
}

simulated event Tick(float delta) {
	local int i;

	for(i = 0; i < Syncs.length; i++) {
		Syncs[i].Update(delta);
	}
}

event OnHookedActorSpawn(Object NewActor, Name Identifier) {
	if(!HasControllerSpawned && Identifier == 'Hat_PlayerController') {
		HasControllerSpawned = true;
		SetTimer(0.1, false, NameOf(OnReady), self, NewActor);
	}
}

function OnReady(Object obj) {
	local Hat_PlayerController pc;
	local Yoshi_Loadout NewLoadout;

	pc = Hat_PlayerController(obj);
	if(pc != None) {

		Print("OPSS_ONREADY " $ `ShowVar(pc));
		SyncHUD = Yoshi_HUDElement_OnlineSync(Hat_HUD(pc.myHUD).OpenHUD(class'Yoshi_HUDElement_OnlineSync'));

		NewLoadout = new class'Yoshi_Loadout';
		NewLoadout.GameMod = self;
		NewLoadout.PlayerOwner = pc;
		NewLoadout.SaveGame = `SaveManager.GetCurrentSaveData();
		pc.MyLoadout = NewLoadout;
		`SaveManager.GetCurrentSaveData().LoadLoadout(pc);
		Hat_Player(pc.Pawn).ServerInitialUpdates();
	}
}

function OnCelebrateSync(Hat_GhostPartyPlayerStateBase state, string LocalizedItemName, Surface Icon) {
	SyncHUD.PushSync(state, LocalizedItemName, Icon);
}

//Call it once then never again...
static function array< class<Yoshi_SyncItem> > GetAllSyncClasses() {
	local array< class<Yoshi_SyncItem> > AllSyncClasses;
	local array< class<Object> > AllClasses;
    local int i;

    AllClasses = class'Hat_ClassHelper'.static.GetAllScriptClasses("Yoshi_SyncItem");
    for(i = 0; i < AllClasses.length; i++) {
        if(class<Yoshi_SyncItem>(AllClasses[i]) != None) {
            AllSyncClasses.AddItem(class<Yoshi_SyncItem>(AllClasses[i]));
        }
    }

    return AllSyncClasses;
}

event OnConfigChanged(Name ConfigName) {
	//TODO: Figure Out Configs / HUD?
}

function string GetTeamCode() {
    if(SelectedOPSSTeam <= 0 || SelectedOPSSTeam >= class'YoshiPrivate_OnlinePartySuperSync_Commands'.default.Teams.Length) {
        return "NONE";
    }
    
    return class'YoshiPrivate_OnlinePartySuperSync_Commands'.default.Teams[SelectedOPSSTeam - 1].TeamCode;
}

function LinearColor GetTeamColor() {
    local LinearColor Empty;

    if(SelectedOPSSTeam <= 0 || SelectedOPSSTeam > class'YoshiPrivate_OnlinePartySuperSync_Commands'.default.Teams.Length) {
        return Empty;
    }
    
    return class'YoshiPrivate_OnlinePartySuperSync_Commands'.default.Teams[SelectedOPSSTeam - 1].TeamColor;    
}

static final function Print(coerce string msg)
{
    local WorldInfo wi;

	if(!DEBUG_MODE) return;

	msg = "[OPSS] " $ msg;

    wi = class'WorldInfo'.static.GetWorldInfo();
    if (wi != None)
    {
        if (wi.GetALocalPlayerController() != None)
            wi.GetALocalPlayerController().TeamMessage(None, msg, 'Event', 6);
        else
            wi.Game.Broadcast(wi, msg);
    }
}