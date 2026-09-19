class_name ItemStack
extends RefCounted
## Holds an item reference and a stack quantity.

var item: InventoryItem
var count: int = 1

func _init(p_item: InventoryItem = null, p_count: int = 1) -> void:
	item = p_item
	count = p_count

func duplicate_stack() -> ItemStack:
	return ItemStack.new(item, count)

func can_merge(other: ItemStack) -> bool:
	if other == null or item == null or other.item == null:
		return false
	return item.id == other.item.id and count < item.max_stack

func add(amount: int) -> int:
	if item == null:
		return amount
	var space := item.max_stack - count
	var taken := mini(space, amount)
	count += taken
	return amount - taken

func capture() -> Dictionary:
	if item == null or count <= 0:
		return {}
	return {
		"id": item.id,
		"count": count
	}

static func restore(data: Dictionary) -> ItemStack:
	if data.is_empty():
		return null
	var id: String = data.get("id", "")
	var count: int = int(data.get("count", 1))
	var item: InventoryItem
	if id == "soybean":
		item = InventoryItem.create_soybean()
	else:
		item = InventoryItem.new()
		item.id = id
		item.name = id.capitalize()
	return ItemStack.new(item, count)
