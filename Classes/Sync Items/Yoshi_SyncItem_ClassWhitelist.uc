
class Yoshi_SyncItem_ClassWhitelist extends Yoshi_SyncItem
	abstract;

var const array< class<Object> > WhitelistedCollectibles; //Use most general class of a collectible that can be handled here
var const array< class<Object> > BlacklistedCollectibles; //Use for subclasses of a Whitelisted Collectible that should not go through

function bool ShouldSync(Object InItem) {
	if(IsWhitelisted(InItem)) {
		return !IsBlacklisted(InItem);
	}

	return false;
}

function bool IsWhitelisted(Object InItem) {
	local int i;

	for(i = 0; i < WhitelistedCollectibles.length; i++) {
		if(ClassIsChildOf(InItem.class, WhitelistedCollectibles[i])) {
			return true;
		}
	}

	return false;
}

function bool IsBlacklisted(Object InItem) {
	local int i;

	for(i = 0; i < BlacklistedCollectibles.length; i++) {
		if(ClassIsChildOf(InItem.class, WhitelistedCollectibles[i])) {
			return true;
		}
	}

	return false;
}

