class_name ItemTooltipContent
extends RefCounted
## Presentation of authored item values; never changes item or actor state.

static func type_label(item: InventoryItem) -> String:
	var types := {"combat": "Weapon", "support": "Consumable · Support", "healing": "Consumable · Healing", "consumable": "Consumable", "currency": "Currency", "material": "Crafting material", "quest": "Quest item", "quest_item": "Quest item", "backpack": "Equipment · Backpack", "helmet": "Equipment · Helmet", "armor": "Equipment · Armor", "legs": "Equipment · Legs", "boots": "Equipment · Boots", "accessory": "Equipment · Accessory"}
	return types.get(item.category, item.category.capitalize() + " item")

static func details(item: InventoryItem) -> String:
	var lines: PackedStringArray = []
	if item.category in ["support", "healing", "consumable"] and item.healing_amount > 0:
		var recovery := "+%s HP" % number(item.healing_amount)
		if item.id == "apple": recovery += " / +50 SP"
		lines.append("%s over %ss" % [recovery, number(item.heal_duration)] if item.heal_duration > 0 else recovery)
		if item.id == "apple": lines.append("Stacks up to 5 · 250 HP/SP over 125s")
		lines.append("Support-slot cooldown · %ss" % number(item.cooldown))
	elif item.category == "backpack":
		lines.append("Bag capacity · %d slots" % item.storage_slots)
	elif item.damage_reduction > 0:
		lines.append("Damage taken −%s%% per piece" % number(item.damage_reduction * 100))
		var set_id := ""
		for candidate in [ApparelSetBonus.SOYPOD, ApparelSetBonus.NORI, ApparelSetBonus.CELESTIAL]:
			if item.id.begins_with(candidate + "_"): set_id = candidate
		if not set_id.is_empty(): lines.append(ApparelSetBonus.details(set_id))
	else:
		lines.append(item.description)
	return "\n".join(lines)

static func number(value: float) -> String:
	return String.num(value, 2).trim_suffix("0").trim_suffix("0").trim_suffix(".")
