class_name AngelBowItem
extends RefCounted

const ID: String = "angel_bow"

static func create() -> InventoryItem:
	var item := InventoryItem.new()
	item.id = ID
	item.name = "Fallen Angel Bow"
	item.description = "The Fallen Tofu Angels' ivory laurel bow. LMB: precise arrow, 2.5x soybean bullet damage (50 body / 100 head), then reload for 2s. Hold RMB 1.25s: 25 SP, double-damage arrow; an enemy hit bursts into a 3.5m flame sphere for 50 nearby damage (6s skill cooldown). Damage scales with shooting mastery."
	item.category = "combat"
	item.max_stack = 1
	item.weapon_power = 50
	item.weapon_level = 3
	item.healing_amount = 0
	item.icon = preload("res://assets/weapons/angel_bow/icon.png")
	return item
