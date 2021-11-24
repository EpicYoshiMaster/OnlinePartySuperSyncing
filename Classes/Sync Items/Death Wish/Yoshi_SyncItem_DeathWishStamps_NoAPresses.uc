class Yoshi_SyncItem_DeathWishStamps_NoAPresses extends Yoshi_SyncItem_DeathWishStamps;

var string CollectedIdentifier;

//If we grab a time piece and the stamp ticks up, this identifier HAS to be the one for the stamp unless they're dumb and cheating
//The identifier will happen first and the stamp will be checked on the next frame
function OnTimePieceCollected(string Identifier) {
	CollectedIdentifier = Identifier;
}

defaultproperties
{
	//WhitelistedDeathWishes.Add(class'Hat_SnatcherContract_DeathWish_NoAPresses');
}