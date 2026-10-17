class_name WorldWeaponOwnership
extends RefCounted
## Legacy equipment flags used by world-drop fallback composition.

static func owns(combat: PlayerCombat, id: String) -> bool:
	if id == AngelBowItem.ID: return combat.bow.selected
	if id == BengalPawsItem.ID: return combat.claws.selected
	if id in ["knife", "edamame_sword", "nori_katana", "celestial_sword"]: return combat.equipment.knife_owned
	if id in ["soy_gun", "soy_raygun"]: return combat.equipment.gun_owned
	if id == "sotjet": return combat.equipment.sotjet_owned
	return combat.equipment.staff_owned

static func set_owned(combat: PlayerCombat, id: String, value: bool) -> void:
	if id == AngelBowItem.ID:
		combat.bow.selected = value
	elif id == "knife":
		combat.equipment.knife_owned = value
		if not value: combat.equipment.knife_selected = false
	elif id == "soy_gun":
		combat.equipment.gun_owned = value
		if not value: combat.gun.selected = false
	elif id == "sotjet":
		combat.equipment.sotjet_owned = value
		if not value: combat.sotjet.selected = false
	elif id == "sproutwood_staff":
		combat.equipment.staff_owned = value
		if not value: combat.equipment.staff_selected = false

