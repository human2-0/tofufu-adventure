class_name FactoryLayout
extends RefCounted
## Stable authored prop locations; unknown IDs never resolve to a playable point.

const SACK_IDS: Array[String] = ["sack_edamame", "sack_mature", "sack_high_fat"]
const INTAKE_IDS: Array[String] = ["intake_chilled", "intake_tofu", "intake_oil"]
const CHEMICAL_IDS: Array[String] = ["nigari", "gypsum", "citric_acid", "vinegar", "lemon_concentrate", "glucono_delta_lactone", "calcium_chloride", "table_salt", "baking_soda", "sodium_carbonate", "sugar", "starch", "agar", "gelatin", "yeast", "pectin", "potassium_citrate", "sodium_citrate", "distilled_water", "mineral_oil"]

static func position_for(object_id: String) -> Vector3:
	if object_id.begins_with("stash_"): return FactoryHiddenChests.position_for(object_id)
	var index := SACK_IDS.find(object_id)
	if index >= 0: return Vector3(294 + index * 6, 0.2, -175)
	index = INTAKE_IDS.find(object_id)
	if index >= 0: return Vector3(294 + index * 6, 0.2, -182.6)
	index = CHEMICAL_IDS.find(object_id)
	if object_id.begins_with("container_"):
		var container_number := object_id.trim_prefix("container_")
		index = int(container_number) if container_number.is_valid_int() else -1
	if index >= 0:
		if index >= CHEMICAL_IDS.size(): return Vector3(INF, INF, INF)
		return Vector3(314 + index % 10 * 1.8, 0.2, -187 if index < 10 else -173)
	if object_id == "lab_terminal" or object_id == "terminal": return Vector3(316, 0.2, -182)
	if object_id == "shift_note" or object_id == "service_note": return Vector3(318, 0.2, -172.5)
	if object_id == "coagulation_tank": return Vector3(327, 0.2, -183)
	if object_id == "traditional_press": return Vector3(338, 0.2, -185)
	if object_id == "modern_press": return Vector3(349, 0.2, -185)
	if object_id == "cutter": return Vector3(344, 4.2, -213)
	if object_id == "packing_seal": return Vector3(322, 4.2, -213)
	for prefix in ["stone_", "slab_", "package_"]:
		if not object_id.begins_with(prefix): continue
		var suffix := object_id.trim_prefix(prefix)
		if not suffix.is_valid_int(): break
		index = int(suffix)
		if prefix == "stone_" and index >= 1 and index <= 3:
			return Vector3(334.5 + index * 2.5, 0.2, -174)
		if prefix == "slab_" and index >= 0 and index < 6:
			return Vector3(340 + index * 1.6, 4.2, -203)
		if prefix == "package_" and index >= 0 and index < 6:
			return Vector3(316 + index * 2.4, 4.2, -213)
	return Vector3(INF, INF, INF)
