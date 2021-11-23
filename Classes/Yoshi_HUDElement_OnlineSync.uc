
class Yoshi_HUDElement_OnlineSync extends Hat_HUDElement;

const MAX_ROWS = 5;
const MAX_FADE_TIME = 0.5;

struct SyncRow {
	var Surface Icon;
	var string ItemName;
	var string MapName;
	var string PlayerName;

	var float FadeTime;
	var bool IsFadingIn;
	var bool IsFadingOut;

	structdefaultproperties
	{
		Icon=Texture2D'HatInTime_Hud_Loadout.Item_Icons.itemicon_unknown'
		ItemName="???"
		MapName="Unknown"
		PlayerName="Anonymous"
	}
};

var array<SyncRow> SyncRows;

var float HUDPosX;
var float HUDPosY;

var float MainTextOffset;
var float MainTextScale;
var Color DrawColor;

var float RowTextScale;
var float RowMatScale;
var float rowYStep;
var float texOffset;

function PushSync(Hat_GhostPartyPlayerStateBase state, string LocalizedItemName, Surface Icon) {
	local SyncRow NewSync;

	NewSync.PlayerName = state.GetDisplayName();
	NewSync.MapName = state.CurrentMapName;
	NewSync.ItemName = LocalizedItemName;
	NewSync.Icon = Icon;
	NewSync.IsFadingIn = true;

	SyncRows.AddItem(NewSync);

	while (SyncRows.length > MAX_ROWS) {
		if(!PopSync()) {
			break;
		}
	}
}

function bool PopSync() {
	local int i;
	if(SyncRows.length > 0) {

		for(i = 0; i < SyncRows.length; i++) {
			if(!SyncRows[i].IsFadingOut) {
				SyncRows[i].IsFadingOut = true;
				return true;
			}
		}
	}

	return false;
}

function bool Tick(HUD H, float delta)
{
	local int i;
    if(!Super.Tick(H, delta)) return false;

	for(i = 0; i < SyncRows.length; i++) {
		if(SyncRows[i].IsFadingIn || SyncRows[i].IsFadingOut) {
			SyncRows[i].FadeTime += delta;

			if(SyncRows[i].FadeTime >= MAX_FADE_TIME) {
				if(SyncRows[i].IsFadingOut) {
					SyncRows.Remove(i, 1);
					i--;
				}
				else {
					SyncRows[i].IsFadingIn = false;
				}
			}
		}
	}

	return true;
}

function bool Render(HUD H)
{
	local int i;
	local float posx, posy, scale, ystep;
    if(!Super.Render(H)) return false;
    if(Hat_HUD(H) != None && Hat_HUD(H).bForceHideHud) return false;
	if(SyncRows.length <= 0) return true;

	//Step 1: Draw Main Text
	posx = H.Canvas.ClipX * HUDPosX;
	posy = H.Canvas.ClipY * HUDPosY;

	scale = H.Canvas.ClipY * 0.01; //Base initial scaling on 1% of the screen
	
	H.Canvas.SetDrawColorStruct(default.DrawColor);
	H.Canvas.Font = class'Hat_FontInfo'.static.GetDefaultFont("Recent Syncs");
	DrawBorderedText(H.Canvas, "Recent Syncs", posx - scale * MainTextOffset, posy, scale * MainTextScale, true, TextAlign_Left,0.5,4.0);

	ystep = scale * rowYstep;

	posy += ystep * 2;

	//Step 2: Render Rows
	for(i = 0; i < SyncRows.length; i++) {

		//Set the Draw Color Alpha
		if(SyncRows[i].IsFadingIn) {
			DrawColor.A = Lerp(0.0, 255.0, (SyncRows[i].FadeTime / MAX_FADE_TIME));
		}
		else if(SyncRows[i].IsFadingOut) {
			DrawColor.A = Lerp(255.0, 0.0, (SyncRows[i].FadeTime / MAX_FADE_TIME));
		}
		else {
			DrawColor.A = default.DrawColor.A;
		}

		H.Canvas.SetDrawColorStruct(DrawColor);

		//Render the Item Name
		DrawTopLeftText(H.Canvas, SyncRows[i].ItemName, posx, posy, scale * RowTextScale, scale * RowTextScale);

		posy += ystep;

		//Render the Map Name
		DrawTopLeftText(H.Canvas, "in" @ SyncRows[i].MapName, posx, posy, scale * RowTextScale, scale * RowTextScale);

		posy += ystep;

		//Render the Player Name
		DrawTopLeftText(H.Canvas, "from" @ SyncRows[i].PlayerName, posx, posy, scale * RowTextScale, scale * RowTextScale);

		posy += ystep;

		//Render the Texture
		DrawBottomRight(H, posx - scale * texOffset, posy, scale * RowMatScale, scale * RowMatScale, SyncRows[i].Icon);

		posy += ystep;
	}
	
    return true;
}

defaultproperties
{
	HUDPosX=0.88
	HUDPosY=0.1
	MainTextOffset=5
	MainTextScale=0.075
	DrawColor=(R=255,G=255,B=255,A=255)

	RowTextScale=0.04
	RowMatScale=5

	texOffset=1
	rowYStep=2;

	SyncRows(0)=(Icon=Texture2D'HatInTime_Hud_ItemIcons.Misc.token_icon',ItemName="Roulette Token",MapName="Mafia Town",PlayerName="xXMafia_BossXDXx")
	SyncRows(1)=(Icon=Texture2D'HatInTime_Hud_Loadout.Item_Icons.itemicon_badge_sprint',ItemName="No Bonk Badge",MapName="Subcon Forest",PlayerName="#1 Snatcher Fan")
	SyncRows(2)=(Icon=Texture2D'HatInTime_Hud.Textures.Collectibles.collectible_timepiece',ItemName="Yellow Overpass Manhole",MapName="Nyakuza Metro",PlayerName="Timmy")
	SyncRows(3)=(Icon=Texture2D'HatInTime_Hud_ItemIcons.yarn.yarn_ui_timestop',ItemName="Time Stop Yarn",MapName="Alpine Skyline",PlayerName="The Twilight Bell is This Way")
	SyncRows(4)=(Icon=Texture2D'HatInTime_Hud_ItemIcons2.decoration_cake_a',ItemName="Relic",MapName="The Arctic Cruise",PlayerName="Egg")
}