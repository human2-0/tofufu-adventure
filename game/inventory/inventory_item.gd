class_name InventoryItem
extends Resource
## Authored definition for inventory and equipment items.

@export var id: String = ""
@export var name: String = ""
@export var icon: Texture2D
@export var max_stack: int = 100
@export var category: String = "general"
@export var healing_amount: float = 25.0
@export var heal_duration: float = 2.5
@export var cooldown: float = 2.0

static func create_soybean() -> InventoryItem:
	var item := InventoryItem.new()
	item.id = "soybean"
	item.name = "Soya Bean"
	item.icon = preload("res://assets/combat/soybean.svg")
	item.max_stack = 100
	item.category = "healing"
	item.healing_amount = 25.0
	item.heal_duration = 2.5
	item.cooldown = 2.0
	return item
