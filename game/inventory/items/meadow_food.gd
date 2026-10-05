class_name MeadowFood
extends RefCounted
## Small authored food definitions. Values are initial countryside balance.

const NAMES := {"potato": "Potato", "cucumber": "Cucumber", "red_berries": "Red Berries", "beetroot": "Beetroot", "forest_mushroom": "Forest Mushroom"}

static func create(id: String) -> InventoryItem:
	if not NAMES.has(id): return null
	var item := InventoryItem.new()
	item.id = id
	item.name = NAMES[id]
	item.max_stack = 50
	item.category = "material" if id == "forest_mushroom" else "support"
	item.healing_amount = 0 if id == "forest_mushroom" else 15
	item.heal_duration = 5
	item.description = "A forest ingredient gathered in the northern woodland." if id == "forest_mushroom" else "Fresh village produce. Eat to recover 15 HP over 5 seconds."
	item.icon = load("res://game/inventory/icons/%s.svg" % id)
	return item
