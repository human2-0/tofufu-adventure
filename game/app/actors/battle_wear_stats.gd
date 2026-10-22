class_name BattleWearStats
extends RefCounted
## Each intact piece grants a quarter of its family's match modifiers.
const BONUSES := {
	"bright_leaf": [0.12, -0.05, -0.05, 0.0, 0.10, -0.05, 0.0, 0.0],
	"dark_leaf": [0.20, 0.10, 0.10, 0.10, -0.10, 0.0, 0.0, 0.10],
	"celestial": [0.25, 0.10, 0.10, 0.10, 0.20, 0.20, 0.12, 0.12]
}

static func family(item: InventoryItem) -> String:
	return item.id.trim_suffix("_" + item.category)

static func apply(combat: PlayerCombat, equipment: CharacterEquipment) -> void:
	var modifiers: Array[float] = [0, 0, 0, 0, 0, 0, 0, 0]
	for name in CharacterEquipment.APPAREL_SLOTS:
		var piece := equipment.get_slot(name)
		if piece == null or piece.reserve <= 0: continue
		var bonus: Array = BONUSES.get(family(piece.item), [])
		for i in bonus.size(): modifiers[i] += float(bonus[i]) / 4.0
	var actor := combat.actor as Player
	actor.motor.walk_multiplier = 1.0 + modifiers[1]
	actor.motor.dash_distance_multiplier = 1.0 + modifiers[2]
	actor.motor.jump_launch_multiplier = 1.0 + modifiers[3]
	combat.sword_damage_multiplier *= 1.0 + modifiers[4]
	combat.fist_damage_multiplier *= 1.0 + modifiers[4]
	combat.gun.damage_multiplier *= 1.0 + modifiers[5]
	combat.attack_speed_multiplier *= 1.0 + modifiers[6]
	combat.gun.attack_speed_multiplier *= 1.0 + modifiers[7]
	combat.sotjet.attack_speed_multiplier = combat.gun.attack_speed_multiplier
	combat.sotjet.flow.attack_cadence_multiplier = combat.attack_speed_multiplier
	combat.sotjet.flow.damage_multiplier = 0.8 * combat.gun.damage_multiplier
	combat.owner_health.armor_multiplier = 1.0 - minf(0.25, modifiers[0])
