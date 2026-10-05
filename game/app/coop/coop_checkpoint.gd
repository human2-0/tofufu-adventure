class_name CoopCheckpoint
extends RefCounted
## Host-owned, versioned complete world checkpoints and stable-key party records.

static func capture(session: CoopSession) -> Dictionary:
	var party: Dictionary = session.game.parrot_travel.saved_party(session.duel.checkpoint_party(session.roster.capture_party()))
	return {"version": 2, "party": party,
		"world": CoopWorld.capture(session.game), "opening": session.opening.capture()}

static func valid(data: Dictionary) -> bool:
	if data.get("version") != 2 or not data.get("party") is Dictionary or data.party.size() > 32: return false
	for key: Variant in data.party:
		if not ExplorationProtocol.key(key) or not data.party[key] is Dictionary or not ExplorationProtocol.actor(data.party[key]): return false
	if data.get("world") is Dictionary and data.world.get("factory") is Dictionary:
		if not DungeonSnapshotValidation.valid(data.world.factory, true): return false
	return data.get("world") is Dictionary and WorldProtocol.valid(data.world) and data.get("opening") is Dictionary and WorldProtocol.opening(data.opening)
