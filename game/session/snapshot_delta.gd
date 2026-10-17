class_name SnapshotDelta
extends RefCounted
## Copy-on-write value patches for the reliable snapshot stream. No remote objects.

const MAX_DEPTH: int = 16
const MAX_VALUES: int = 16384
var _remaining: int = MAX_VALUES

static func difference(before: Variant, after: Variant) -> Array:
	if before == after: return []
	if before is Dictionary and after is Dictionary:
		var changes := {}
		var removed: Array = []
		for key: String in after:
			var patch := difference(before.get(key), after[key])
			if not patch.is_empty(): changes[key] = patch
		for key: String in before:
			if not after.has(key): removed.append(key)
		return [1, changes, removed]
	# Sparse rows retain unchanged mobs, props and item records. Numeric vectors
	# are replaced together; index wrappers would cost more than their values.
	if before is Array and after is Array and before.size() == after.size() and after.size() > 4:
		var changes := {}
		for index in after.size():
			if not after[index] is Array and not after[index] is Dictionary: return [0, after]
			var patch := difference(before[index], after[index])
			if not patch.is_empty(): changes[str(index)] = patch
		return [2, changes]
	return [0, after]

func apply(before: Variant, patch: Variant) -> Variant:
	_remaining = MAX_VALUES
	return _apply(before, patch, 0)

func bounded(value: Variant) -> bool:
	_remaining = MAX_VALUES
	return _value(value, 0)

func _apply(before: Variant, patch: Variant, depth: int) -> Variant:
	_remaining -= 1
	if _remaining < 0 or depth > MAX_DEPTH or not patch is Array or patch.is_empty(): return null
	if not ExplorationProtocol.sequence(patch[0]) or patch[0] > 2: return null
	match int(patch[0]):
		0:
			if patch.size() != 2 or not _value(patch[1], depth + 1): return null
			return patch[1]
		1:
			return _dictionary(before, patch, depth)
		2:
			return _array(before, patch, depth)
	return null

func _dictionary(before: Variant, patch: Array, depth: int) -> Variant:
	if not before is Dictionary or patch.size() != 3 or not patch[1] is Dictionary or not patch[2] is Array: return null
	if patch[1].size() > 256 or patch[2].size() > 256: return null
	var result: Dictionary = before.duplicate()
	for key: Variant in patch[2]:
		if not key is String or not result.has(key) or patch[1].has(key): return null
		result.erase(key)
	for key: Variant in patch[1]:
		if not key is String or key.length() > 64: return null
		var value: Variant = _apply(before.get(key), patch[1][key], depth + 1)
		if value == null: return null
		result[key] = value
	if result.size() > 256: return null
	return result

func _array(before: Variant, patch: Array, depth: int) -> Variant:
	if not before is Array or patch.size() != 2 or not patch[1] is Dictionary or patch[1].size() > 512: return null
	var result: Array = before.duplicate()
	for key: Variant in patch[1]:
		if not key is String or not key.is_valid_int(): return null
		var index := int(key)
		if str(index) != key or index < 0 or index >= result.size(): return null
		var value: Variant = _apply(before[index], patch[1][key], depth + 1)
		if value == null: return null
		result[index] = value
	return result

func _value(value: Variant, depth: int) -> bool:
	_remaining -= 1
	if _remaining < 0 or depth > MAX_DEPTH: return false
	if value is Dictionary:
		if value.size() > 256: return false
		for key: Variant in value:
			if not (key is String or key is StringName) or String(key).length() > 64 or not _value(value[key], depth + 1): return false
		return true
	if value is Array:
		if value.size() > 512: return false
		for item: Variant in value:
			if not _value(item, depth + 1): return false
		return true
	if value is String or value is StringName: return String(value).length() <= 512
	if value is bool: return true
	return ExplorationProtocol.number(value, 2147483647)
