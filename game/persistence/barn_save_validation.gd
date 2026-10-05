class_name BarnSaveValidation
extends RefCounted
## Bounded chest/display values for host snapshots. Legacy absence remains valid.

static func valid(value: Variant, limits: Dictionary) -> bool:
	if not value is Dictionary or value.size() != 2: return false
	if not value.get("owners") is Array or value.owners.size() != 20: return false
	if not value.get("chests") is Array or value.chests.size() != 20: return false
	for i in 20:
		if not owner(value.owners[i]): return false
		if not value.chests[i] is Array or value.chests[i].size() != 24: return false
		for row: Variant in value.chests[i]:
			if not row is Dictionary: return false
			if row.is_empty(): continue
			if not row.get("id") is String or not limits.has(row.id): return false
			if not _integer(row.get("count")) or row.count < 1 or row.count > limits[row.id]: return false
			if not _number(row.get("reserve", 100.0), 100) or row.get("reserve", 100.0) < 0: return false
	return true

static func owner(value: Variant) -> bool:
	return value is String and (value.is_empty() or value == "solo" or (value.length() == 64 and value.is_valid_hex_number(false)))

static func display(value: Variant) -> bool:
	return value is Dictionary and value.size() == 2 and _integer(value.get("bay")) and value.bay < 20 and owner(value.get("owner"))

static func _integer(value: Variant) -> bool:
	return _number(value, 2147483647) and value >= 0 and value == floorf(value)

static func _number(value: Variant, bound: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and absf(float(value)) <= bound

static func produce(value: Variant) -> bool:
	if not value is Array or value.size() != 36: return false
	for timer: Variant in value:
		if not _number(timer, 120) or timer < 0: return false
	return true
