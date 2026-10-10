class_name ApparelSetBonus
extends RefCounted
## Full-set modifiers. Item IDs stay stable for saved inventories.

const SOYPOD := "bright_leaf"
const NORI := "dark_leaf"
const CELESTIAL := "celestial"

static func walk(set_id: String) -> float:
	return 0.95 if set_id == SOYPOD else (1.10 if set_id == NORI else 1.0)

static func dash(set_id: String) -> float:
	return walk(set_id)

static func jump_launch(set_id: String) -> float:
	return 1.10 if set_id == NORI else 1.0

static func melee_damage(set_id: String) -> float:
	if set_id == CELESTIAL: return 1.25
	return 1.10 if set_id == SOYPOD else (0.90 if set_id == NORI else 1.0)

static func ranged_damage(set_id: String) -> float:
	if set_id == CELESTIAL: return 1.25
	return 0.95 if set_id == SOYPOD else 1.0

static func shooting_speed(set_id: String) -> float:
	if set_id == CELESTIAL: return 1.25
	return 1.10 if set_id == NORI else 1.0

static func attack_speed(set_id: String) -> float:
	return 1.25 if set_id == CELESTIAL else 1.0

static func drop_chance(set_id: String, base: float) -> float:
	return clampf(base * (1.10 if set_id == CELESTIAL else 1.0), 0.0, 1.0)

static func name_for(set_id: String) -> String:
	if set_id == CELESTIAL: return "Celestial"
	return "Soypod" if set_id == SOYPOD else ("Nori" if set_id == NORI else "")

static func details(set_id: String) -> String:
	if set_id == CELESTIAL: return "Full set: 50% damage reduction; all damage +25%; attack speed +25%; item drop chance +10%; a subtle divine aura."
	if set_id == SOYPOD:
		return "Full set: 10% damage reduction; melee damage +10%; gun and Soyjet damage -5%; walk speed and dash distance -5%."
	if set_id == NORI:
		return "Full set: 10% damage reduction; walk speed and dash distance +10%; jump launch speed +10% for higher jumps; melee damage -10%; gun fire rate and Soyjet stream speed +10%."
	return ""

static func celebration_text(set_id: String) -> String:
	if set_id == CELESTIAL: return "50% protection · Damage and attack speed +25%\nItem drop chance +10% · Divine aura"
	if set_id == SOYPOD:
		return "10% protection · Melee damage +10% · Ranged damage -5%\nWalk speed and dash distance -5%"
	if set_id == NORI:
		return "10% protection · Walk/dash +10% · Jump launch +10% (higher jumps)\nMelee damage -10% · Gun fire rate and Soyjet speed +10%"
	return ""
