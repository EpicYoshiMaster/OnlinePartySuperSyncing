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
			Syncs[i].OnReceiveSync(Command);
		}
	}
}

event Tick(float delta) {
	local Hat_PlayerController pc;

	pc = Hat_PlayerController(GetALocalPlayerController());

	if(pc != None) {
		if(Hat_HUD(pc.myHUD).GetHUD(class'Yoshi_HUDElement_OnlineSync') == None) {
			Hat_HUD(pc.myHUD).OpenHUD(class'Yoshi_HUDElement_OnlineSync');
		}
	}
}

event OnModLoaded() {
	local int i;
	Syncs.length = 0;

	Syncs.AddItem(new class'Yoshi_SyncItem_Pon');
	//Syncs.AddItem(new class'Yoshi_SyncItem_OnCollected_Badge');
	Syncs.AddItem(new class'Yoshi_SyncItem_OnCollected_Sticker');
	Syncs.AddItem(new class'Yoshi_SyncItem_OnCollected_Yarn');
	Syncs.AddItem(new class'Yoshi_SyncItem_TimePiece');

	for(i = 0; i < Syncs.length; i++) {
		Syncs[i].OnAdded();
	}
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