class_name DungeonSnapshotValidation
extends RefCounted
## App preflight before any checkpoint or replica mutates the world.

static func adventure(data: Dictionary) -> bool:
	if data.has("castle") and not CastleProtocol.valid(data.castle): return false
	if data.has("tofu_dungeon") and not valid(data.tofu_dungeon): return false
	if data.has("coop") and not CoopCheckpoint.valid(data.coop): return false
	return true

static func valid(data: Dictionary, live: bool = false) -> bool:
	if data.has("stashes") and (not data.stashes is Dictionary or not TofuStashRules.new().restore(data.stashes)): return false
	if data.has("inspections") and not _inspections(data.inspections): return false
	if data.has("actor_ids") and not DungeonActorIdentity.valid(data.actor_ids): return false
	if data.has("boss_members"):
		if not data.boss_members is Array or data.boss_members.size() > 4: return false
		var seen: Array[String] = []
		for key: Variant in data.boss_members:
			if not key is String or (key != "solo" and not ExplorationProtocol.key(key)) or key in seen: return false
			seen.append(key)
	if data.has("puzzle"):
		if not data.puzzle is Dictionary: return false
		var proof := TofuDungeonAttempt.new()
		if not proof.restore(data.puzzle, live): return false
		if bool(data.get("puzzle_mode", true)):
			if int(data.get("stage", proof.stage)) != int(proof.stage): return false
			if bool(data.get("completed", false)) != (proof.stage == TofuPuzzleContract.Stage.COMPLETE): return false
	if data.has("reward_ledger"):
		if not data.reward_ledger is Dictionary: return false
		var ledger := TofuRewardLedger.new()
		if not ledger.restore(data.reward_ledger): return false
	if data.has("puzzle_clock"):
		var clock: Variant = data.puzzle_clock
		if not (clock is int or clock is float) or not is_finite(float(clock)) or float(clock) < 0.0: return false
	return true

static func _inspections(value: Variant) -> bool:
	if not value is Dictionary or value.size() > 128: return false
	for key: Variant in value:
		if not key is String or key.length() > 64 or not value[key] is String: return false
		var id: String = value[key]
		if not TofuFactory.object_position(id).is_finite(): return false
	return true
