class_name FarmingProtocol
extends RefCounted
## Fixed plot growth values.

static func valid(value: Variant) -> bool:
	if not value is Array or value.size() != 4: return false
	for row: Variant in value:
		if not row is Array or row.size() != 4: return false
		if not row[0] is bool: return false
		if not ExplorationProtocol.number(row[1], 30) or row[1] < 0: return false
		if not ExplorationProtocol.number(row[2], 1.2) or row[2] < 0: return false
		if not ExplorationProtocol.sequence(row[3]): return false
		if row[0] and row[2] != 0: return false
		if not row[0] and row[1] != 0: return false
	return true
