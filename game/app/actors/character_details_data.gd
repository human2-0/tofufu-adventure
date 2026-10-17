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
	data.current_health = game.health.current
	data.current_stamina = combat.vitals.current
	data.bag_binding = GamePreferences.binding_text("toggle_inventory", "keyboard")
	data.info_binding = GamePreferences.binding_text("toggle_character", "keyboard")
	data.skill_benefits = _skill_benefits(progress)
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
	var walk := game.player.tuning.walk_speed * minf(1.75, 1.0 + tuning.character_walk_speed * (level - 1))
	var trained_walk := walk * progress.journey.walk_multiplier()
	rows.append(_row("Walking speed", walk, trained_walk - walk, trained_walk * (ApparelSetBonus.walk(set_id) * game.player.motor.equipment_walk_multiplier - 1.0), "m/s"))
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
	var natural_defence := 1.0 - CharacterProgress.protection_multiplier(level, 1 + int((level - 1) / float(tuning.character_levels_per_defence)))
	var trained_defence := 1.0 - progress.incoming_multiplier()
	var final_defence := 1.0 - progress.incoming_multiplier() * equipment.damage_multiplier()
	rows.append(_row("Damage reduction", natural_defence * 100, (trained_defence - natural_defence) * 100, (final_defence - trained_defence) * 100, "%"))
	var recovery := progress.journey.recovery_multiplier()
	rows.append(_row("Resting HP recovery", VitalRules.HP_REGEN * 100, VitalRules.HP_REGEN * (recovery - 1) * 100, 0, "%/s"))
	rows.append(_row("Stamina recovery", VitalRules.SP_REGEN * 100, VitalRules.SP_REGEN * (recovery - 1) * 100, 0, "%/s"))
	var descriptions := [
		"Your maximum health. The meter above shows how much health you have now.",
		"Your maximum stamina for attacks, guarding and movement. The meter above shows your current reserve.",
		"Ground walking speed before running or dashing. Explore on foot to earn permanent speed medals.",
		"Attack speed relative to the base rhythm: 100% is normal speed. Your held weapon and outfit affect this total.",
		"Damage from one normal unarmed hit, before the target's protection and critical hits.",
		"Damage from the currently held weapon's light hit or body shot, before the target's protection and critical hits. A stream is shown as damage per second.",
		"The share of incoming damage absorbed by your level, defence skill and worn armour together. These protections combine multiplicatively.",
		"Percentage of maximum health restored each second after 30 seconds without combat. Care medals improve recovery.",
		"Percentage of maximum stamina restored each second while recovery is available. Care medals improve recovery."
	]
	for index in rows.size(): rows[index].description = descriptions[index]
	return rows

static func _weapon(game: AdventureGame, natural: float, set_id: String) -> Dictionary:
	var combat := game.combat
	var stack := game.character_equipment.get_slot("combat_%d" % game.loadout.active_slot)
	var item := stack.item if stack != null else null
	if item == null or not game.character_equipment.can_equip("combat_%d" % game.loadout.active_slot, stack): return _row("Held weapon · none", 0, 0, 0, "DMG")
	var ranged := item.id in ["soy_gun", "soy_raygun", "sotjet", AngelBowItem.ID]
	var skill := "shooting" if ranged else "sword"
	var raw := combat.tuning.bean_damage if ranged else combat.tuning.light_damage
	if item.id == AngelBowItem.ID: raw *= AngelBow.DAMAGE_SCALE
	if item.id == BengalPawsItem.ID:
		skill = "fist"
		raw = combat.tuning.punch_damage
	var power := 1.0
	if item.id in ["sproutwood_staff", "celestial_staff"]: power = combat.tuning.staff_power / combat.tuning.light_damage
	elif item.id == "edamame_sword": power = 1.2
	elif item.id == BengalPawsItem.ID: power = BengalClaws.DAMAGE / combat.tuning.punch_damage
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

static func _skill_benefits(progress: CharacterProgress) -> Dictionary:
	var tuning := CharacterProgress.TUNING
	var damage := String.num(tuning.weapon_damage * 100, 2)
	return {
		"fist": "Next: +%s%% base fist damage." % damage,
		"sword": "Next: +%s%% base melee damage." % damage,
		"shooting": "Next: +%s%% base ranged damage; tighter aim." % damage,
		"defence": "Next: +%s%% skill protection." % String.num(maxf(0.0, progress.incoming_multiplier() - CharacterProgress.protection_multiplier(progress.level(), mini(99, progress.effective_defence() + 1))) * 100, 2),
		"attack_speed": "Next: +%s%% base attack pace." % String.num(maxf(0.0, minf(3.5, progress.attack_multiplier() + tuning.trained_attack_speed * progress.journey.rhythm_multiplier()) - progress.attack_multiplier()) * 100, 2),
		"magic": "Future mana abilities. No points can be spent here."
	}
