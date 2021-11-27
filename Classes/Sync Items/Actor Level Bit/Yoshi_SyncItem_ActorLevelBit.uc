class Yoshi_SyncItem_ActorLevelBit extends Yoshi_SyncItem
	abstract;

const ACTOR_BIT_HEADER = "actorlevelbits";

var const array< class<Actor> > ActorClasses;

var array<Actor> MapActors;
var bool ShouldCelebrateSync;
var string LocalizedNameKey;

function OnPostInitGame() {
	local Actor a;
	local string BitID;

	MapActors.length = 0;

	foreach class'WorldInfo'.static.GetWorldInfo().DynamicActors(class'Actor', a) {

		if(a != None && IsTrackableActor(a)) {
			BitID = class'Hat_SaveBitHelper'.static.GetBitID(a);
			if(!class'Hat_SaveBitHelper'.static.HasLevelBit(BitID, 1)) {
				MapActors.AddItem(a);
			}
		}
	}

	//Print("OPSS_ONPOSTINITGAME =>" @ `ShowVar(MapActors.length));
}

function bool IsTrackableActor(Actor a) {
	local int i;

	for(i = 0; i < ActorClasses.length; i++) {
		if(ClassIsChildOf(a.class, ActorClasses[i])) {
			return true;
		}
	}

	return false;
}

function Update(float delta) {
	local int i;
	local string BitID, SyncString;

	for(i = 0; i < MapActors.length; i++) {
		if(MapActors[i] == None) {
			MapActors.Remove(i, 1);
			i--;
			continue;
		}

		BitID = class'Hat_SaveBitHelper'.static.GetBitID(MapActors[i]);

		if(class'Hat_SaveBitHelper'.static.HasLevelBit(BitID, 1)) {

			SyncString = BitID $ "+" $ `GameManager.GetCurrentMapFilename();
			Sync(SyncString);

			if(ShouldCelebrateSync) {
				CelebrateSyncLocal(GetLocalization(MapActors[i].class), GetHUDIcon(MapActors[i].class));
			}
			
			MapActors.Remove(i, 1);
			i--;
		}
	}
}

function UpdateActors() {
	local int i;
	local string BitID;

	for(i = 0; i < MapActors.length; i++) {
		BitID = class'Hat_SaveBitHelper'.static.GetBitId(MapActors[i]);

		if(class'Hat_SaveBitHelper'.static.HasLevelBit(BitID, 1)) {
			SyncActor(MapActors[i]);
		}
	}
}

//Must be defined in subclasses, cast to your classes and do the function junk!! (I hate it too!!!)
function SyncActor(Actor a) {

}

static function string GetLocalization(optional Object SyncClass) {
	return Localize(ACTOR_BIT_HEADER, default.LocalizedNameKey, OPSS_LOCALIZATION_FILENAME);
}

function OnReceiveSync(string SyncString, Hat_GhostPartyPlayerStateBase Sender) {
	local array<string> arr;

	arr = SplitString(SyncString, "+");

	if(arr.length < 3) return;
	if(class'Hat_SaveBitHelper'.static.HasLevelBit(arr[0], 1, arr[1])) return;

	class'Hat_SaveBitHelper'.static.AddLevelBit(arr[0], 1, arr[1]);
	
	if(`GameManager.GetCurrentMapFilename() ~= arr[1]) {
		UpdateActors();
	}

	if(ShouldCelebrateSync) {
		CelebrateSync(Sender, GetLocalization(), GetHUDIcon());
	}
}

defaultproperties
{
	ShouldCelebrateSync=true
}