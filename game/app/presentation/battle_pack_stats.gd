class_name BattlePackStats
extends RefCounted
## Reports the actual temporary modifiers rather than adventure levels/training.

static func text(game: BattleRoyaleGame) -> String:
	var fighter := game.combat.fighters[game.local_slot]
	var combat := fighter.combat
	var bag := fighter.loadout.inventory
	var equipment := fighter.loadout.equipment
	var set_id := equipment.complete_set()
	var occupied := 0
	for stack in bag.slots:
		if stack != null: occupied += 1
	var melee := combat.sword_damage_multiplier * (1.2 if combat.equipment.pod_selected else 1.0)
	if combat.claws.selected: melee = combat.fist_damage_multiplier
	var lines := PackedStringArray()
	lines.append(TranslationServer.translate("HP %.0f / 100 · Armour %.0f / 50 · SP %.0f / 100") % [game.match_state.rows[game.local_slot][8], game.match_state.rows[game.local_slot][9], combat.vitals.current])
	lines.append(TranslationServer.translate("Backpack: %d / %d slots · Protection: %d%%") % [occupied, bag.capacity, roundi((1 - fighter.health.armor_multiplier) * 100)])
	lines.append(TranslationServer.translate("Run speed %.1f · Melee damage ×%.2f · Ranged damage ×%.2f\nMelee speed ×%.2f · Fire rate ×%.2f") % [fighter.actor.tuning.run_speed * fighter.actor.motor.walk_multiplier * fighter.actor.motor.equipment_walk_multiplier, melee, combat.gun.damage_multiplier, combat.melee_speed(), combat.gun.attack_speed_multiplier])
	if not set_id.is_empty(): lines.append(TranslationServer.translate("Complete set: %s") % TranslationServer.translate(ApparelSetBonus.name_for(set_id)))
	else:
		for family in ["bright_leaf", "dark_leaf", "celestial"]:
			var count := 0
			for name in CharacterEquipment.APPAREL_SLOTS:
				var stack := equipment.get_slot(name)
				if stack != null and stack.item.id.begins_with(family): count += 1
			lines.append("%s: %d / 4" % [TranslationServer.translate(ApparelSetBonus.name_for(family)), count])
	for name in CharacterEquipment.APPAREL_SLOTS:
		var piece := equipment.get_slot(name)
		if piece != null:
			lines.append(TranslationServer.translate("%s · Durability %.1f/50") % [TranslationServer.translate(piece.item.name), BattleArmourWear.remaining(piece)])
	var healing := game.pack.healing[game.local_slot]
	lines.append(TranslationServer.translate("Healing pending: %.0f HP · Apple regeneration: %.0fs") % [healing.active_heal_remaining, healing.apple_duration_remaining])
	lines.append(TranslationServer.translate("Everything in this backpack and all equipment disappear when this match ends."))
	return "\n\n".join(lines)
