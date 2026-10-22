class_name BattleHUDValues
extends RefCounted
## App supplies real item art and clocks; UI never imports combat/inventory rules.
static func loadout(game: BattleRoyaleGame) -> Dictionary:
	var fighter := game.combat.fighters[game.local_slot]
	var combat := fighter.combat
	var equipment := fighter.loadout.equipment
	var icons: Array = []
	var colors: Array = []
	for slot in ["combat_1", "combat_2"]:
		var stack := equipment.get_slot(slot)
		icons.append(stack.item.icon if stack != null else null)
		colors.append(BattleRarity.COLORS[BattleRarity.grade(BattleItems.weapon_kind(stack))])
	var support: Array = []
	var counts: Array = []
	for slot in ["support_1", "support_2", "support_3", "support_4"]:
		var stack := equipment.get_slot(slot)
		support.append(stack.item.icon if stack != null else null)
		counts.append(stack.count if stack != null else 0)
	var armour_icons: Array = []
	var integrity: Array = []
	for name in CharacterEquipment.APPAREL_SLOTS:
		var stack := equipment.get_slot(name)
		armour_icons.append(stack.item.icon if stack != null else null)
		integrity.append(stack.reserve / 100.0 if stack != null else -1)
	var reload := combat.bow.reload_remaining if combat.bow.selected else combat.gun.reload_remaining
	var reload_duration := AngelBow.RELOAD if combat.bow.selected else SoyGun.RELOAD_SECONDS
	var cooldown := 0.0
	if combat.claws.selected: cooldown = combat.claws.cooldown
	elif combat.bow.selected: cooldown = combat.bow.cooldown
	elif combat.equipment.nori_selected: cooldown = combat.plunge.cooldown
	elif combat.equipment.pod_selected: cooldown = combat.podburst.cooldown
	elif combat.equipment.staff_selected: cooldown = combat.rules.cooldown
	var buddy := game.local_slot ^ 1
	var duo := BattleOptions.duos(game.room.options) and buddy < game.bodies.size()
	return {"armour_icons": armour_icons, "integrity": integrity, "complete_set": not equipment.complete_set().is_empty(), "weapon_icons": icons, "weapon_colors": colors, "support_icons": support, "support_counts": counts,
		"ammo": int(combat.bow.reload_remaining <= 0) if combat.bow.selected else combat.gun.magazine,
		"magazine_capacity": 1 if combat.bow.selected else combat.gun.magazine_capacity, "ranged": combat.ranged_selected(), "reload": reload, "reload_progress": clampf(1 - reload / reload_duration, 0, 1), "special_remaining": cooldown,
		"partner_hp": game.match_state.rows[buddy][8] if duo else -1, "partner_name": game.name_of(buddy) if duo else ""}
