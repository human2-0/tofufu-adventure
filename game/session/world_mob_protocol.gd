class_name WorldMobProtocol
extends RefCounted
## Fixed roster records, including bounded facing, flights and paralysis.

static func valid(data: Dictionary, wet: bool) -> bool:
	for index in data.mobs.size():
		var row: Variant = data.mobs[index]
		if not row is Array or row.size() not in [9, 12, 18]: return false
		if not _mob_numbers(row): return false
		if index >= 43 and index < 55 and row.size() != 18: return false
		if index >= 59 and (row.size() != 12 or not _numeric(row.slice(9, 11), 1) or row[11] < 0 or row[11] > 0.25): return false
		if index >= 55 and index < 59 and row.size() != 9: return false
		if index < 59 and row.size() == 12 and (not _numeric(row.slice(9), 65) or row[9] < 0 or absf(row[10]) > 1 or absf(row[11]) > 1): return false
		if row.size() == 18 and (not _mob_numbers(row) or absf(row[9]) > 1 or absf(row[10]) > 1 or not ExplorationProtocol.vector(row.slice(14, 17), 3, 32 if index >= 43 and index < 55 else 16) or row[17] < 0 or row[17] > 1.5): return false
		if not _mob_numbers(row) or row[6] < 0 or row[6] > (240 if index >= 59 else (130 if index >= 55 else (420 if index >= 43 else (180 if wet else 130)))) or row[7] < 0 or row[8] < 0: return false
	if data.has("mob_paralysis"):
		if not data.mob_paralysis is Array or data.mob_paralysis.size() != data.mobs.size(): return false
		for value: Variant in data.mob_paralysis:
			if not ExplorationProtocol.number(value, 4) or value < 0: return false
	return true

static func _mob_numbers(row: Array) -> bool:
	return ExplorationProtocol.vector(row.slice(0, 3), 3, 1000) and _numeric(row.slice(3), 500)

static func _numeric(row: Array, bound: float) -> bool:
	for value: Variant in row:
		if not ExplorationProtocol.number(value, bound): return false
	return true
