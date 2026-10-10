class_name WorldProtocol
extends RefCounted
## Fixed-content world schema; no arbitrary resource paths or object deserialization.

const ITEM_LIMITS := {"celestial_helmet": 1, "celestial_armor": 1, "celestial_legs": 1, "celestial_boots": 1, "celestial_sword": 1, "celestial_staff": 1, "soy_raygun": 1, "nori_katana": 1, "edamame_sword": 1, "knife": 1, "soy_gun": 1, "sotjet": 1, "sproutwood_staff": 1, "factory_backpack": 1, "seed_satchel": 1, "traveler_backpack": 1, "edamame": 100, "mature_bean": 100, "tofu_white_chunk": 100, "toasted_tofu_chunk": 100, "golden_tofu_chunk": 100, "soy_milk": 10, "apple": 50, "potato": 50, "cucumber": 50, "red_berries": 50, "beetroot": 50, "forest_mushroom": 50, "piece_of_shell": 50, "bright_leaf_helmet": 1, "bright_leaf_armor": 1, "bright_leaf_legs": 1, "bright_leaf_boots": 1, "dark_leaf_helmet": 1, "dark_leaf_armor": 1, "dark_leaf_legs": 1, "dark_leaf_boots": 1}
const BACKPACK_CONTENT_LIMIT: int = 20
const CURRENT_MOB_COUNT: int = 43

static func valid(data: Dictionary) -> bool:
	if data.has("castle") and not CastleProtocol.valid(data.castle, true): return false
	if data.has("produce") and not BarnProtocol.produce(data.produce): return false
	if data.has("barn") and not BarnProtocol.valid(data.barn, ITEM_LIMITS): return false
	if data.has("farming") and not farming(data.farming): return false
	if data.has("factory") and not factory(data.factory): return false
	if data.has("world_items") and not world_items(data.world_items): return false
	if data.has("apple_trees") and not _rows(data.apple_trees, 20, 20, 2): return false
	if not data.get("mobs") is Array or not _rows(data.get("props"), 24, 24, 2): return false
	if data.mobs.size() not in [9, 15, 27, 39, CURRENT_MOB_COUNT]: return false
	if data.has("weather_phase") and (not ExplorationProtocol.number(data.weather_phase, 1) or data.weather_phase < 0): return false
	if data.has("seed_satchel_claimed") and not data.seed_satchel_claimed is bool: return false
	var wet: bool = data.get("weather_phase", 0.0) >= 1.0 / 3.0 and data.get("weather_phase", 0.0) < 2.0 / 3.0
	if not _rows(data.get("dummies"), 3, 3, 4) or not _rows(data.get("pickups"), 0, 128, 10, 11): return false
	for row: Variant in data.mobs:
		if not row is Array or row.size() not in [9, 12, 18]: return false
		if row.size() == 12 and (not _numeric(row.slice(9), 65) or row[9] < 0 or absf(row[10]) > 1 or absf(row[11]) > 1): return false
		if row.size() == 18 and (not _mob_numbers(row) or absf(row[9]) > 1 or absf(row[10]) > 1 or not ExplorationProtocol.vector(row.slice(14, 17), 3, 16) or row[17] < 0 or row[17] > 1.5): return false
		if not _mob_numbers(row) or row[6] < 0 or row[6] > (180 if wet else 130) or row[7] < 0 or row[8] < 0: return false
	for row: Array in data.props:
		if not _numeric(row, 100) or row[0] < 0 or row[1] < 0: return false
	for row: Array in data.dummies:
		if not _numeric(row, 100000000) or row[0] < 0 or row[0] > 200 or row[3] < 0 or row[3] > 4: return false
	for row: Array in data.get("apple_trees", []):
		if not _numeric(row, 180) or row[0] < 0 or row[0] > 1 or row[1] < 0: return false
		if (row[0] > 0) != (row[1] == 0): return false
	var ids: Array[int] = []
	for row: Array in data.pickups:
		if not _numeric(row, 2147483647) or not ExplorationProtocol.sequence(row[0]) or int(row[0]) in ids: return false
		ids.append(int(row[0]))
		if row.size() == 11 and (not ExplorationProtocol.sequence(row[10]) or row[10] < 1 or row[10] > 100): return false
		if not ExplorationProtocol.vector(row.slice(1, 4), 3, 1000): return false
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

static func factory(value: Variant) -> bool:
	if not value is Dictionary: return false
	if value.has("stashes") and not FactoryStashProtocol.valid(value.stashes): return false
	if value.has("puzzle_mode") and not value.puzzle_mode is bool: return false
	if value.has("puzzle") and not _factory_puzzle(value.puzzle): return false
	if not ExplorationProtocol.sequence(value.get("stage")) or value.stage > 6: return false
	if not value.get("completed") is bool or value.completed != (value.stage == 6): return false
	if not value.get("active") is bool: return false
	if value.has("cargo"):
		if not _rows(value.cargo, 0, 4, 3): return false
		for row: Array in value.cargo:
			if not ExplorationProtocol.vector(row, 3, 1000): return false
	if value.has("units") and (not ExplorationProtocol.sequence(value.units) or value.units > 3): return false
	for field in ["secured", "coagulant_added"]:
		if value.has(field) and not value[field] is bool: return false
	if value.has("broken_crates") and (not ExplorationProtocol.sequence(value.broken_crates) or value.broken_crates > 4095): return false
	if value.has("rewarded_ids"):
		if not value.rewarded_ids is Array or value.rewarded_ids.size() > 64: return false
		var reward_ids: Array[String] = []
		for identity: Variant in value.rewarded_ids:
			if not identity is String or identity.is_empty() or identity.length() > 48 or identity in reward_ids: return false
			reward_ids.append(identity)
	if value.has("run_members"):
		if not value.run_members is Array or value.run_members.size() > 4: return false
		var member_ids: Array[String] = []
		for key: Variant in value.run_members:
			if not key is String or key.is_empty() or key.length() > 64 or key in member_ids: return false
			member_ids.append(key)
	if value.has("reward_ledger") and not _factory_ledger(value.reward_ledger): return false
	if not ExplorationProtocol.number(value.get("processing"), 30) or value.processing < 0: return false
	if not _rows(value.get("enemies"), 0, 8, 5) or not _rows(value.get("crates"), 0, 12, 3): return false
	for row: Array in value.enemies:
		if not ExplorationProtocol.sequence(row[0]) or row[0] > 4: return false
		if not ExplorationProtocol.vector(row.slice(1, 4), 3, 1000): return false
		if not ExplorationProtocol.number(row[4], 2500) or row[4] < 0: return false
	for row: Array in value.crates:
		if not ExplorationProtocol.vector(row, 3, 1000): return false
	return true

static func _factory_puzzle(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 13 or value.get("version") != 2: return false
	for field: String in ["run_id", "attempt_id", "stage", "phase", "mistakes"]:
		var number: Variant = value.get(field)
		if not (number is int or number is float) or not is_finite(float(number)) or number != floorf(number): return false
		if number < 0 or number > 2147483647: return false
	if value.run_id < 1 or value.attempt_id < 1 or value.stage > 6 or value.phase > 5 or value.mistakes > 10: return false
	if not value.get("encounter_id") is String or value.encounter_id.length() > 48: return false
	if value.get("batch_id") != "batch_%d_%d" % [int(value.run_id), int(value.attempt_id)]: return false
	for field: String in ["sorting", "lab", "press", "cut", "pack"]:
		if not value.get(field) is Dictionary or not _factory_value(value[field], 0): return false
	return true

static func _factory_value(value: Variant, depth: int) -> bool:
	if depth > 4: return false
	if value is Dictionary:
		if value.size() > 32: return false
		for key: Variant in value:
			if not key is String or key.length() > 64 or not _factory_value(value[key], depth + 1): return false
		return true
	if value is Array:
		if value.size() > 32: return false
		for item: Variant in value:
			if not _factory_value(item, depth + 1): return false
		return true
	if value is String: return value.length() <= 128
	if value is bool: return true
	if value is int or value is float: return is_finite(float(value)) and absf(float(value)) <= 2147483647.0
	return false

static func _factory_ledger(value: Variant) -> bool:
	if not value is Dictionary or value.get("version") != 1: return false
	if not value.get("paid") is Array or not value.get("entitled") is Array: return false
	if value.paid.size() > 168 or value.entitled.size() > 64: return false
	var found: Dictionary = {}
	for identity: Variant in value.paid:
		if not identity is String or identity.is_empty() or identity.length() > 20 or found.has(identity): return false
		found[identity] = true
	found.clear()
	for key: Variant in value.entitled:
		if not key is String or key.is_empty() or key.length() > 64 or found.has(key): return false
		found[key] = true
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
	return ExplorationProtocol.vector(data.get("escape_start"), 3, 1000) and data.get("feedback") is String and data.feedback.length() <= 160

static func _rows(value: Variant, minimum: int, maximum: int, width: int, alternate_width: int = -1) -> bool:
	if not value is Array or value.size() < minimum or value.size() > maximum: return false
	for row: Variant in value:
		if not row is Array or (row.size() != width and row.size() != alternate_width): return false
	return true

static func _mob_numbers(row: Array) -> bool:
	return ExplorationProtocol.vector(row.slice(0, 3), 3, 1000) and _numeric(row.slice(3), 500)

static func _numeric(row: Array, bound: float) -> bool:
	for value: Variant in row:
		if not ExplorationProtocol.number(value, bound): return false
	return true

static func world_items(value: Variant) -> bool:
	if not value is Array or value.size() > 128: return false
	var ids: Array[int] = []
	for row: Variant in value:
		if not row is Array or row.size() not in [7, 8, 9]: return false
		if not ExplorationProtocol.sequence(row[0]) or row[0] < 1 or int(row[0]) in ids: return false
		ids.append(int(row[0]))
		if not row[1] is String: return false
		var maximum: Variant = ITEM_LIMITS.get(row[1])
		if maximum == null or not ExplorationProtocol.sequence(row[2]) or row[2] < 1 or row[2] > maximum: return false
		if not ExplorationProtocol.number(row[3], 100) or row[3] < 0: return false
		if not ExplorationProtocol.vector(row.slice(4, 7), 3, 1000): return false
		if row.size() >= 8 and not _backpack_contents(row[7], row[1]): return false
		if row.size() == 9 and not BarnProtocol.display(row[8]): return false
	return true

static func _backpack_contents(value: Variant, backpack_id: String) -> bool:
	if not value is Array: return false
	var limit := 10 if backpack_id == "factory_backpack" else (14 if backpack_id == "seed_satchel" else (BACKPACK_CONTENT_LIMIT if backpack_id == "traveler_backpack" else 0))
	if value.size() > limit: return false
	for row: Variant in value:
		if not row is Dictionary: return false
		if not row.is_empty() and not _stack(row): return false
	return true

static func _stack(row: Dictionary) -> bool:
	if not row.get("id") is String or not ExplorationProtocol.sequence(row.get("count")): return false
	var maximum: Variant = ITEM_LIMITS.get(row.id)
	if maximum == null or row.count < 1 or row.count > maximum: return false
	var reserve: Variant = row.get("reserve", 100.0)
	return ExplorationProtocol.number(reserve, 100) and reserve >= 0

static func farming(value: Variant) -> bool:
	return FarmingProtocol.valid(value)
