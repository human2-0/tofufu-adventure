class_name BattleCombatWire
extends RefCounted
## Positional compression of adventure combat values, validated before presentation.

const FIELDS: Array[String] = [
	"enhanced", "celestial", "nori", "plunging", "plunge_recovery", "plunge_sequence",
	"plunge_at", "plunge_cooldown", "vitals", "pod", "podburst", "pod_cooldown",
	"world_drops", "gun_owned", "sotjet_owned", "staff_owned", "staff", "jet",
	"milk", "jet_ads", "jet_firing", "jet_sequence", "jet_origin", "jet_velocity",
	"recoil", "gun", "ads", "shot", "shot_origin", "shot_velocity",
	"owned", "selected", "guard", "active", "aim", "facing",
	"gun_magazine", "gun_reload", "gun_charge", "ricochet", "ricochet_origin", "ricochet_velocity",
	"charge", "strength", "style", "elapsed", "hit_pause", "punch",
	"punch_sequence", "combo", "chain", "combo_window", "clash", "cooldown",
	"drop", "paws", "claw_cooldown", "claw_charge", "claw_charging", "claw_dashing",
	"claw_remaining", "claw_launch", "claw_sequence", "claw_origin", "claw_aim", "bow",
	"bow_reload", "bow_charge", "bow_cooldown", "bow_shot", "bow_fire", "bow_origin",
	"bow_velocity", "bow_burst", "bow_at", "gun_clock", "click_clock", "refill_wait",
	"cloud_sequence", "cloud_at", "recoil_quiet"
]

static func pack(state: Dictionary) -> Array:
	var result: Array = []
	for field in FIELDS: result.append(precision(state[field]))
	return result

static func unpack(values: Array) -> Dictionary:
	var result: Dictionary = {}
	for i in FIELDS.size(): result[FIELDS[i]] = values[i]
	return result

static func valid(value: Variant) -> bool:
	if not value is Array or value.size() != FIELDS.size(): return false
	var state := unpack(value)
	for field in ["gun_clock", "click_clock", "refill_wait"]:
		if not BattleProtocol.number(state[field], 0, 2): return false
	if not BattleProtocol.number(state.recoil_quiet, 0, 0.12): return false
	if not BattleProtocol.integer(state.cloud_sequence, 0, 100000): return false
	if not ExplorationProtocol.vector(state.cloud_at, 3, 1000): return false
	return ExplorationProtocol.combat(state) and state.vitals.stamina <= 100

static func roster(value: Variant) -> bool:
	if not value is Array or (value.size() < 2 or value.size() > BattleProtocol.CAPACITY): return false
	for row: Variant in value:
		if not valid(row): return false
	return true

static func difference(before: Array, after: Array) -> Array:
	var result: Array = []
	for slot in after.size():
		var changes: Array = [slot]
		for index in FIELDS.size():
			if before[slot][index] != after[slot][index]: changes.append_array([index, after[slot][index]])
		if changes.size() > 1: result.append(changes)
	return result

static func apply(before: Array, patch: Variant) -> Array:
	if before.size() < 2 or before.size() > BattleProtocol.CAPACITY or not patch is Array or patch.size() > before.size(): return []
	var result := before.duplicate()
	var seen: Dictionary = {}
	for row: Variant in patch:
		if not row is Array or row.is_empty() or row.size() > FIELDS.size() * 2 + 1 or row.size() % 2 != 1: return []
		if not BattleProtocol.integer(row[0], 0, before.size() - 1) or seen.has(row[0]): return []
		seen[row[0]] = true
		var slot := int(row[0])
		result[slot] = result[slot].duplicate()
		var indexes: Dictionary = {}
		for i in range(1, row.size(), 2):
			if not BattleProtocol.integer(row[i], 0, FIELDS.size() - 1) or indexes.has(row[i]): return []
			indexes[row[i]] = true
			result[slot][int(row[i])] = row[i + 1]
	return result if roster(result) else []

static func precision(value: Variant) -> Variant:
	if value is float:
		var rounded := snappedf(value, 0.001)
		return int(rounded) if rounded == floorf(rounded) else rounded
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(precision(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key: String in value: result[key] = precision(value[key])
		return result
	return value
