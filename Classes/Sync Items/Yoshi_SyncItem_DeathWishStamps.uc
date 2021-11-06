class Yoshi_SyncItem_DeathWishStamps extends Yoshi_SyncItem;

struct OPSS_DeathWishBit {
	var class<Hat_SnatcherContract_DeathWish> Contract;
	var int ObjectiveID;
};

var array<OPSS_DeathWishBit> DeathWishBits;

function OnAdded() {
	Super.OnAdded();

	UpdateActiveDWs();
}

function Update(float delta) {
	local int i;

	if(DeathWishBits.length <= 0) {
		UpdateActiveDWs();
	}

	for(i = 0; i < DeathWishBits.length; i++) {
		if(DeathWishBits[i].Contract.static.IsObjectiveCompleted(DeathWishBits[i].ObjectiveID)) {
			Print("OPSS_DEATHWISH =>" @ `ShowVar(DeathWishBits[i].Contract) @ `ShowVar(DeathWishBits[i].ObjectiveID));

			DeathWishBits.Remove(i, 1);
		}
	}
}

function UpdateActiveDWs()
{
	local int i, j;
	local OPSS_DeathWishBit NewDWBit;
	
	DeathWishBits.length = 0;
	for (i = 0; i < `GameManager.DeathWishes.Length; i++)
	{
		for(j = 0; j < `GameManager.DeathWishes[i].default.Objectives.length; j++) {
			if(!`GameManager.DeathWishes[i].static.IsObjectiveCompleted(j)) {

				NewDWBit.Contract = `GameManager.DeathWishes[i].Class;
				NewDWBit.ObjectiveID = j;

				DeathWishBits.AddItem(NewDWBit);
			}
		}
	}
}