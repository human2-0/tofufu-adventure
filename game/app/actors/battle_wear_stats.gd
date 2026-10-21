class_name BattleWearStats
extends RefCounted
## Earned match equipment modifies equal base stats; no adventure progression.

static func apply(combat: PlayerCombat, equipment: CharacterEquipment) -> void:
	var set_id := equipment.complete_set()
	var actor := combat.actor as Player
	actor.motor.walk_multiplier = ApparelSetBonus.walk(set_id)
	actor.motor.dash_distance_multiplier = ApparelSetBonus.dash(set_id)
	actor.motor.jump_launch_multiplier = ApparelSetBonus.jump_launch(set_id)
	var celestial := set_id == "celestial"
	if celestial:
		actor.motor.walk_multiplier = 1.10
		actor.motor.dash_distance_multiplier = 1.10
		actor.motor.jump_launch_multiplier = 1.10
	combat.sword_damage_multiplier *= 1.20 if celestial else minf(1.15, ApparelSetBonus.melee_damage(set_id))
	combat.fist_damage_multiplier *= 1.20 if celestial else minf(1.15, ApparelSetBonus.melee_damage(set_id))
	combat.gun.damage_multiplier *= 1.20 if celestial else minf(1.15, ApparelSetBonus.ranged_damage(set_id))
	combat.attack_speed_multiplier *= 1.12 if celestial else minf(1.10, ApparelSetBonus.attack_speed(set_id))
	combat.gun.attack_speed_multiplier *= 1.12 if celestial else minf(1.10, ApparelSetBonus.shooting_speed(set_id))
	combat.sotjet.attack_speed_multiplier = combat.gun.attack_speed_multiplier
	combat.sotjet.flow.attack_cadence_multiplier = combat.attack_speed_multiplier
	combat.sotjet.flow.damage_multiplier = 0.8 * combat.gun.damage_multiplier
	var protection := 0.0
	for slot in CharacterEquipment.APPAREL_SLOTS:
		var piece := equipment.get_slot(slot)
		if piece != null: protection += piece.item.damage_reduction
	if not set_id.is_empty(): protection = {"bright_leaf": 0.12, "dark_leaf": 0.20, "celestial": 0.25}[set_id]
	combat.owner_health.armor_multiplier = 1.0 - minf(0.25, protection)
