class_name CharacterProgress
extends RefCounted
## Per-character cumulative practice and EXP; no scenes, input or networking.

signal changed
const CAP: int = 99
const TUNING: ProgressionTuning = preload("res://game/progression/default_progression.tres")
const SKILLS: Array[String] = ["fist", "sword", "shooting", "magic", "attack_speed", "defence"]
var experience: int = 0
var practice: Dictionary = {"fist": 0, "sword": 0, "shooting": 0, "magic": 0, "attack_speed": 0, "defence": 0}
var stat_points: int = 0
var stats: Dictionary = {"fist": 0, "sword": 0, "shooting": 0, "magic": 0, "attack_speed": 0, "defence": 0}
var _granted_level: int = 1

static func requirement(level: int, character: bool = false) -> int:
	if character:
		return TUNING.first_experience_cost + TUNING.experience_linear * (level - 1) + TUNING.experience_quadratic * (level - 1) * (level - 1)
	return ceili(TUNING.first_practice_cost * pow(TUNING.practice_growth, level - 1))

static func threshold(level: int, character: bool = false) -> int:
	var total := 0
	for step in range(1, clampi(level, 1, CAP)):
		total += requirement(step, character)
	return total

static func rank(total: int, character: bool = false) -> int:
	var level := 1
	while level < CAP and total >= requirement(level, character):
		total -= requirement(level, character)
		level += 1
	return level

func level() -> int:
	return rank(experience, true)

func skill(name: String) -> int:
	var base_rank := rank(int(int(practice.get(name, 0)) / practice_cost_multiplier(name)))
	return mini(CAP, base_rank + int(stats.get(name, 0)))

func allocate_stat(name: String) -> bool:
	if stat_points <= 0 or not name in SKILLS or skill(name) >= CAP:
		return false
	stat_points -= 1
	stats[name] = int(stats.get(name, 0)) + 1
	changed.emit()
	return true

func weapon_hit(weapon: String) -> void:
	if weapon in ["fist", "sword", "shooting"]: _practice(weapon, 1)

func defended() -> void:
	_practice("defence", 1)

## Future spell execution must call this only after actually deducting mana.
func mana_spent(points: int) -> void:
	_practice("magic", points)

## No gameplay caller until the specific training equipment is implemented.
func speed_gear_trained(units: int) -> void:
	_practice("attack_speed", units)

func award_experience(amount: int) -> void:
	if amount <= 0: return
	experience = mini(threshold(CAP, true), experience + mini(amount, 100000000))
	_check_level_points()
	changed.emit()

func _check_level_points() -> void:
	if level() > _granted_level:
		stat_points += level() - _granted_level
		_granted_level = level()

func _practice(name: String, amount: int) -> void:
	if amount <= 0: return
	practice[name] = mini(threshold(CAP) * practice_cost_multiplier(name), int(practice[name]) + mini(amount, 100000000))
	changed.emit()

static func practice_cost_multiplier(name: String) -> int:
	return TUNING.shooting_practice_multiplier if name == "shooting" else 1

func shooting_spread_multiplier() -> float:
	return 1.0 - TUNING.shooting_accuracy * (skill("shooting") - 1)

func shooting_range_multiplier() -> float:
	return 1.0 + TUNING.shooting_jet_range * (skill("shooting") - 1)

func damage_multiplier(weapon: String) -> float:
	return 1.0 + TUNING.character_damage * (level() - 1) + TUNING.weapon_damage * (skill(weapon) - 1)

func effective_defence() -> int:
	return mini(CAP, skill("defence") + int((level() - 1) / float(TUNING.character_levels_per_defence)))

func incoming_multiplier() -> float:
	return 1.0 - TUNING.defence_reduction * (effective_defence() - 1)

func walk_multiplier() -> float:
	return 1.0 + TUNING.character_walk_speed * (level() - 1)

func attack_multiplier() -> float:
	return 1.0 + TUNING.character_attack_speed * (level() - 1) + TUNING.trained_attack_speed * (skill("attack_speed") - 1)

func capture() -> Dictionary:
	return {
		"version": 2,
		"experience": experience,
		"practice": practice.duplicate(),
		"stat_points": stat_points,
		"stats": stats.duplicate(),
		"granted_level": _granted_level
	}

func restore(data: Dictionary, legacy_experience: int = 0) -> void:
	experience = clampi(int(data.get("experience", legacy_experience)), 0, threshold(CAP, true))
	var saved: Dictionary = data.get("practice", {})
	for name in SKILLS: practice[name] = clampi(int(saved.get(name, 0)), 0, threshold(CAP) * practice_cost_multiplier(name))
	var saved_stats: Dictionary = data.get("stats", {})
	for name in SKILLS: stats[name] = maxi(0, int(saved_stats.get(name, 0)))
	_granted_level = maxi(1, int(data.get("granted_level", 1)))
	stat_points = maxi(0, int(data.get("stat_points", maxi(0, level() - _granted_level))))
	_check_level_points()
	changed.emit()

func display() -> Dictionary:
	var req := requirement(level(), true)
	var earned_exp := req - (threshold(mini(CAP, level() + 1), true) - experience)
	var pct := 100 if level() == CAP else clampi(int(100.0 * earned_exp / maxf(1.0, req)), 0, 100)
	var rate: float = snappedf(attack_multiplier() / 0.38, 0.1)
	var dmg: int = int(12.0 * damage_multiplier("fist"))
	var result := {
		"level": level(),
		"experience": experience,
		"skills": {},
		"defence": effective_defence(),
		"level_percent": pct,
		"fist_hit_rate": rate,
		"fist_damage": dmg,
		"stat_points": stat_points,
		"stats": stats.duplicate()
	}
	result.remaining = threshold(mini(CAP, level() + 1), true) - experience
	for name in SKILLS:
		var current := skill(name)
		var base_rank := rank(int(int(practice.get(name, 0)) / practice_cost_multiplier(name)))
		var earned := int(practice[name]) - threshold(base_rank) * practice_cost_multiplier(name)
		var practice_req := requirement(base_rank) * practice_cost_multiplier(name)
		var skill_pct := 100 if current == CAP else clampi(int(100.0 * earned / maxf(1.0, practice_req)), 0, 100)
		result.skills[name] = {"level": current, "percent": skill_pct}
	return result
