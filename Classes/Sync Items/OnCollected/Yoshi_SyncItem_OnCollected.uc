//Generic class for syncs that involve the OnCollectedCollectible function to clean things up
class Yoshi_SyncItem_OnCollected extends Yoshi_SyncItem
	abstract;

var const array< class<Object> > WhitelistedCollectibles; //Use most general class of a collectible that can be handled here
var const array< class<Object> > BlacklistedCollectibles; //Use for subclasses of a Whitelisted Collectible that should not go through

function OnCollectedCollectible(Object InCollectible) {
	local int i;

	//Check whitelist
	for(i = 0; i < WhitelistedCollectibles.length; i++) {
		if(ClassIsChildOf(InCollectible.class, WhitelistedCollectibles[i])) {

			if(IsBlacklisted(InCollectible)) return;

			//We found a valid collectible!
			OnValidCollectible(InCollectible);
			return;
		}
	}
}

function bool IsBlacklisted(Object InCollectible) {
	local int i;

	for(i = 0; i < BlacklistedCollectibles.length; i++) {
		if(ClassIsChildOf(InCollectible.class, WhitelistedCollectibles[i])) {
			return true;
		}
	}

	return false;
}

function OnValidCollectible(Object InCollectible) {
	local string collectibleString;

	//Send the class, then the level bit, then the map
	collectibleString = InCollectible.class $ "+" $ GetLevelBitId(InCollectible) $ "+" $ GetLevelBitValue(InCollectible) $ "+" $ `GameManager.GetCurrentMapFilename();
	Sync(collectibleString);
}

function OnReceiveSync(string SyncString, Hat_GhostPartyPlayerStateBase Sender) {
	local array<string> arr;
	local Hat_Player ply;
	local Hat_Collectible_Important SpawnedCollectible;

	arr = SplitString(SyncString, "+");

	//Check for already obtained level bits
	if(HasLevelBit(arr[1], int(arr[2]), arr[3])) {
		return;
	}

	ply = Hat_Player(class'Engine'.static.GetEngine().GamePlayers[0].Actor.Pawn);

	//Spawn the collectible in, give it to the player, then say GOODBYE
	SpawnedCollectible = `GameManager.Spawn(class<Hat_Collectible_Important>(class'Hat_ClassHelper'.static.ClassFromName(arr[0])),,,Vect(1000000,1000000,1000000));
    SpawnedCollectible.GiveCollectible(ply);
    SpawnedCollectible.Destroy();

    if(arr[0] ~= "Hat_Collectible_BadgeSlot" || arr[0] ~= "Hat_Collectible_BadgeSlot2") {
        `GameManager.AddBadgeSlots(1);
    }

	CelebrateSync(Sender,"COLLECTIBLE ITEM NAME",GetTextureByName(arr[0]));
	AddLevelBit(arr[1], int(arr[2]), arr[3]);
}

function bool HasLevelBit(string ID, int Value, string MapName) {
	if(ID == "") return false;

	Value = Max(Value, 1);

	return class'Hat_SaveBitHelper'.static.HasLevelBit(ID, Value, MapName);
}

function AddLevelBit(string ID, int Value, string MapName) {
	Value = Max(Value, 1);

	//BUG: Collectible is not being destroyed sometimes?
	if(ID != "") {
        class'Hat_SaveBitHelper'.static.AddLevelBit(ID, Value, MapName);
        if(`GameManager.GetCurrentMapFilename() ~= MapName) {
            DestroyCollectible(ID);
            UpdateActorStatus(ID); //Some containers give their level bits to their collectibles
        }
    }
}

//Sometimes the Level Bit for a collectible was already set to 1 but it exists in the world still. So we just get rid of it. Goodbye!
function DestroyCollectible(string LevelBitID) {
    local Hat_Collectible_Important I;
    if(LevelBitID == "") return;
    foreach GameMod.DynamicActors(class'Hat_Collectible_Important', I) {
        if(I.OnCollectLevelBit.ID == LevelBitID) {
            I.Destroy();
        }
    }
}

//FIX THIS UNGODLY MESS SOMETIME PLEASE
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

    if(LevelBitID == "" || GameMod == None) return;

    //First we need to check to see if there's currently a collectible with this Level Bit that shouldn't exist
    foreach GameMod.DynamicActors(class'Hat_Collectible_Important', CI) {
        if(class'Hat_SaveBitHelper'.static.GetBitId(CI) == LevelBitID) {
            CI.Destroy();
        }
    }
    
    foreach GameMod.DynamicActors(class'Hat_SandStationHorn_Base', SSH) {
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

    foreach GameMod.DynamicActors(class'Hat_Bonfire_Base', BB) {
        if(class'Hat_SaveBitHelper'.static.GetBitId(BB) == LevelBitID) {
			BB.OnCompleted(true);
            return;
		}
    }

    foreach GameMod.DynamicActors(class'Hat_ImpactInteract_Breakable_ChemicalBadge', CB) {
        if(class'Hat_SaveBitHelper'.static.GetBitId(CB) == LevelBitID) {
            CB.PostBeginPlay();
            return;
        }
    }

    foreach GameMod.DynamicActors(class'Hat_TreasureChest_Base', TC) {
        if(class'Hat_SaveBitHelper'.static.GetBitId(TC) == LevelBitID) {
            TC.Empty();
            return;
        }
    }

    foreach GameMod.DynamicActors(class'Hat_Goodie_Vault_Base', GV) {
        if(class'Hat_SaveBitHelper'.static.GetBitId(GV) == LevelBitID) {
            GV.RemoveContentAlreadyCollected();
            return;
        }
    }

    foreach GameMod.DynamicActors(class'Hat_NPC_Bullied', B) {
		if(class'Hat_SaveBitHelper'.static.GetBitId(B) == LevelBitID) {
			B.RemoveRewardsAlreadyCollected();
			return;
		}
	}

    //Print("Did not find Container with Level Bit " $ LevelBitID);
}

function string GetLevelBitId(Object InCollectible) {
	local string bitID;

	if(Hat_Collectible_Important(InCollectible) != None) {
		bitID = Hat_Collectible_Important(InCollectible).OnCollectLevelBit.Id;
	}
	
	return bitID;
}

function int GetLevelBitValue(Object InCollectible) {
	local int bitValue;

	if(Hat_Collectible_Important(InCollectible) != None) {
		bitValue = Hat_Collectible_Important(InCollectible).OnCollectLevelBit.Bits;
	}
	
	return bitValue;
}