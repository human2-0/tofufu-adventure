class_name CoopCheckpoint
extends RefCounted
## Host-owned, versioned complete world checkpoints and stable-key party records.

static func capture(session: CoopSession) -> Dictionary:
	var party: Dictionary = session.game.parrot_travel.saved_party(session.duel.checkpoint_party(session.roster.capture_party()))
	var data := {"version": 2, "party": party,
		"world": CoopWorld.capture(session.game), "opening": session.opening.capture()}
	if session.personal_maps != null: data.maps = session.personal_maps.capture()
	return data

static func valid(data: Dictionary) -> bool:
	if data.get("version") != 2 or not data.get("party") is Dictionary or data.party.size() > 32: return false
	if data.has("maps"):
		if not data.maps is Dictionary or data.maps.size() > 32: return false
		for key: Variant in data.maps:
			if not data.get("party", {}).has(key) or not MapSaveValidation.valid(data.maps[key]): return false
	for key: Variant in data.party:
		if not ExplorationProtocol.key(key) or not data.party[key] is Dictionary or not ExplorationProtocol.actor(data.party[key]): return false
	if data.get("world") is Dictionary and data.world.get("factory") is Dictionary:
		if not DungeonSnapshotValidation.valid(data.world.factory, true): return false
	return data.get("world") is Dictionary and WorldProtocol.valid(data.world) and data.get("opening") is Dictionary and WorldProtocol.opening(data.opening)
