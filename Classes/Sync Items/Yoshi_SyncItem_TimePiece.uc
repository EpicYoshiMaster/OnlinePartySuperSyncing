class Yoshi_SyncItem_TimePiece extends Yoshi_SyncItem;

var bool ShouldBlockTimePiece;

//Time Pieces are probably the simplest of them all.
function OnTimePieceCollected(string Identifier) {
    local String SyncString;
	local Hat_ChapterActInfo ActInfo;

	if(Identifier == "") return;

    if(ShouldBlockTimePiece) { 
		ShouldBlockTimePiece = false; 
		return; 
	}
	//TODO: Mod Collectibles include time pieces too!
    if(class'Hat_SnatcherContract_DeathWish'.static.IsAnyActive(false) || class'GameMod'.static.HasActiveLevelMod()) return;

	ActInfo = FindChapterActInfoForIdentifier(Identifier);

	CelebrateSyncLocal(GetLocalization(ActInfo), GetHUDIcon(ActInfo));

    SyncString = Identifier $ "+" $ ActInfo.IsBonus;

	Sync(SyncString);
}

function OnReceiveSync(string SyncString, Hat_GhostPartyPlayerStateBase Sender) {
	local array<string> arr;
	local Hat_ChapterActInfo ActInfo;

	arr = SplitString(SyncString, "+");

	if(`GameManager.HasTimePiece(arr[0])) return;

	ShouldBlockTimePiece = true; //Otherwise an infinite loop of OP Commands occurs
    `GameManager.GiveTimePiece(arr[0], bool(arr[1]));

	ActInfo = FindChapterActInfoForIdentifier(arr[0]);

	CelebrateSync(Sender, GetLocalization(ActInfo), GetHUDIcon());
	UpdatePowerPanels();
}

static function Hat_ChapterActInfo FindChapterActInfoForIdentifier(string Identifier) {
	local array<Hat_ChapterInfo> AllChapterInfo;
	local Hat_ChapterActInfo ActInfo;
	local int i, j;

	AllChapterInfo = class'Hat_ChapterInfo'.static.GetAllChapterInfo();

	for(i = 0; i < AllChapterInfo.length; i++) {
		AllChapterInfo[i].ConditionalUpdateActList();

		for(j = 0; j < AllChapterInfo[i].ChapterActInfo.length; j++) {
			if(AllChapterInfo[i].ChapterActInfo[j] == None) continue;

			if(AllChapterInfo[i].ChapterActInfo[j].HourGlass ~= Identifier) {
				ActInfo = AllChapterInfo[i].ChapterActInfo[j];
				Print("OPSS_CHAPTERACTINFO => Located:" @ `ShowVar(ActInfo));
				
				return ActInfo;
			}
		}
	}

	return None;
}

static function string GetLocalization(optional Object SyncClass) {
	local Hat_ChapterActInfo ChapterActInfoObject;

	ChapterActInfoObject = Hat_ChapterActInfo(SyncClass);

	if(ChapterActInfoObject != None) {
		return class'Hat_HUDMenuActSelect'.static.GetLocalizedActName(ChapterActInfoObject, 1);
	}

	return Super.GetLocalization(SyncClass);
}

static function Surface GetHUDIcon(optional Object SyncClass) {
	return Texture2D'HatInTime_Hud.Textures.Collectibles.collectible_timepiece';
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

static function bool ShouldBeEnabled() {
	return class'Yoshi_OnlinePartySuperSync_GameMod'.default.SyncTimePieces == 0;
}

defaultproperties
{
	ParticleScale=0.5
}