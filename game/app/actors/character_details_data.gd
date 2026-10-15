class_name CharacterDetailsData
extends RefCounted
## Derives honest display values from the same per-actor rules as combat.

static func build(game: AdventureGame) -> Dictionary:
	var progress := game.progression.progress
	var combat := game.combat
	var equipment := game.character_equipment
	var data := progress.display()
	var portrait := AtlasTexture.new()
	var visual := game.player.visuals
	portrait.atlas = visual.texture
	var frame_size := visual.texture.get_size() / Vector2(visual.hframes, visual.vframes)
	portrait.region = Rect2(Vector2(visual.frame_coords) * frame_size, frame_size)
	data.portrait = portrait
	data.rows = _rows(game)
	data.journey = progress.journey.display()
	data.gear = _gear(equipment, game.loadout.active_slot)
	data.condition = "Recovering after combat · %ds until HP regeneration" % ceili(combat.vitals.combat_remaining) if combat.vitals.combat_remaining > 0 else "At ease · Health and stamina recover naturally"
	data.title = "Growing companion"
	var best := 0
	for milestone: Dictionary in data.journey:
		if milestone.rank > best:
			best = milestone.rank
			data.title = milestone.name
	return data

static func _rows(game: AdventureGame) -> Array[Dictionary]:
	var progress := game.progression.progress
	var combat := game.combat
	var equipment := game.character_equipment
	var level := progress.level()
	var tuning := CharacterProgress.TUNING
	var set_id := equipment.complete_set()
	var rows: Array[Dictionary] = []
	rows.append(_row("Maximum health", game.health.maximum, 0, 0, "HP"))
	rows.append(_row("Maximum stamina", combat.vitals.maximum, 0, 0, "SP"))
	var walk := game.player.tuning.walk_speed * minf(1.25, 1.0 + tuning.character_walk_speed * (level - 1))
	var trained_walk := walk * progress.journey.walk_multiplier()
	rows.append(_row("Walking speed", walk, trained_walk - walk, trained_walk * (ApparelSetBonus.walk(set_id) - 1.0), "m/s"))
	var rate := 1.0 + tuning.character_attack_speed * (level - 1)
	var trained_rate := progress.attack_multiplier()
	var item_rate := ApparelSetBonus.attack_speed(set_id)
	if combat.gun.selected or combat.sotjet.selected: item_rate = ApparelSetBonus.shooting_speed(set_id)
	elif combat.equipment.nori_selected: item_rate *= combat.tuning.nori_speed
	rows.append(_row("Attack cadence", rate * 100, (trained_rate - rate) * 100, trained_rate * (item_rate - 1.0) * 100, "%"))
	var natural_damage := 1.0 + tuning.character_damage * (level - 1)
	var fist := combat.tuning.punch_damage * natural_damage
	var trained_fist := combat.tuning.punch_damage * progress.damage_multiplier("fist")
	rows.append(_row("Fist damage", fist, trained_fist - fist, trained_fist * (ApparelSetBonus.melee_damage(set_id) - 1.0), "DMG"))
	rows.append(_weapon(game, natural_damage, set_id))
	var natural_defence := 1.0 - (1.0 - tuning.character_defence * (level - 1)) * (1.0 - tuning.defence_reduction * int((level - 1) / float(tuning.character_levels_per_defence)))
	var trained_defence := 1.0 - progress.incoming_multiplier()
	var final_defence := 1.0 - progress.incoming_multiplier() * equipment.damage_multiplier()
	rows.append(_row("Damage reduction", natural_defence * 100, (trained_defence - natural_defence) * 100, (final_defence - trained_defence) * 100, "%"))
	var recovery := progress.journey.recovery_multiplier()
	rows.append(_row("Resting HP recovery", VitalRules.HP_REGEN * 100, VitalRules.HP_REGEN * (recovery - 1) * 100, 0, "%/s"))
	rows.append(_row("Stamina recovery", VitalRules.SP_REGEN * 100, VitalRules.SP_REGEN * (recovery - 1) * 100, 0, "%/s"))
	return rows

static func _weapon(game: AdventureGame, natural: float, set_id: String) -> Dictionary:
	var combat := game.combat
	var stack := game.character_equipment.get_slot("combat_%d" % game.loadout.active_slot)
	var item := stack.item if stack != null else null
	if item == null or not game.character_equipment.can_equip("combat_%d" % game.loadout.active_slot, stack): return _row("Held weapon · none", 0, 0, 0, "DMG")
	var ranged := item.id in ["soy_gun", "soy_raygun", "sotjet"]
	var skill := "shooting" if ranged else "sword"
	var raw := combat.tuning.bean_damage if ranged else combat.tuning.light_damage
	var power := 1.0
	if item.id in ["sproutwood_staff", "celestial_staff"]: power = combat.tuning.staff_power / combat.tuning.light_damage
	elif item.id == "edamame_sword": power = 1.2
	var base := raw * natural
	var trained := raw * game.progression.progress.damage_multiplier(skill)
	var bonus := ApparelSetBonus.ranged_damage(set_id) if ranged else ApparelSetBonus.melee_damage(set_id)
	var actual := trained * power * bonus * MagicalTofufu.power(stack)
	var label := "Held weapon · light hit" if not ranged else "Held weapon · body hit"
	if item.id == "sotjet":
		base = combat.sotjet.flow.tuning.damage_per_second * natural
		trained = combat.sotjet.flow.tuning.damage_per_second * game.progression.progress.damage_multiplier(skill)
		actual = trained * bonus * MagicalTofufu.power(stack) * combat.sotjet.flow.attack_cadence_multiplier
		label = "Held weapon · stream /s"
	return _row(label, base, trained - base, actual - trained, "DMG")

static func _row(title: String, base: float, training: float, gear: float, unit: String) -> Dictionary:
	return {"title": title, "base": base, "training": maxf(0, training), "gear": gear, "total": base + training + gear, "unit": unit}

static func _gear(equipment: CharacterEquipment, active_slot: int) -> String:
	var lines: PackedStringArray = []
	var held := equipment.get_slot("combat_%d" % active_slot)
	var held_name := held.item.name if held != null else "Fists"
	if held != null and held.enhanced: held_name = "%s · Enhanced" % held_name
	lines.append("Held: %s" % held_name)
	for slot in CharacterEquipment.APPAREL_SLOTS:
		var stack := equipment.get_slot(slot)
		if stack != null and equipment.can_equip(slot, stack):
			lines.append("%s · %s%% protection" % [stack.item.name, String.num(stack.item.damage_reduction * 100, 1)])
	var set_id := equipment.complete_set()
	if not set_id.is_empty(): lines.append(ApparelSetBonus.details(set_id))
	return "\n".join(lines)
