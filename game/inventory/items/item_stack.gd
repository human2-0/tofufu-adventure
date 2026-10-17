class_name ItemStack
extends RefCounted
## Holds an item reference and a stack quantity.

var item: InventoryItem
var count: int = 1
var reserve: float = 100.0
var enhanced: bool = false

func _init(p_item: InventoryItem = null, p_count: int = 1) -> void:
	item = p_item
	count = p_count

func duplicate_stack() -> ItemStack:
	var copy := ItemStack.new(item, count)
	copy.reserve = reserve
	copy.enhanced = enhanced
	return copy

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
		"count": count, "reserve": reserve, "enhanced": enhanced
	}

static func restore(data: Dictionary) -> ItemStack:
	if data.is_empty():
		return null
	var raw_id: Variant = data.get("id")
	var raw_count: Variant = data.get("count", 1)
	if not raw_id is String or raw_id.is_empty() or raw_id.length() > 64: return null
	if not (raw_count is int or raw_count is float): return null
	if not is_finite(float(raw_count)) or raw_count < 1 or raw_count > 100 or float(raw_count) != floor(float(raw_count)): return null
	var id: String = raw_id
	var restored_count: int = int(raw_count)
	var restored_item: InventoryItem
	restored_item = InventoryItem.from_id(id)
	if restored_item == null: return null
	if restored_count > restored_item.max_stack: return null
	var stack := ItemStack.new(restored_item, restored_count)
	var restored_reserve: Variant = data.get("reserve", 100.0)
	if not (restored_reserve is int or restored_reserve is float) or not is_finite(float(restored_reserve)) or restored_reserve < 0 or restored_reserve > 100: return null
	var upgraded: Variant = data.get("enhanced", false)
	if not upgraded is bool or (upgraded and restored_item.category != "combat"): return null
	stack.enhanced = upgraded
	stack.reserve = float(restored_reserve)
	return stack
