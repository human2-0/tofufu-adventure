class_name CastleProtocol
extends RefCounted
## Bounded values only: castle actions and atomic join/checkpoint snapshots.

static func trial(value: Variant) -> bool:
	if not value is Dictionary: return false
	if not CastleTreasureProtocol.valid(value): return false
	if value.has("message") and (not value.message is String or value.message.length() > 384): return false
	if not value.get("solved") is Array or value.solved.size() != 3: return false
	for flag: Variant in value.solved:
		if not flag is bool: return false
	if not _integer(value.get("levers"), 0, 7) or not _integer(value.get("sequence"), 0, 4): return false
	if not value.get("dials") is Array or value.dials.size() != 3: return false
	for dial: Variant in value.dials:
		if not _integer(dial, 0, 3): return false
	if not _integer(value.get("guards"), 0, 511) or not _integer(value.get("revision"), 0, 2147483647): return false
	for field in ["introduced", "completed"]:
		if not value.get(field) is bool: return false
	if value.solved[0] != (value.levers == 5) or value.solved[1] != (value.sequence == 4): return false
	if value.solved[2]:
		for i in 3:
			if int(value.dials[i]) != i + 1: return false
	if not _members(value.get("participants")) or not _members(value.get("rewarded")): return false
	for key: String in value.rewarded:
		if key not in value.participants or not value.completed: return false
	if value.completed and (value.guards != 511 or false in value.solved or not value.introduced or value.participants.is_empty()): return false
	return true

static func valid(value: Variant, live: bool = false) -> bool:
	if not value is Dictionary or not trial(value.get("trial")): return false
	if not live: return true
	if not value.get("guards") is Array or value.guards.size() != 9: return false
	for i in 9:
		if not CastleCombatProtocol.guardian(value.guards[i], i): return false
		if (value.guards[i].body[3] == 0) != (int(value.trial.guards) & (1 << i) != 0): return false
	if not _king(value.get("king")): return false
	if value.king.active and (value.trial.completed or value.trial.participants.is_empty() or false in value.trial.solved or value.trial.guards != 511): return false
	if value.trial.completed and (value.king.active or value.king.pose != "defeat"): return false
	if not value.get("burns") is Dictionary or value.burns.size() > 4: return false
	for key: Variant in value.burns:
		if not _key(key) or not _numbers(value.burns[key], 2, 6) or value.burns[key][0] < 0 or value.burns[key][1] < 0: return false
	if not _members(value.get("fallen")): return false
	for key: String in value.fallen:
		if key not in value.trial.participants: return false
	return true

static func _king(value: Variant) -> bool:
	if not value is Dictionary or not _numbers(value.get("position"), 3, 1000): return false
	if absf(value.position[0] - 316) > 25 or absf(value.position[2] - 334) > 25 or absf(value.position[1] - 28.4) > 1: return false
	if not _number(value.get("health"), 4000) or not _number(value.get("maximum"), 4000): return false
	if value.health < 0 or value.maximum < 1100 or value.health > value.maximum: return false
	if not value.get("active") is bool or not _integer(value.get("phase"), 1, 2) or not _integer(value.get("skill"), 0, 4): return false
	if not _integer(value.get("burst"), 0, 4) or not _number(value.get("burst_clock"), 0.14) or value.burst_clock < 0 or not _numbers(value.get("chunk_aim"), 3, 1.01): return false
	for field in ["cast", "recovery"]:
		if not _number(value.get(field), 3) or value[field] < 0: return false
	if not _numbers(value.get("facing"), 2, 1) or not _numbers(value.get("locked_aim"), 3, 1) or not _integer(value.get("cycle"), 0, 2147483647): return false
	if value.get("pose") not in ["idle", "walk", "channel", "release", "hit", "defeat"]: return false
	return CastleCombatProtocol.spells(value.get("spells"), 24, 12)

static func _members(value: Variant) -> bool:
	if not value is Array or value.size() > 4: return false
	var seen: Array[String] = []
	for key: Variant in value:
		if not _key(key) or key in seen: return false
		seen.append(key)
	return true

static func _key(value: Variant) -> bool:
	if not value is String: return false
	if value == "solo": return true
	if value.length() != 64: return false
	for character in value:
		if character not in "0123456789abcdef": return false
	return true

static func _integer(value: Variant, lo: int, hi: int) -> bool:
	return _number(value, hi) and value >= lo and float(value) == floorf(value)

static func _number(value: Variant, bound: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and absf(value) <= bound

static func _numbers(value: Variant, count: int, bound: float) -> bool:
	if not value is Array or value.size() != count: return false
	for item: Variant in value:
		if not _number(item, bound): return false
	return true
