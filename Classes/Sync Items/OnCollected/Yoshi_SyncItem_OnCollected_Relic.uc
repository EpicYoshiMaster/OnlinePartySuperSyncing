class Yoshi_SyncItem_OnCollected_Relic extends Yoshi_SyncItem_OnCollected;

var const Array< class< Hat_Collectible_Decoration > > DecorationPriorities;

function OnReceiveSync(string SyncString, Hat_GhostPartyPlayerStateBase Sender) {
	local array<string> arr;
	local Hat_Player ply;
	local class<Hat_Collectible_Decoration> RelicClass;

	arr = SplitString(SyncString, "+");

	//Check for already obtained level bits
	if(HasLevelBit(arr[1], int(arr[2]), arr[3])) {
		return;
	}

	ply = Hat_Player(class'Engine'.static.GetEngine().GamePlayers[0].Actor.Pawn);
	RelicClass = GetNextRelic(class<Hat_Collectible_Decoration>(class'Hat_ClassHelper'.static.ClassFromName(arr[0])), ply);

	if(RelicClass != None) {
		Hat_PlayerController(ply.Controller).GetLoadout().AddCollectible(RelicClass);

		CelebrateSync(Sender, GetLocalization(RelicClass),GetHUDIcon(RelicClass));
	}
	else {
		Hat_PlayerController(ply.Controller).GetLoadout().AddCollectible(class'Hat_Collectible_RouletteToken');
		CelebrateSync(Sender, GetLocalization(class'Hat_Collectible_RouletteToken'),GetHUDIcon(class'Hat_Collectible_RouletteToken'));
	}
    
	AddLevelBit(arr[1], int(arr[2]), arr[3]);
}

//Relic functions to determine which to give the player
function bool IsValidDecoration(class<Hat_Collectible_Decoration> Relic, Hat_Loadout lo)
{
	if (lo.HasCollectible(Relic, 1, false)) return false;
	
	// Do not reward DLC relics
	if (Relic.default.RequiredDLC != None && !class'Hat_GameDLCInfo'.static.IsGameDLCInfoInstalled(Relic.default.RequiredDLC)) return false;
	
	// Do not reward already placed relics
	if (class'Hat_SeqCond_IsDecorationPlaced'.static.GetResult(Relic, class'WorldInfo'.static.GetWorldInfo().NetMode != NM_Standalone)) return false;
	
	return true;
}

//Determines the next relic the player needs
simulated function class<Hat_Collectible_Decoration> GetNextRelic(class<Hat_Collectible_Decoration> SyncedRelic, Actor Collector)
{
	local int i;
	local Hat_PlayerController pc;
	local Hat_Loadout lo;
	
	pc = Hat_PlayerController(Pawn(Collector).Controller);
	if (class'WorldInfo'.static.GetWorldInfo().WorldInfo.NetMode != NM_Standalone && Hat_Player(Collector) != None) {
		lo = Hat_PlayerReplicationInfo(Hat_Player(Collector).PlayerReplicationInfo).MyLoadout;
	}
	else if(pc != None) {
		lo = pc.GetLoadout();
	}

	if(SyncedRelic == class'Hat_Collectible_Decoration_BurgerTop') {
		if(IsValidDecoration(SyncedRelic, lo)) {
			return SyncedRelic;
		}
		else {
			return None;
		}
	} 
	
	i = 0;
	while (i < DecorationPriorities.Length && !IsValidDecoration(DecorationPriorities[i], lo))
		i++;
	
	// No more relics to give, give Roulette Tokens instead
	if (i >= DecorationPriorities.Length) {
		return None;
	}
	
	return DecorationPriorities[i];
}

static function bool ShouldBeEnabled() {
	return class'Yoshi_OnlinePartySuperSync_GameMod'.default.SyncGeneralCollectibles == 0;
}

defaultproperties
{
	WhitelistedCollectibles.Add(class'Hat_Collectible_Decoration');

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
}