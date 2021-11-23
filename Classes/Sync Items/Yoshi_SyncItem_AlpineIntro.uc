class Yoshi_SyncItem_AlpineIntro extends Yoshi_SyncItem;

const ALPINE_INTRO_BIT_NAME = "actless_freeroam_intro_complete";
const ALPINE_MAP_NAME = "alpsandsails";

var bool AlreadyHasBit;

function OnAdded() {
	Super.OnAdded();

	if(HasAlpineIntroBit()) {
		AlreadyHasBit = true;
	}
}

function bool HasAlpineIntroBit() {
	return class'Hat_SaveBitHelper'.static.HasLevelBit(ALPINE_INTRO_BIT_NAME, 1, ALPINE_MAP_NAME);
}

function Update(float delta) {
	if(AlreadyHasBit) return;

	if(HasAlpineIntroBit()) {
		Sync(ALPINE_INTRO_BIT_NAME);
		AlreadyHasBit = true;

		Print("OPSS_LOCALIZE =>" @ `ShowVar(self.class) @ "Name: " @ GetLocalization() @ "Icon: " $ GetHUDIcon());
	}
}

static function string GetLocalization(optional Object SyncClass) {
	return Localize("UnrealEd", "MainMenu_ChangeAct_FreeRoam_Intro", "UnrealEd");
}

static function Surface GetHUDIcon(optional Object SyncClass) {
	return Texture2D'HatInTime_Hud_LocationBanner.Textures.vikinghorn';
}

function OnReceiveSync(string SyncString, Hat_GhostPartyPlayerStateBase Sender) {
	if(AlreadyHasBit) return;

	class'Hat_SaveBitHelper'.static.AddLevelBit(ALPINE_INTRO_BIT_NAME, 1, ALPINE_MAP_NAME);
	AlreadyHasBit = true;

	CelebrateSync(Sender, GetLocalization(), GetHUDIcon());
}