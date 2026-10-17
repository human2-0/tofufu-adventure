class_name CharacterProgress
extends RefCounted
## Per-character cumulative practice and EXP; no scenes, input or networking.

signal changed
signal leveled_up(new_level: int)
const CAP: int = 99
const TUNING: ProgressionTuning = preload("res://game/progression/default_progression.tres")
const SKILLS: Array[String] = ["fist", "sword", "shooting", "magic", "attack_speed", "defence"]
var experience: int = 0
var practice: Dictionary = {"fist": 0, "sword": 0, "shooting": 0, "magic": 0, "attack_speed": 0, "defence": 0}
var stat_points: int = 0
var stats: Dictionary = {"fist": 0, "sword": 0, "shooting": 0, "magic": 0, "attack_speed": 0, "defence": 0}
var _granted_level: int = 1
var journey := JourneyPractice.new()

func record_journey(track: String, units: int) -> void:
	if journey.record(track, units): changed.emit()

static func requirement(skill_level: int, character: bool = false) -> int:
	if character:
		return TUNING.first_experience_cost + TUNING.experience_linear * (skill_level - 1) + TUNING.experience_quadratic * (skill_level - 1) * (skill_level - 1)
	return ceili(TUNING.first_practice_cost * pow(TUNING.practice_growth, skill_level - 1))

static func threshold(skill_level: int, character: bool = false) -> int:
	var total := 0
	for step in range(1, clampi(skill_level, 1, CAP)):
		total += requirement(step, character)
	return total

static func rank(total: int, character: bool = false) -> int:
	var skill_level := 1
	while skill_level < CAP and total >= requirement(skill_level, character):
		total -= requirement(skill_level, character)
		skill_level += 1
	return skill_level

func level() -> int:
	return rank(experience, true)

func skill(name: String) -> int:
	var base_rank := rank(int(float(practice.get(name, 0)) / practice_cost_multiplier(name)))
	return mini(CAP, base_rank + int(stats.get(name, 0)))

func allocate_stat(name: String) -> bool:
	if stat_points <= 0 or not name in SKILLS or skill(name) >= CAP or bonus_capped(name):
		return false
	stat_points -= 1
	stats[name] = int(stats.get(name, 0)) + 1
	changed.emit()
	return true

func bonus_capped(name: String) -> bool:
	if name == "defence": return incoming_multiplier() <= 0.200001
	if name == "attack_speed": return attack_multiplier() >= 3.499999
	return false

func weapon_hit(weapon: String) -> void:
	if weapon in ["fist", "sword", "shooting"]:
		journey.record("rhythm", 1)
		_practice(weapon, 1)

func defended() -> void:
	_practice("defence", 1)

## Future spell execution must call this only after actually deducting mana.
func mana_spent(points: int) -> void:
	_practice("magic", points)

## Confirmed Bengal Paws strikes train speed alongside fist practice.
func speed_gear_trained(units: int) -> void:
	_practice("attack_speed", units)

func award_experience(amount: int) -> void:
	if amount <= 0: return
	var previous := level()
	experience = mini(threshold(CAP, true), experience + mini(amount, 100000000))
	_check_level_points()
	changed.emit()
	if level() > previous: leveled_up.emit(level())

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

func shooting_push_multiplier() -> float:
	return 1.0 + TUNING.shooting_jet_push * (skill("shooting") - 1)

func shooting_range_multiplier() -> float:
	return 1.0 + TUNING.shooting_jet_range * (skill("shooting") - 1)

func damage_multiplier(weapon: String) -> float:
	return 1.0 + TUNING.character_damage * (level() - 1) + TUNING.weapon_damage * (skill(weapon) - 1)

func effective_defence() -> int:
	return mini(CAP, skill("defence") + int((level() - 1) / float(TUNING.character_levels_per_defence)))

func incoming_multiplier() -> float:
	return protection_multiplier(level(), effective_defence())

static func protection_multiplier(character_level: int, defence_rank: int) -> float:
	var rating := TUNING.defence_reduction * (defence_rank - 1) + TUNING.character_defence * (character_level - 1)
	return maxf(0.2, 1.0 / (1.0 + rating))

func walk_multiplier() -> float:
	return minf(1.75, 1.0 + TUNING.character_walk_speed * (level() - 1)) * journey.walk_multiplier()

func attack_multiplier() -> float:
	return minf(3.5, (1.0 + TUNING.character_attack_speed * (level() - 1) + TUNING.trained_attack_speed * (skill("attack_speed") - 1)) * journey.rhythm_multiplier())

func capture() -> Dictionary:
	return {
		"version": 3,
		"journey": journey.totals.duplicate(),
		"experience": experience,
		"practice": practice.duplicate(),
		"stat_points": stat_points,
		"stats": stats.duplicate(),
		"granted_level": _granted_level
	}

func restore(data: Dictionary, legacy_experience: int = 0) -> void:
	journey.restore(data.get("journey", {}))
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
	var rate: float = snappedf(attack_multiplier() / 0.04, 0.1)
	var dmg: int = int(12.0 * damage_multiplier("fist"))
	var result := {
		"level": level(),
		"experience": experience,
		"skills": {},
		"skill_caps": {"defence": bonus_capped("defence"), "attack_speed": bonus_capped("attack_speed")},
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
		var base_rank := rank(int(float(practice.get(name, 0)) / practice_cost_multiplier(name)))
		var earned := int(practice[name]) - threshold(base_rank) * practice_cost_multiplier(name)
		var practice_req := requirement(base_rank) * practice_cost_multiplier(name)
		var skill_pct := 100 if current == CAP else clampi(int(100.0 * earned / maxf(1.0, practice_req)), 0, 100)
		result.skills[name] = {"level": current, "percent": skill_pct}
	return result
