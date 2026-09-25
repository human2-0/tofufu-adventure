class_name ChestTransfer
extends RefCounted
## Transactional bag <-> chest slot moves. Equipment never enters the seed bank.

static func valid_slot(source: Variant, id: Variant) -> bool:
	if not source is String or not (id is int or id is float):
		return false
	if not is_finite(float(id)) or float(id) != floor(float(id)):
		return false
	if source == "inventory":
		return id >= 0 and id < PlayerInventory.MAX_CAPACITY
	if source == "chest":
		return id >= 0 and id < ChestInventory.CAPACITY
	return false

static func apply(bag: PlayerInventory, chest: ChestInventory, src: String, src_id: Variant, dst: String, dst_id: Variant) -> bool:
	if bag == null or chest == null or not valid_slot(src, src_id) or not valid_slot(dst, dst_id):
		return false
	if (src == "inventory" and int(src_id) >= bag.capacity) or (dst == "inventory" and int(dst_id) >= bag.capacity): return false
	if src == dst and src_id == dst_id:
		return false
	var source_stack: ItemStack = _stack(bag, chest, src, int(src_id))
	if source_stack == null or source_stack.item == null:
		return false
	var destination_stack: ItemStack = _stack(bag, chest, dst, int(dst_id))
	if destination_stack != null and destination_stack.item != null and destination_stack.item.id == source_stack.item.id:
		var leftover := destination_stack.add(source_stack.count)
		if leftover == source_stack.count:
			return false
		if leftover == 0:
			_replace_slot(bag, chest, src, int(src_id), null)
		else:
			source_stack.count = leftover
		_notify(bag, chest)
		return true
	_replace_slot(bag, chest, src, int(src_id), destination_stack)
	_replace_slot(bag, chest, dst, int(dst_id), source_stack)
	_notify(bag, chest)
	return true

static func _stack(bag: PlayerInventory, chest: ChestInventory, source: String, index: int) -> ItemStack:
	return bag.slots[index] if source == "inventory" else chest.slots[index]

static func _replace_slot(bag: PlayerInventory, chest: ChestInventory, source: String, index: int, stack: ItemStack) -> void:
	if source == "inventory": bag.slots[index] = stack
	else: chest.slots[index] = stack

static func _notify(bag: PlayerInventory, chest: ChestInventory) -> void:
	bag.changed.emit()
	chest.changed.emit()
