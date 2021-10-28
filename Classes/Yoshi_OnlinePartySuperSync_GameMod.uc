/*
* Code by EpicYoshiMaster
* Yes, all you need is a GameMod
* 
* Each Sync requires a different strategy, which is pretty cool.
* Time Pieces run on a simple GEI function
* Death Wish Stamps run on a Tick function, which goes through currently incomplete active Death Wishes
* Pons run on another simple GEI function
* General Collectibles vary by type, some are tracked in GEI, others are tracked in a Tick function. I sadly have to track your entire inventory every tick
* Cosmetics are tracked in a Tick function
*
*
*/
class Yoshi_OnlinePartySuperSync_GameMod extends GameMod;

//0 is Enabled, 1 is Disabled
var config int ShowSyncIcons;
var config int SyncTimePieces;
var config int SyncDeathWishStamps;
var config int SyncPons;
var config int SyncGeneralCollectibles;
var config int SyncCosmetics;
var config int SyncLevelEvents;

var config int SelectedOPSSTeam; //0 is No Team, 1 = Red, 2 = Green, 3 = Blue, 4 = Yellow

var const bool DebugMode; //I'm dumb so sorry you don't get access lol

var bool BlockTimePiece;
var Array< class< Hat_Collectible_Decoration > > DecorationPriorities;
var ParticleSystem TimePieceParticle;
var ParticleSystem DeathWishStampParticle;
var ParticleSystem RelicParticle;
var ParticleSystem GeneralParticle;
var MaterialInstanceConstant CollectibleMaterial;

var array<Actor> ChestActors;
var array<Actor> ProgressionActors;
var bool isAlpineIntroComplete;

struct DeathWishLevelBitSet {
    var class<Hat_SnatcherContract_DeathWish> DeathWish;
    var array<bool> ObjectivesComplete;
    var array<bool> InitialObjectivesComplete;
};

var array<DeathWishLevelBitSet> CurrentDeathWishes;
var array<Hat_BackpackItem> AddItemQueue;
var BackpackInfo2017 PlayerInventory;

var array<Yoshi_SyncItem> Syncs;

function SendSync(Yoshi_SyncItem SyncItem, string SyncString, Name CommandChannel) {
	CommandChannel = Name(GetTeamCode() $ "+" $ CommandChannel $ "+" $ SyncItem.class);
    SendOnlinePartyCommand(SyncString, CommandChannel);
}

event OnOnlinePartyCommand(string Command, Name CommandChannel, Hat_GhostPartyPlayerStateBase Sender) {
	local int i;
	local array<string> CommandInfo;

	CommandInfo = SplitString(String(CommandChannel), "+");

	if(CommandInfo.Length < 3 || GetTeamCode() != CommandInfo[0]) return;
	if(CommandInfo[1] != class'Yoshi_SyncItem'.static.GetCommandChannel()) return;

	for(i = 0; i < Syncs.length; i++) {
		if(CommandInfo[2] ~= string(Syncs[i].class)) {
			Syncs[i].OnReceiveSync(Command);
		}
	}
}

event OnModLoaded() {
    //TODO: Setup Syncs
}

event OnConfigChanged(Name ConfigName) {
	//TODO: Figure Out Configs / HUD?
}

event OnModUnloaded() {
	Syncs.Length = 0;
}

//I dislike using a Tick function on this but sadly some things just lack the necesssary functions to track in any other fashion.
simulated event Tick(float delta) {
    local MaterialInstanceConstant GenMat;
    local int UpdateVersion;
    local String LevelBitID;
    local Actor a;
    local Hat_Player ply;
    local int i;
    local int j;
    local string s;
    local LinearColor TeamColor;
    if(`GameManager.GetCurrentMapFilename() == `GameManager.TitlescreenMapName) return;

    ply = Hat_Player(class'Engine'.static.GetEngine().GamePlayers[0].Actor.Pawn);
    
    //Chest Section
    if(SyncGeneralCollectibles == 0) {
        foreach ChestActors(a) {
            UpdateVersion = 0;
            if(Hat_TreasureChest_Base(a) != None) {
                UpdateVersion = Hat_TreasureChest_Base(a).UpdateVersion;
            }
            LevelBitID = class'Hat_SaveBitHelper'.static.GetBitId(a, UpdateVersion);
            if(class'Hat_SaveBitHelper'.static.HasLevelBit(LevelBitID, 1)) {
                Print("Sending Chest Open with Command " $ a.default.class $ "+" $ LevelBitID $ "+" $ `GameManager.GetCurrentMapFilename());
                PrepareOnlinePartyCommand(a.default.class $ "+" $ LevelBitID $ "+" $ `GameManager.GetCurrentMapFilename(), class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSChest, ply);
                ChestActors.RemoveItem(a);
            }

        }
    }

    //Ziplines / Bonfires
    if(SyncLevelEvents == 0) {
        foreach ProgressionActors(a) {
            LevelBitID = class'Hat_SaveBitHelper'.static.GetBitId(a);
            if(class'Hat_SaveBitHelper'.static.HasLevelBit(LevelBitID, 1)) {
                Print("Sending Progression Event with Command " $ a.default.class $ "+" $ LevelBitID $ "+" $ `GameManager.GetCurrentMapFilename());
                PrepareOnlinePartyCommand(a.default.class $ "+" $ LevelBitID $ "+" $ `GameManager.GetCurrentMapFilename(), class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSProgression, ply);
                ProgressionActors.RemoveItem(a);
            }
        }

        if(class'Hat_SaveBitHelper'.static.HasLevelBit("actless_freeroam_intro_complete", 1) && !isAlpineIntroComplete) {
            isAlpineIntroComplete = true;
            Print("Sending Alpine Intro Complete Event with Command " $ "actless_freeroam_intro_complete" $ "+" $ `GameManager.GetCurrentMapFilename());
            PrepareOnlinePartyCommand("actless_freeroam_intro_complete" $ "+" $ `GameManager.GetCurrentMapFilename(), class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSAlpineIntro, ply);
        }
    }

    //Player Inventory Section (Cosmetics)
    AddItemQueue.Length = 0;
    if(SyncCosmetics == 0 || SyncGeneralCollectibles == 0) {
        CheckForLoadoutBackpackItemDifferences(PlayerInventory.Hats, GetBackpack().Hats);
        CheckForBackpackItemDifferences(PlayerInventory.Badges, GetBackpack().Badges);
        CheckForBackpackItemDifferences(PlayerInventory.Skins, GetBackpack().Skins);
        CheckForBackpackItemDifferences(PlayerInventory.Remixes, GetBackpack().Remixes);
        CheckForBackpackItemDifferences(PlayerInventory.Filters, GetBackpack().Filters);
        CheckForBackpackItemDifferences(PlayerInventory.Weapons, GetBackpack().Weapons);
        for(i = 0; i < AddItemQueue.Length; i++) {

            //Check for Non-Cosmetic Hats which shouldn't sync
            if(Hat_LoadoutBackpackItem(AddItemQueue[i]) != None && 
            class'Hat_Loadout'.static.IsClassHat(AddItemQueue[i].BackpackClass) && 
            Hat_LoadoutBackpackItem(AddItemQueue[i]).ItemQualityInfo == None) continue;
            
            //Check for Non-Cruise/Non-Nyakuza Badges which already sync
            if(class'Hat_Loadout'.static.IsClassBadge(AddItemQueue[i].BackpackClass) &&
            class<Hat_Ability_Mirror>(AddItemQueue[i].BackpackClass) == None && 
            class<Hat_Ability_Nostalgia>(AddItemQueue[i].BackpackClass) == None &&
            class<Hat_Ability_PeacefulBadge>(AddItemQueue[i].BackpackClass) == None &&
            class<Hat_Ability_RedtroVR>(AddItemQueue[i].BackpackClass) == None &&
            class<Hat_Ability_RetroHandheld>(AddItemQueue[i].BackpackClass) == None) continue;

            //By this point all remaining collectibles *should* be new and not yet synced
            s = "";
            s $= AddItemQueue[i].BackpackClass.default.class;
            s $= Hat_LoadoutBackpackItem(AddItemQueue[i]) != None ? "+" $ String(Hat_LoadoutBackpackItem(AddItemQueue[i]).ItemQualityInfo.default.class) : "+";
            //Print("Sending Backpack Collect with Command " $ s);
            if(SyncCosmetics == 0 || class'Hat_Loadout'.static.IsClassBadge(AddItemQueue[i].BackpackClass) || class<Hat_Weapon_Umbrella>(AddItemQueue[i].BackpackClass) != None) { //We check for badges because General Collectibles needs to access them here
                Print("Sending Backpack Change with Command " $ s);
                PrepareOnlinePartyCommand(s, class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSBackpack, ply);
            }

            if(default.DebugMode) {
                GenMat = new class'MaterialInstanceConstant';
                GenMat.SetParent(CollectibleMaterial);
                TeamColor = GetTeamColor();
                GenMat.SetVectorParameterValue('TeamColor', TeamColor);
                GenMat.SetTextureParameterValue('Diffuse', GetTextureByName(Hat_LoadoutBackpackItem(AddItemQueue[i]) != None ? String(Hat_LoadoutBackpackItem(AddItemQueue[i]).ItemQualityInfo.default.class) : String(AddItemQueue[i].BackpackClass.default.class)));
                SpawnParticle(GeneralParticle, GenMat, 0.25);
            }
        }

    }

    //Death Wish Stamps Section
    if(!class'Hat_SnatcherContract_DeathWish'.static.IsAnyActive(true)) return;

    if(CurrentDeathWishes.Length > 0 && SyncDeathWishStamps == 0) {
        for(j = 0; j < CurrentDeathWishes.Length; j++) {
            for(i = 0; i < CurrentDeathWishes[j].DeathWish.default.Objectives.Length; i++) {
                if(CurrentDeathWishes[j].ObjectivesComplete[i]) continue;

                if(CurrentDeathWishes[j].DeathWish.static.IsObjectiveCompleted(i) && !CurrentDeathWishes[j].InitialObjectivesComplete[i] && !CurrentDeathWishes[j].ObjectivesComplete[i]) {
                    CurrentDeathWishes[j].ObjectivesComplete[i] = true;
                    s = "";
                    //Print("Collected a new Death Wish Stamp!");
                    s $= CurrentDeathWishes[j].DeathWish.default.class $ "+" $ i;
                    Print("Sending Death Wish Stamp with Command " $ s);
                    PrepareOnlinePartyCommand(s, class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSDeathWish, ply);
                }
            }
        }
    }
}

//Checking my Backpack vs. the game's Backpack
function CheckForBackpackItemDifferences(out array<Hat_BackpackItem> OriginalItems, array<Hat_BackpackItem> CurrentItems) {
    local int i;
    if(OriginalItems.Length >= CurrentItems.Length) return;

    for(i = 0; i < CurrentItems.Length; i++) {
        if(OriginalItems.Find(CurrentItems[i]) == -1) {
            AddItemQueue.AddItem(CurrentItems[i]);
            OriginalItems.AddItem(CurrentItems[i]);
        }
    }
}

//Checking specifically for Hat Flairs
function CheckForLoadoutBackpackItemDifferences(out array<Hat_LoadoutBackpackItem> OriginalItems, array<Hat_LoadoutBackpackItem> CurrentItems) {
    local int i;
    if(OriginalItems.Length >= CurrentItems.Length) return;

    for(i = 0; i < CurrentItems.Length; i++) {
        if(OriginalItems.Find(CurrentItems[i]) == -1) {
            AddItemQueue.AddItem(CurrentItems[i]);
            OriginalItems.AddItem(CurrentItems[i]);
        }
    }
}

function BackpackInfo2017 GetBackpack() {
    return class'Hat_Loadout'.static.GetSaveGame().MyBackpack2017;
}

//This function will always run through regardless of Config settings. Just in case they switch them mid-level, the arrays will still be relevant.
//Hooks necessary level bit actors, gets Death Wishes, and grabs our initial inventory
function OnPostInitGame() {
    local array< class<Hat_SnatcherContract_DeathWish> > ActiveDeathWishes;
    local class<Hat_SnatcherContract_DeathWish> DW;
    local DeathWishLevelBitSet DeathWishBits;
    local int i;

    if(class'Hat_SaveBitHelper'.static.HasLevelBit("actless_freeroam_intro_complete", 1)) {
        isAlpineIntroComplete = true;
    }

    if(`GameManager.GetCurrentMapFilename() == `GameManager.TitlescreenMapName) return;
    HookActorSpawn(class'Hat_TreasureChest_Base', 'Hat_TreasureChest_Base');
    HookActorSpawn(class'Hat_SandStationHorn_Base', 'Hat_SandStationHorn_Base');
    HookActorSpawn(class'Hat_Bonfire_Base', 'Hat_Bonfire_Base');

    PlayerInventory = GetBackpack();

    if(!class'Hat_SnatcherContract_DeathWish'.static.IsAnyActive(true)) return;

    ActiveDeathWishes = class'Hat_SnatcherContract_DeathWish'.static.GetActiveDeathWishes();
    foreach ActiveDeathWishes(DW) {
        if(DW.static.IsContractPerfected()) continue;
        DeathWishBits.DeathWish = DW;

        DeathWishBits.ObjectivesComplete.Length = 0;
        DeathWishBits.InitialObjectivesComplete.Length = 0;
        for(i = 0; i < DW.default.Objectives.Length; i++) {
            DeathWishBits.ObjectivesComplete.AddItem(DW.static.IsObjectiveCompleted(i));
            DeathWishBits.InitialObjectivesComplete.AddItem(DW.static.IsObjectiveCompleted(i));
        }
        CurrentDeathWishes.AddItem(DeathWishBits);
    }
}

//You already know what this does, don't you?
event OnHookedActorSpawn(Object NewActor, Name Identifier) {
    local string LevelBitID;

    if(Identifier == 'Hat_TreasureChest_Base') {
        LevelBitID = class'Hat_SaveBitHelper'.static.GetBitId(NewActor, Hat_TreasureChest_Base(NewActor).UpdateVersion);
        if(!class'Hat_SaveBitHelper'.static.HasLevelBit(LevelBitID, 1)) {
            ChestActors.AddItem(Actor(NewActor));
        }
    }

    if(Identifier == 'Hat_SandStationHorn_Base') {
        LevelBitID = class'Hat_SaveBitHelper'.static.GetBitId(NewActor);
        if(!class'Hat_SaveBitHelper'.static.HasLevelBit(LevelBitID, 1)) {
            ProgressionActors.AddItem(Actor(NewActor));
        }
    }

    if(Identifier == 'Hat_Bonfire_Base') {
        LevelBitID = class'Hat_SaveBitHelper'.static.GetBitId(NewActor);
        if(!class'Hat_SaveBitHelper'.static.HasLevelBit(LevelBitID, 1)) {
            ProgressionActors.AddItem(Actor(NewActor));
        }
    }
}

//Controls the bulk of collectibles, since it you know, tracks collectibles being collected (that's a lot of collection)
function OnCollectedCollectible(Object InCollectible) {
    local MaterialInstanceConstant GenMat;
    local Hat_Player ply;
    local String s;
    local LinearColor TeamColor;
    ply = Hat_Player(class'Engine'.static.GetEngine().GamePlayers[0].Actor.Pawn);

    s = "MessaseSoItWontComplain :)";
    if(Hat_Collectible_EnergyBit(InCollectible) != None && SyncPons == 0) {
        //Print("Sending Pon"); //Sorry but this one really is not worth it lol
        PrepareOnlinePartyCommand(s, class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSPon, ply);
    }

    if((Hat_Collectible_BadgePart(InCollectible) != None || 
    Hat_Collectible_InstantCamera(InCollectible) != None || 
    Hat_Collectible_BadgeSlot(InCollectible) != None || 
    Hat_Collectible_BadgeSlot2(InCollectible) != None || 
    Hat_Collectible_RouletteToken(InCollectible) != None ||
    Hat_Collectible_MetroTicket_Base(InCollectible) != None) && SyncGeneralCollectibles == 0) {

        if(Hat_Collectible_BadgePart_Scooter_Subcon(InCollectible) != None) return; //No Rental Badges in this house!!!

        s = String(Hat_Collectible_Important(InCollectible).default.class) $ "+" $ Hat_Collectible_Important(InCollectible).OnCollectLevelBit.Id $ "+" $ 
        Hat_Collectible_Important(InCollectible).OnCollectLevelBit.Bits $ "+" $ `GameManager.GetCurrentMapFilename();
        Print("Sending General Collectible with Command " $ s);
        PrepareOnlinePartyCommand(s, class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSGeneral, ply);
    }
    
    if(Hat_Collectible_Sticker(InCollectible) != None && SyncCosmetics == 0 && !Hat_Collectible_Sticker(InCollectible).IsHolo) {
        s = String(Hat_Collectible_Sticker(InCollectible).default.class) $ "+" $ Hat_Collectible_Sticker(InCollectible).OnCollectLevelBit.Id $ "+" $
        Hat_Collectible_Sticker(InCollectible).OnCollectLevelBit.Bits $ "+" $ `GameManager.GetCurrentMapFilename();
        Print("Sending Sticker with Command " $ s);
        PrepareOnlinePartyCommand(s, class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSSticker, ply);
    }

    if(Hat_Collectible_Decoration(InCollectible) != None && SyncGeneralCollectibles == 0) {
        s = String(Hat_Collectible_Decoration(InCollectible).default.class) $ "+" $ Hat_Collectible_Decoration(InCollectible).OnCollectLevelBit.Id $
        "+" $ Hat_Collectible_Decoration(InCollectible).OnCollectLevelBit.Bits $  "+" $ `GameManager.GetCurrentMapFilename();
        Print("Sending Relic with Command " $ s); //Keep in mind the relic ONLY matters if it's the Burger Top
        PrepareOnlinePartyCommand(s, class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSRelic, ply);

        //UpdateDecorationStands();
    }

    if(default.DebugMode) {
        GenMat = new class'MaterialInstanceConstant';
        GenMat.SetParent(CollectibleMaterial);
        TeamColor = GetTeamColor();
        GenMat.SetVectorParameterValue('TeamColor', TeamColor);
        GenMat.SetTextureParameterValue('Diffuse', GetTextureByName(String(InCollectible.default.class)));
        SpawnParticle(GeneralParticle, GenMat, 0.25);
    }
}

//Added functionality for team specification within the command channel
function PrepareOnlinePartyCommand(string Command, Name CommandChannel, optional Pawn SendingPlayer, optional Hat_GhostPartyPlayerStateBase Receiver) {
    CommandChannel = Name(GetTeamCode() $ "+" $ CommandChannel);
    SendOnlinePartyCommand(Command, CommandChannel, SendingPlayer, Receiver);
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

//Our hub of operation, takes requests from around the world and turns them into material things!
event OnOnlinePartyCommand(string Command, Name CommandChannel, Hat_GhostPartyPlayerStateBase Sender) {
    local Array<String> arr;
    local Array<String> CommandInfo;
    local int i;
    local Hat_Player ply;
    local Hat_PlayerController PC;
    local Hat_Collectible_Important BP;
    local MaterialInstanceConstant GenMat;
    local class<Hat_SnatcherContract_DeathWish> DW;
    local class<Object> BackpackClass;
    local LinearColor TeamColor;

    if(`GameManager.GetCurrentMapFilename() == `GameManager.TitlescreenMapName) return;
    ply = Hat_Player(class'Engine'.static.GetEngine().GamePlayers[0].Actor.Pawn);
    PC = Hat_PlayerController(ply.Controller);
    arr = SplitString(Command, "+");
    CommandInfo = SplitString(String(CommandChannel), "+");

    //Determine Team Info
    if(CommandInfo.Length >= 2) {
        if(GetTeamCode() != CommandInfo[0]) { //This also includes None teams
            return;
        }
    }
    else {
        return;
    }

    TeamColor = GetTeamColor();
    CommandChannel = Name(CommandInfo[1]); //Wanted to be lazy, the information is already in CommandInfo anyways

    //Source file not included for privacy of CommandChannels
    if(CommandChannel == class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSTimePiece && SyncTimePieces == 0) {
        Print("Received Time Piece with Command " $ Command);
        if(`GameManager.HasTimePiece(arr[0])) return;

        GenMat = new class'MaterialInstanceConstant';
        GenMat.SetParent(CollectibleMaterial);
        GenMat.SetVectorParameterValue('TeamColor', TeamColor);
        GenMat.SetTextureParameterValue('Diffuse', Texture2D'HatInTime_Hud.Textures.Collectibles.collectible_timepiece');
        SpawnParticle(GeneralParticle, GenMat);

        BlockTimePiece = true; //Otherwise an infinite loop of OP Commands occurs
        `GameManager.GiveTimePiece(arr[0], 1 == int(arr[1]));

        UpdatePowerPanels();
        //UpdateDecorationStands();
    }

    if(CommandChannel == class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSDeathWish && SyncDeathWishStamps == 0) {
        Print("Received Death Wish Stamp with Command " $ Command);
        DW = class<Hat_SnatcherContract_DeathWish>(class'Hat_ClassHelper'.static.ClassFromName(arr[0]));
        if(DW.static.IsContractPerfected() || DW.static.IsObjectiveCompleted(int(arr[1]))) return;

        GenMat = new class'MaterialInstanceConstant';
        GenMat.SetParent(CollectibleMaterial);
        GenMat.SetVectorParameterValue('TeamColor', TeamColor);
        GenMat.SetTextureParameterValue('Diffuse', Texture2D'HatInTime_Hud_DeathWish.UI_Deathwish_Activated2');
        SpawnParticle(GeneralParticle, GenMat);
        class'Hat_SaveBitHelper'.static.AddLevelBit(DW.static.GetObjectiveBitID(), int(arr[1])+1, DW.default.ObjectiveMapName);
    }

    if(CommandChannel == class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSPon && SyncPons == 0) {
        `GameManager.AddEnergyBits(1);
    }

    if((CommandChannel == class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSGeneral && SyncGeneralCollectibles == 0) || (CommandChannel == class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSSticker && SyncCosmetics == 0)) {
        Print("Received a General Collectible with Command " $ Command);
        if(arr[1] != "" && class'Hat_SaveBitHelper'.static.HasLevelBit(arr[1], Max(int(arr[2]), 1), arr[3])) return; //If we already have this level bit, they don't get a dupe.

        BP = `GameManager.Spawn(class<Hat_Collectible_Important>(class'Hat_ClassHelper'.static.ClassFromName(arr[0])),,,Vect(1000000,1000000,1000000));
        BP.GiveCollectible(ply);
        BP.Destroy();

        if(arr[0] ~= "Hat_Collectible_BadgeSlot" || arr[0] ~= "Hat_Collectible_BadgeSlot2") {
            `GameManager.AddBadgeSlots(1);
        }

        GenMat = new class'MaterialInstanceConstant';
        GenMat.SetParent(CollectibleMaterial);
        GenMat.SetVectorParameterValue('TeamColor', TeamColor);
        GenMat.SetTextureParameterValue('Diffuse', GetTextureByName(arr[0]));
        SpawnParticle(GeneralParticle, GenMat, 0.25);

        if(arr[1] != "") {
            class'Hat_SaveBitHelper'.static.AddLevelBit(arr[1], Max(int(arr[2]), 1), arr[3]);
            if(`GameManager.GetCurrentMapFilename() ~= arr[3]) {
                DestroyCollectible(arr[1]);
                UpdateActorStatus(arr[1]); //Some containers give their level bits to their collectibles
            }
        }
        
    }

    if(CommandChannel == class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSRelic && SyncGeneralCollectibles == 0) {
        Print("Received Relic with Command " $ Command);
        if(arr[1] != "" && class'Hat_SaveBitHelper'.static.HasLevelBit(arr[1], Max(int(arr[2]), 1), arr[3])) return;

        i = GetDecorationPriorityIndex(ply);
        GenMat = new class'MaterialInstanceConstant';
        GenMat.SetParent(CollectibleMaterial);
        if(class<Hat_Collectible_Decoration_BurgerTop>(class'Hat_ClassHelper'.static.ClassFromName(arr[0])) != None) { //We have to treat the Cooking Cat relic separately
        
            //Still need to do decoration checks to see if we already have it
            if (PC.GetLoadout().HasCollectible(class'Hat_Collectible_Decoration_BurgerTop', 1, false)) return;
            if (class'Hat_SeqCond_IsDecorationPlaced'.static.GetResult(class'Hat_Collectible_Decoration_BurgerTop', class'WorldInfo'.static.GetWorldInfo().NetMode != NM_Standalone)) return;
            
            PC.GetLoadout().AddCollectible(class'Hat_Collectible_Decoration_BurgerTop', 1);
            GenMat.SetVectorParameterValue('TeamColor', TeamColor);
            GenMat.SetTextureParameterValue('Diffuse', GetTextureByName(String(class'Hat_Collectible_Decoration_BurgerTop'.default.class)));
            SpawnParticle(GeneralParticle, GenMat, 0.25);
        }
        else if(i == INDEX_NONE) {
            PC.GetLoadout().AddCollectible(class'Hat_Collectible_RouletteToken', 1);
            GenMat.SetVectorParameterValue('TeamColor', TeamColor);
            GenMat.SetTextureParameterValue('Diffuse', GetTextureByName(String(class'Hat_Collectible_RouletteToken'.default.class)));
            SpawnParticle(GeneralParticle, GenMat, 0.25);
        }
        else {
            PC.GetLoadout().AddCollectible(DecorationPriorities[i], 1);
            GenMat.SetVectorParameterValue('TeamColor', TeamColor);
            GenMat.SetTextureParameterValue('Diffuse', GetTextureByName(String(DecorationPriorities[i].default.class)));
            SpawnParticle(GeneralParticle, GenMat, 0.25);
        }
        
        if(arr[1] != "") {
            class'Hat_SaveBitHelper'.static.AddLevelBit(arr[1], Max(int(arr[2]), 1), arr[3]);
            if(`GameManager.GetCurrentMapFilename() ~= arr[3]) {
                DestroyCollectible(arr[1]);
                UpdateActorStatus(arr[1]); //Some Containers pass on their level bits to their collectibles
            }
        }

        //UpdateDecorationStands();
        
    }

    if(CommandChannel == class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSBackpack && SyncCosmetics == 0) {
        Print("Received Backpack Collect with Command " $ Command);
        BackpackClass = class'Hat_ClassHelper'.static.ClassFromName(arr[0]);
        if((class<Hat_Ability_Sprint>(BackpackClass) != None && class'Hat_Loadout'.static.BackpackHasHatClass(class'Hat_Ability_Sprint', false) == INDEX_NONE) ||
        (class<Hat_Ability_Chemical>(BackpackClass) != None && class'Hat_Loadout'.static.BackpackHasHatClass(class'Hat_Ability_Chemical', false) == INDEX_NONE) ||
        (class<Hat_Ability_FoxMask>(BackpackClass) != None && class'Hat_Loadout'.static.BackpackHasHatClass(class'Hat_Ability_FoxMask', false) == INDEX_NONE) ||
        (class<Hat_Ability_StatueFall>(BackpackClass) != None && class'Hat_Loadout'.static.BackpackHasHatClass(class'Hat_Ability_StatueFall', false) == INDEX_NONE) ||
        (class<Hat_Ability_TimeStop>(BackpackClass) != None && class'Hat_Loadout'.static.BackpackHasHatClass(class'Hat_Ability_TimeStop', false) == INDEX_NONE)) {
            //Print("Did not have the required hat!");
            return;
        }

        if(PC.GetLoadout().BackpackHasInventory(class<Actor>(BackpackClass), false, class<Hat_CosmeticItemQualityInfo>(class'Hat_ClassHelper'.static.ClassFromName(arr[1])))) {
            return;
        }

        if(!PC.GetLoadout().AddBackpack(class'Hat_Loadout'.static.MakeLoadoutItem(BackpackClass, class<Hat_CosmeticItemQualityInfo>(class'Hat_ClassHelper'.static.ClassFromName(arr[1]))), true)) {
            //Print("Failed to add item!");
            return;
        }

        //Print("Succeeded in adding item");
        GenMat = new class'MaterialInstanceConstant';
        GenMat.SetParent(CollectibleMaterial);
        GenMat.SetVectorParameterValue('TeamColor', TeamColor);
        GenMat.SetTextureParameterValue('Diffuse', GetTextureByName(arr[1] != "" ? arr[1] : arr[0]));
        SpawnParticle(GeneralParticle, GenMat, 0.25);
        `SaveManager.SaveToFile();
    }

    if((CommandChannel == class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSChest && SyncGeneralCollectibles == 0) || (CommandChannel == class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSProgression && SyncLevelEvents == 0)) {
        Print("Received Chest Open or Progression Event with Command " $ Command);
        if(arr[1] != "" && class'Hat_SaveBitHelper'.static.HasLevelBit(arr[1], 1, arr[2])) return;

        if(arr[1] != "") {
            class'Hat_SaveBitHelper'.static.AddLevelBit(arr[1], 1, arr[2]);
            if(`GameManager.GetCurrentMapFilename() == arr[2]) {
                UpdateActorStatus(arr[0]);
            }

            if(CommandChannel == class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSProgression) {
                GenMat = new class'MaterialInstanceConstant';
                GenMat.SetParent(CollectibleMaterial);
                GenMat.SetVectorParameterValue('TeamColor', TeamColor);
                GenMat.SetTextureParameterValue('Diffuse', GetTextureByName(arr[0]));
                SpawnParticle(GeneralParticle, GenMat, 0.25);
            }
        }
    }

    if(CommandChannel == class'YoshiPrivate_OnlinePartySuperSync_Commands'.const.OPSSAlpineIntro && SyncLevelEvents == 0) {
        Print("Received Alpine Intro with Command " $ Command);
        if(arr[0] != "" && class'Hat_SaveBitHelper'.static.HasLevelBit(arr[0], 1, arr[2])) return;
        class'Hat_SaveBitHelper'.static.AddLevelBit(arr[0], 1, arr[1]);
        GenMat = new class'MaterialInstanceConstant';
        GenMat.SetParent(CollectibleMaterial);
        GenMat.SetVectorParameterValue('TeamColor', TeamColor);
        GenMat.SetTextureParameterValue('Diffuse', GetTextureByName("Hat_SandStationHorn_Base"));
        SpawnParticle(GeneralParticle, GenMat, 0.25);
    }
}

//Makes the cool icon that shows up when you get a sync
function SpawnParticle(ParticleSystem P, optional MaterialInterface MI, optional float ParticleScale = 0.5) {
	local ParticleSystemComponent psc;
    local Hat_Player ply;

    if(ShowSyncIcons == 0) {
        foreach DynamicActors(class'Hat_Player', ply) {
            if(P != None && ply.IsLocallyControlled()) {
                psc = class'WorldInfo'.static.GetWorldInfo().MyEmitterPool.SpawnEmitter(P, ply.Location + vect(0,0,30));
                if(MI != None) {
                    psc.SetMaterialParameter('CollectibleOverride', MI);
                }
		        psc.SetScale(ParticleScale);
            }
        }
    }
}

//Where we get the icon, if you ever see a ? then I missed an approach to find the HUDIcon
function Texture2D GetTextureByName(string Collectible) {
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

//Sometimes the Level Bit for a collectible was already set to 1 but it exists in the world still. So we just get rid of it. Goodbye!
function DestroyCollectible(string LevelBitID) {
    local Hat_Collectible_Important I;
    if(LevelBitID == "") return;
    foreach DynamicActors(class'Hat_Collectible_Important', I) {
        if(I.OnCollectLevelBit.ID == LevelBitID) {
            I.Destroy();
        }
    }
}

function UpdatePowerPanels() {
    local Hat_SpaceshipPowerPanel SPP;
    if(`GameManager.GetCurrentMapFilename() ~= `GameManager.HubMapName) {
        foreach DynamicActors(class'Hat_SpaceshipPowerPanel', SPP) {
            if(SPP.isA('Hat_SpaceshipPowerPanel')) {
                SPP.PostBeginPlay();
            }
        }
    }
}

function UpdateDecorationStands() {
    local Hat_DecorationStand DS;

    if(`GameManager.GetCurrentMapFilename() == `GameManager.HubMapName) {
        foreach DynamicActors(class'Hat_DecorationStand', DS) {
            if(DS.isA('Hat_DecorationStand')) {
                DS.UpdateVisibilityStatus();
            }
        }
    }
}

//When Actors have their Level Bits changed directly, you'll need to give them a nudge to make them do their thing
function UpdateActorStatus(string LevelBitID) {
    local int i;
    local Hat_ImpactInteract_Breakable_ChemicalBadge CB;
    local Hat_TreasureChest_Base TC;
    local Hat_Goodie_Vault_Base GV;
    local Hat_NPC_Bullied B;
    local Hat_Collectible_Important CI;
    local Hat_SandStationHorn_Base SSH;
    local Hat_Bonfire_Base BB;

    if(LevelBitID == "") return;

    //First we need to check to see if there's currently a collectible with this Level Bit that shouldn't exist
    foreach DynamicActors(class'Hat_Collectible_Important', CI) {
        if(class'Hat_SaveBitHelper'.static.GetBitId(CI) == LevelBitID) {
            CI.Destroy();
        }
    }
    
    foreach DynamicActors(class'Hat_SandStationHorn_Base', SSH) {
        if(class'Hat_SaveBitHelper'.static.GetBitId(SSH) == LevelBitID) {
            SSH.isActivated = true;
            for(i = 0; i < ArrayCount(SSH.TargetUnlocks); i++) {
                if(SSH.TargetUnlocks[i] != None) {
                    Hat_SandTravelNode(SSH.TargetUnlocks[i]).UpdateHookStatus();
                }
            }
            return;
        }
    }

    foreach DynamicActors(class'Hat_Bonfire_Base', BB) {
        if(class'Hat_SaveBitHelper'.static.GetBitId(BB) == LevelBitID) {
			BB.OnCompleted(true);
            return;
		}
    }

    foreach DynamicActors(class'Hat_ImpactInteract_Breakable_ChemicalBadge', CB) {
        if(class'Hat_SaveBitHelper'.static.GetBitId(CB) == LevelBitID) {
            CB.PostBeginPlay();
            return;
        }
    }

    foreach DynamicActors(class'Hat_TreasureChest_Base', TC) {
        if(class'Hat_SaveBitHelper'.static.GetBitId(TC) == LevelBitID) {
            TC.Empty();
            return;
        }
    }

    foreach DynamicActors(class'Hat_Goodie_Vault_Base', GV) {
        if(class'Hat_SaveBitHelper'.static.GetBitId(GV) == LevelBitID) {
            GV.RemoveContentAlreadyCollected();
            return;
        }
    }

    foreach DynamicActors(class'Hat_NPC_Bullied', B) {
		if(class'Hat_SaveBitHelper'.static.GetBitId(B) == LevelBitID) {
			B.RemoveRewardsAlreadyCollected();
			return;
		}
	}

    //Print("Did not find Container with Level Bit " $ LevelBitID);
}

//Relic functions to determine which to give the player
function bool IsValidDecoration(int i, Hat_Loadout lo)
{
	if (lo.HasCollectible(DecorationPriorities[i], 1, false)) return false;
	
	// Do not reward DLC relics
	if (DecorationPriorities[i].default.RequiredDLC != None && !class'Hat_GameDLCInfo'.static.IsGameDLCInfoInstalled(DecorationPriorities[i].default.RequiredDLC)) return false;
	
	// Do not reward already placed relics
	if (class'Hat_SeqCond_IsDecorationPlaced'.static.GetResult(DecorationPriorities[i], class'WorldInfo'.static.GetWorldInfo().NetMode != NM_Standalone)) return false;
	
	return true;
}

//Determines the next relic the player needs
simulated function int GetDecorationPriorityIndex(Actor Collector)
{
	local int i;
	local Hat_PlayerController pc;
	local Hat_Loadout lo;
	
	i = 0;
	
	if (Pawn(Collector) != None) Collector = Pawn(Collector).Controller;
	Pc = Hat_PlayerController(Collector);
    if (Pc == None) return INDEX_NONE;
	if (class'WorldInfo'.static.GetWorldInfo().WorldInfo.NetMode != NM_Standalone && Hat_Player(Collector) != None)
		lo = Hat_PlayerReplicationInfo(Hat_Player(Collector).PlayerReplicationInfo).MyLoadout;
	else
		lo = pc.GetLoadout();
	
	while (i < DecorationPriorities.Length && !IsValidDecoration(i, lo))
		i++;
	
	// No more relics to give, give Roulette Tokens instead
	if (i >= DecorationPriorities.Length)
		i = INDEX_NONE;
	
	return i;
}

//Probably uh, gives collectibles, maybe?
function GiveCollectible(String str, int amount)
{
	local class<Object> c;
	local Hat_PlayerController pc;
	pc = Hat_PlayerController(class'Hat_PlayerController'.static.GetPlayer1());

	c = class'Hat_ClassHelper'.static.ClassFromName(str);
	if (c == None)
	{
		//Print("Invalid class: " $ str);
		return;
	}
	
	pc.GetLoadout().AddCollectible(c, amount);
}

//Pretty sure I didn't even use this because I end up calling it directly lol
function class<Actor> InventoryClassFromName(String str)
{
	return class'Hat_ClassHelper'.static.InventoryClassFromName(str);
}

//I think the title says it all
simulated function AddToBackpack(class<Actor> i, optional class<Hat_CosmeticItemQualityInfo> ItemQualityInfo, optional bool equip = false)
{
	local Hat_PlayerController pc;
	pc = Hat_PlayerController(class'Hat_PlayerController'.static.GetPlayer1());
	
	if (Role != Role_Authority && WorldInfo.NetMode != NM_Standalone)
		Hat_Player(pc.Pawn).ServerAddToBackpack(i, ItemQualityInfo);
	else
		pc.GetLoadout().AddBackpack(class'Hat_Loadout'.static.MakeLoadoutItem(i, ItemQualityInfo), equip, ,Hat_Player(pc.Pawn));
}

//Debug tool to see what in the world my commands are actually sending
static function Print(string s)
{
    if(default.DebugMode) {
	    class'WorldInfo'.static.GetWorldInfo().Game.Broadcast(class'WorldInfo'.static.GetWorldInfo(), s);
    }

}

defaultproperties
{
    BlockTimePiece=false
    DebugMode=false

    DecorationPriorities.Add(class'Hat_Collectible_Decoration_BurgerBottom');
	DecorationPriorities.Add(class'Hat_Collectible_Decoration_TrainTracks');
	DecorationPriorities.Add(class'Hat_Collectible_Decoration_Train');
	DecorationPriorities.Add(class'Hat_Collectible_Decoration_UFO');
	DecorationPriorities.Add(class'Hat_Collectible_Decoration_ToyCowA');
	DecorationPriorities.Add(class'Hat_Collectible_Decoration_ToyCowB');
	DecorationPriorities.Add(class'Hat_Collectible_Decoration_ToyCowC');
	DecorationPriorities.Add(class'Hat_Collectible_Decoration_CrayonBox');
	DecorationPriorities.Add(class'Hat_Collectible_Decoration_CrayonBlue');
	DecorationPriorities.Add(class'Hat_Collectible_Decoration_CrayonGreen');
	DecorationPriorities.Add(class'Hat_Collectible_Decoration_CrayonRed');
	DecorationPriorities.Add(class'Hat_Collectible_Decoration_GoldNecklace');
	DecorationPriorities.Add(class'Hat_Collectible_Decoration_JewelryDisplay');
	DecorationPriorities.Add(class'Hat_Collectible_Decoration_CakeA');
	DecorationPriorities.Add(class'Hat_Collectible_Decoration_CakeTower');
	DecorationPriorities.Add(class'Hat_Collectible_Decoration_CakeB');
	DecorationPriorities.Add(class'Hat_Collectible_Decoration_CakeC');

    TimePieceParticle=ParticleSystem'Yoshi_OPSuperSync_Content.TimePiece_Sync'
    DeathWishStampParticle=ParticleSystem'Yoshi_OPSuperSync_Content.Yoshi_DeathWishStamp_Sync'
    RelicParticle=ParticleSystem'Yoshi_OPSuperSync_Content.Yoshi_Relic_Sync'
    GeneralParticle=ParticleSystem'Yoshi_OPSuperSync_Content.Yoshi_YarnType_Sync'
    CollectibleMaterial=MaterialInstanceConstant'Yoshi_OPSuperSync_Content.Yoshi_YarnMaterial_Sync_INST'
}