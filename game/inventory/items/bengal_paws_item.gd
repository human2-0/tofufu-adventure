class_name BengalPawsItem
extends RefCounted
## Rare training weapon, also stocked in the testing shop.

const ID: String = "bengal_paws"
const DROP_CHANCE: float = 0.01
const ICON: Texture2D = preload("res://assets/weapons/bengal_paws/paws.png")

static func create() -> InventoryItem:
	var item := InventoryItem.new()
	item.id = ID
	item.name = "Bengal Paws"
	item.description = "Rare Bengal drop (1%). Lv. 15. Hits train fists + attack speed. Hold RMB 2s: dash hits for 1x damage, then a separate 3x rift cut with 4s paralysis. 20 SP; 8s cooldown. Held: +15% walk/run speed; -25% dash cooldown and SP cost. Sold in the testing shop."
	item.category = "combat"
	item.max_stack = 1
	item.healing_amount = 0
	item.required_level = 15
	item.weapon_level = 4
	item.weapon_power = 16
	item.icon = ICON
	return item
