class_name CastleSaveValidation
extends RefCounted
## Persistent trial and reward values; live combat resumes as a fresh challenge.

static func trial(value: Variant) -> bool:
	if not value is Dictionary: return false
	if not CastleTreasureValidation.valid(value): return false
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

static func valid(value: Variant) -> bool:
	return value is Dictionary and trial(value.get("trial"))

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
