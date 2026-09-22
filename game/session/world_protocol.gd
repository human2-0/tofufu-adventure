class_name WorldProtocol
extends RefCounted
## Fixed-content world schema; no arbitrary resource paths or object deserialization.

static func valid(data: Dictionary) -> bool:
	if data.has("farming") and not farming(data.farming): return false
	if data.has("world_items") and not world_items(data.world_items): return false
	if not _rows(data.get("mobs"), 9, 15, 9) or not _rows(data.get("props"), 24, 24, 2): return false
	if data.mobs.size() != 9 and data.mobs.size() != 15: return false
	if data.has("weather_phase") and (not ExplorationProtocol.number(data.weather_phase, 1) or data.weather_phase < 0): return false
	var wet: bool = data.get("weather_phase", 0.0) >= 1.0 / 3.0 and data.get("weather_phase", 0.0) < 2.0 / 3.0
	if not _rows(data.get("dummies"), 3, 3, 4) or not _rows(data.get("pickups"), 0, 128, 10): return false
	for row: Array in data.mobs:
		if not _numeric(row, 500) or row[6] < 0 or row[6] > (90 if wet else 60) or row[7] < 0 or row[8] < 0: return false
	for row: Array in data.props:
		if not _numeric(row, 100) or row[0] < 0 or row[1] < 0: return false
	for row: Array in data.dummies:
		if not _numeric(row, 100000000) or row[0] < 0 or row[0] > 200 or row[3] < 0 or row[3] > 4: return false
	var ids: Array[int] = []
	for row: Array in data.pickups:
		if not _numeric(row, 2147483647) or not ExplorationProtocol.sequence(row[0]) or int(row[0]) in ids: return false
		ids.append(int(row[0]))
		if not ExplorationProtocol.vector(row.slice(1, 4), 3, 500): return false
		if row[4] < 0 or row[4] > 61 or absf(row[5]) > 100 or absf(row[6]) > 100: return false
		for value: Variant in row.slice(7, 10):
			if value != 0 and value != 1: return false
	if not ExplorationProtocol.number(data.get("phase"), 1) or data.phase < 0: return false
	for field in ["beans", "kills", "harvests", "experience", "next_pickup"]:
		if not ExplorationProtocol.sequence(data.get(field)): return false
	if not data.get("places") is Array or data.places.size() > 4: return false
	for place: Variant in data.places:
		if not place is String or place.length() > 80: return false
	return true

static func opening(data: Dictionary) -> bool:
	if not data.get("active") is bool: return false
	if not data.active: return true
	if not ExplorationProtocol.sequence(data.get("stage")) or data.stage > 5: return false
	if not ExplorationProtocol.sequence(data.get("pushes")) or data.pushes > 4: return false
	if not ExplorationProtocol.number(data.get("direction"), 1) or absf(data.direction) != 1: return false
	if not ExplorationProtocol.number(data.get("last_direction"), 1) or data.last_direction != floorf(data.last_direction): return false
	if not data.get("held") is bool: return false
	for field in ["elapsed", "beat", "charge"]:
		if not ExplorationProtocol.number(data.get(field), 100000000) or data[field] < 0: return false
	return ExplorationProtocol.vector(data.get("escape_start"), 3, 500) and data.get("feedback") is String and data.feedback.length() <= 160

static func _rows(value: Variant, minimum: int, maximum: int, width: int) -> bool:
	if not value is Array or value.size() < minimum or value.size() > maximum: return false
	for row: Variant in value:
		if not row is Array or row.size() != width: return false
	return true

static func _numeric(row: Array, bound: float) -> bool:
	for value: Variant in row:
		if not ExplorationProtocol.number(value, bound): return false
	return true

static func world_items(value: Variant) -> bool:
	if not value is Array or value.size() > 128: return false
	var ids: Array[int] = []
	for row: Variant in value:
		if not row is Array or row.size() != 7: return false
		if not ExplorationProtocol.sequence(row[0]) or row[0] < 1 or int(row[0]) in ids: return false
		ids.append(int(row[0]))
		if not row[1] is String or row[1] not in ["knife", "soy_gun", "sotjet", "soybean"]: return false
		if not ExplorationProtocol.sequence(row[2]) or row[2] < 1 or row[2] > (999 if row[1] == "soybean" else 1): return false
		if not ExplorationProtocol.number(row[3], 100) or row[3] < 0: return false
		if not ExplorationProtocol.vector(row.slice(4), 3, 500): return false
	return true

static func farming(value: Variant) -> bool:
	if not _rows(value, 4, 4, 4): return false
	for row: Array in value:
		if not row[0] is bool: return false
		if not ExplorationProtocol.number(row[1], 30) or row[1] < 0: return false
		if not ExplorationProtocol.number(row[2], 1.2) or row[2] < 0: return false
		if not ExplorationProtocol.sequence(row[3]): return false
		if row[0] and row[2] != 0: return false
		if not row[0] and row[1] != 0: return false
	return true
