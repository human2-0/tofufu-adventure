class_name ApparelSetBonus
extends RefCounted
## Full-set modifiers. Item IDs stay stable for saved inventories.

const SOYPOD := "bright_leaf"
const NORI := "dark_leaf"

static func walk(set_id: String) -> float:
	return 0.95 if set_id == SOYPOD else (1.10 if set_id == NORI else 1.0)

static func dash(set_id: String) -> float:
	return walk(set_id)

static func jump_launch(set_id: String) -> float:
	return 1.10 if set_id == NORI else 1.0

static func melee_damage(set_id: String) -> float:
	return 1.10 if set_id == SOYPOD else (0.90 if set_id == NORI else 1.0)

static func ranged_damage(set_id: String) -> float:
	return 0.95 if set_id == SOYPOD else 1.0

static func shooting_speed(set_id: String) -> float:
	return 1.10 if set_id == NORI else 1.0

static func name_for(set_id: String) -> String:
	return "Soypod" if set_id == SOYPOD else ("Nori" if set_id == NORI else "")

static func details(set_id: String) -> String:
	if set_id == SOYPOD:
		return "Full set: 10% damage reduction; melee damage +10%; gun and Soyjet damage -5%; walk speed and dash distance -5%."
	if set_id == NORI:
		return "Full set: 10% damage reduction; walk speed and dash distance +10%; jump launch speed +10% for higher jumps; melee damage -10%; gun fire rate and Soyjet stream speed +10%."
	return ""

static func celebration_text(set_id: String) -> String:
	if set_id == SOYPOD:
		return "10% protection · Melee damage +10% · Ranged damage -5%\nWalk speed and dash distance -5%"
	if set_id == NORI:
		return "10% protection · Walk/dash +10% · Jump launch +10% (higher jumps)\nMelee damage -10% · Gun fire rate and Soyjet speed +10%"
	return ""
