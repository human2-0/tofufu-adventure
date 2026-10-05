class_name BarnProtocol
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
			if not ExplorationProtocol.sequence(row.get("count")) or row.count < 1 or row.count > limits[row.id]: return false
			if not ExplorationProtocol.number(row.get("reserve", 100.0), 100) or row.get("reserve", 100.0) < 0: return false
	return true

static func owner(value: Variant) -> bool:
	return value is String and (value.is_empty() or value == "solo" or ExplorationProtocol.key(value))

static func display(value: Variant) -> bool:
	return value is Dictionary and value.size() == 2 and ExplorationProtocol.sequence(value.get("bay")) and value.bay < 20 and owner(value.get("owner"))

static func produce(value: Variant) -> bool:
	if not value is Array or value.size() != 36: return false
	for timer: Variant in value:
		if not ExplorationProtocol.number(timer, 120) or timer < 0: return false
	return true
