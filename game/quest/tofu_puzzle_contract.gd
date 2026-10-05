class_name TofuPuzzleContract
extends RefCounted
## Stable IDs and state bounds shared by the dungeon's rule modules.

enum Stage { SORT, LAB, PRESS, CUT, PACK, BOSS, COMPLETE }
enum Phase { LOCKED, COMBAT, READY, OPERATING, REJECTED, COMPLETE }

const SCHEMA_VERSION: int = 2
const MAX_MISTAKES: int = 10
const SACK_IDS: Array[String] = ["sack_edamame", "sack_mature", "sack_high_fat"]
const INTAKE_IDS: Array[String] = ["intake_chilled", "intake_tofu", "intake_oil"]
const CHEMICAL_IDS: Array[String] = ["nigari", "gypsum", "citric_acid", "vinegar", "lemon_concentrate", "glucono_delta_lactone", "calcium_chloride", "table_salt", "baking_soda", "sodium_carbonate", "sugar", "starch", "agar", "gelatin", "yeast", "pectin", "potassium_citrate", "sodium_citrate", "distilled_water", "mineral_oil"]
const PASSWORD: String = "Tofufu"
const BOSS_REWARD: int = 10
const ORDINARY_REWARD: int = 10

static func expected_intake(sack_id: String) -> String:
	var index: int = SACK_IDS.find(sack_id)
	return INTAKE_IDS[index] if index >= 0 else ""

static func encounter_id(stage: Stage, mistake: int, slot: int) -> String:
	if mistake > 0:
		return "penalty_%02d_slot_%02d" % [mistake, slot]
	return "stage_%02d_slot_%02d" % [int(stage), slot]

static func penalty_multiplier(mistake: int) -> float:
	return pow(1.2, clampi(mistake, 1, MAX_MISTAKES))

static func password_matches(value: String) -> bool:
	return value.strip_edges().nocasecmp_to(PASSWORD) == 0

static func bounded_integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and float(value) == floorf(float(value)) and value >= minimum and value <= maximum
