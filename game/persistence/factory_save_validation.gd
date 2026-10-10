class_name FactorySaveValidation
extends RefCounted
## Bounded dungeon identity fields for local save records.

static func stashes(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 2: return false
	for field: String in ["opened", "revision"]:
		var number: Variant = value.get(field)
		if not (number is int or number is float) or not is_finite(float(number)) or number != floorf(number): return false
	if value.opened < 0 or value.opened > 7 or value.revision < 0 or value.revision > 3: return false
	var bits: int = 0
	for index in 3:
		if (int(value.opened) & (1 << index)) != 0: bits += 1
	return bits == int(value.revision)

static func rewards(value: Variant) -> bool:
	if not value is Array or value.size() > 64: return false
	var found: Array[String] = []
	for identity: Variant in value:
		if not identity is String or identity.length() > 48 or identity.is_empty() or identity in found: return false
		found.append(identity)
	return true

static func members(value: Variant) -> bool:
	if not value is Array or value.size() > 4: return false
	var found: Array[String] = []
	for key: Variant in value:
		if not key is String or key.is_empty() or key.length() > 64 or key in found: return false
		found.append(key)
	return true

static func ledger(value: Variant) -> bool:
	if not value is Dictionary or value.get("version") != 1: return false
	var paid: Variant = value.get("paid")
	var entitled: Variant = value.get("entitled")
	if not paid is Array or not entitled is Array or paid.size() > 168 or entitled.size() > 64: return false
	var paid_seen: Dictionary = {}
	var member_seen: Dictionary = {}
	for identity: Variant in paid:
		if not identity is String or identity.is_empty() or identity.length() > 20 or paid_seen.has(identity): return false
		paid_seen[identity] = true
	for member: Variant in entitled:
		if not member is String or member.is_empty() or member.length() > 64 or member_seen.has(member): return false
		member_seen[member] = true
	return true

static func puzzle(value: Variant) -> bool:
	if not value is Dictionary: return false
	if value.size() != 13 or value.get("version") != 2: return false
	for field: String in ["run_id", "attempt_id", "stage", "phase", "mistakes"]:
		var number: Variant = value.get(field)
		if not (number is int or number is float) or not is_finite(float(number)) or number != floorf(number): return false
		if number < 0 or number > 2147483647: return false
	if value.run_id < 1 or value.attempt_id < 1 or value.stage > 6 or value.phase > 5 or value.mistakes > 10: return false
	if not value.get("encounter_id") is String or value.encounter_id.length() > 48: return false
	if value.get("batch_id") != "batch_%d_%d" % [int(value.run_id), int(value.attempt_id)]: return false
	for field: String in ["sorting", "lab", "press", "cut", "pack"]:
		if not value.get(field) is Dictionary or not _bounded_tree(value[field], 0): return false
	return true

static func _bounded_tree(value: Variant, depth: int) -> bool:
	if depth > 4: return false
	if value is Dictionary:
		if value.size() > 32: return false
		for key: Variant in value:
			if not key is String or key.length() > 64 or not _bounded_tree(value[key], depth + 1): return false
		return true
	if value is Array:
		if value.size() > 32: return false
		for item: Variant in value:
			if not _bounded_tree(item, depth + 1): return false
		return true
	if value is String: return value.length() <= 128
	if value is bool: return true
	if value is int or value is float: return is_finite(float(value)) and absf(float(value)) <= 2147483647.0
	return false
