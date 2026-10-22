class_name BattlePackWire
extends RefCounted
## Match-only catalog and bounded inventory/world loot values. IDs are one-based.
const CHESTS: int = 80
const DROPS: int = 768
const ITEMS: Array[String] = [
	"knife", "soy_gun", "edamame_sword", "nori_katana", "sproutwood_staff",
	"bengal_paws", "sotjet", "angel_bow", "celestial_sword", "celestial_staff",
	"soy_raygun", "bright_leaf_helmet", "bright_leaf_armor", "bright_leaf_legs", "bright_leaf_boots",
	"dark_leaf_helmet", "dark_leaf_armor", "dark_leaf_legs", "dark_leaf_boots", "celestial_helmet",
	"celestial_armor", "celestial_legs", "celestial_boots", "factory_backpack", "seed_satchel",
	"traveler_backpack", "apple", "soy_milk", "potato", "cucumber",
	"red_berries", "beetroot"
]
const CATEGORIES: Array[String] = [
	"combat", "combat", "combat", "combat", "combat",
	"combat", "combat", "combat", "combat", "combat",
	"combat", "helmet", "armor", "legs", "boots",
	"helmet", "armor", "legs", "boots", "helmet",
	"armor", "legs", "boots", "backpack", "backpack",
	"backpack", "support", "support", "support", "support",
	"support", "support"
]
const SLOTS: Array[String] = [
	"helmet", "armor", "legs", "boots", "backpack",
	"accessory", "combat_1", "combat_2", "support_1", "support_2",
	"support_3", "support_4"
]

static func stack(value: Variant, category: String = "") -> bool:
	if value is Array and value.is_empty(): return true
	if not value is Array or value.size() != 3: return false
	if not BattleProtocol.integer(value[0], 1, ITEMS.size()): return false
	var kind := CATEGORIES[int(value[0]) - 1]
	if not category.is_empty() and kind != category: return false
	var maximum := (10 if int(value[0]) == 28 else 50) if kind == "support" else 1
	if not BattleProtocol.integer(value[1], 1, maximum): return false
	return BattleProtocol.number(value[2], 0, 100)

static func packs(value: Variant) -> bool:
	if not value is Array or (value.size() < 2 or value.size() > BattleProtocol.CAPACITY): return false
	for row: Variant in value:
		if not row is Array or row.size() != 4 or not BattleProtocol.integer(row[0], 0, 1000000): return false
		if not row[1] is Array or row[1].size() not in [0, 10, 14, 20]: return false
		for item: Variant in row[1]:
			if not stack(item): return false
		if not row[2] is Array or row[2].size() != SLOTS.size(): return false
		for i in SLOTS.size():
			var category := "combat" if i in [6, 7] else ("support" if i >= 8 else SLOTS[i])
			if not stack(row[2][i], category): return false
		var bag: Array = row[2][4]
		if bag.is_empty():
			if not row[1].is_empty(): return false
			for item: Array in row[2]:
				if not item.is_empty(): return false
		elif row[1].size() != [10, 14, 20][int(bag[0]) - 24]: return false
		if not row[3] is Array or row[3].size() != 5: return false
		for i in 5:
			if not BattleProtocol.number(row[3][i], 0, [2, 2, 50, 100, 125][i]): return false
	return true

static func world(chests: Variant, drops: Variant) -> bool:
	if not chests is Array or chests.size() > CHESTS or not drops is Array or drops.size() > DROPS: return false
	for i in chests.size():
		var row: Variant = chests[i]
		if not row is Array or row.size() != 5 or not BattleProtocol.integer(row[0], i, i): return false
		if not BattleProtocol.integer(row[4], 0, 1) or not point(row): return false
	var seen: Dictionary = {}
	for row: Variant in drops:
		if not row is Array or row.size() != 7 or not BattleProtocol.integer(row[0], 0, 1000000): return false
		if seen.has(row[0]) or not point(row) or not BattleProtocol.integer(row[5], 0, 50): return false
		seen[row[0]] = true
		if not stack([row[4], maxi(1, int(row[5])), row[6]]): return false
	return true

static func point(row: Array) -> bool:
	for i in range(1, 4):
		if not BattleProtocol.number(row[i], -1000, 1000): return false
	return true
