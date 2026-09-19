class_name PlayerInventory
extends RefCounted
## Ten-slot bag storing stacked items up to their max capacity.

signal changed

const CAPACITY: int = 10
var slots: Array[ItemStack] = []

func _init() -> void:
	slots.resize(CAPACITY)
	for i in CAPACITY:
		slots[i] = null

func has_space_for(item: InventoryItem, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false
	var needed := amount
	for stack in slots:
		if stack != null and stack.item != null and stack.item.id == item.id:
			needed -= (item.max_stack - stack.count)
			if needed <= 0:
				return true
		elif stack == null:
			needed -= item.max_stack
			if needed <= 0:
				return true
	return needed <= 0

func add_item(item: InventoryItem, amount: int = 1) -> int:
	if item == null or amount <= 0:
		return amount
	var remaining := amount
	# First pass: fill existing non-full stacks
	for stack in slots:
		if stack != null and stack.item != null and stack.item.id == item.id and stack.count < item.max_stack:
			remaining = stack.add(remaining)
			if remaining <= 0:
				break
	# Second pass: fill empty slots
	if remaining > 0:
		for i in CAPACITY:
			if slots[i] == null:
				var to_add := mini(item.max_stack, remaining)
				slots[i] = ItemStack.new(item, to_add)
				remaining -= to_add
				if remaining <= 0:
					break
	if remaining < amount:
		changed.emit()
	return remaining

func remove_item(item_id: String, amount: int = 1) -> int:
	var remaining := amount
	for i in range(CAPACITY - 1, -1, -1):
		var stack := slots[i]
		if stack != null and stack.item != null and stack.item.id == item_id:
			if stack.count <= remaining:
				remaining -= stack.count
				slots[i] = null
			else:
				stack.count -= remaining
				remaining = 0
			if remaining <= 0:
				break
	var removed := amount - remaining
	if removed > 0:
		changed.emit()
	return removed

func count_item(item_id: String) -> int:
	var total := 0
	for stack in slots:
		if stack != null and stack.item != null and stack.item.id == item_id:
			total += stack.count
	return total

func get_slot(index: int) -> ItemStack:
	if index >= 0 and index < CAPACITY:
		return slots[index]
	return null

func set_slot(index: int, stack: ItemStack) -> void:
	if index >= 0 and index < CAPACITY:
		slots[index] = stack
		changed.emit()

func swap_slots(from_idx: int, to_idx: int) -> void:
	if from_idx < 0 or from_idx >= CAPACITY or to_idx < 0 or to_idx >= CAPACITY or from_idx == to_idx:
		return
	var a := slots[from_idx]
	var b := slots[to_idx]
	if a != null and b != null and a.can_merge(b):
		var leftover := b.add(a.count)
		if leftover <= 0:
			slots[from_idx] = null
		else:
			a.count = leftover
	else:
		slots[from_idx] = b
		slots[to_idx] = a
	changed.emit()

func capture() -> Array:
	var data: Array = []
	for stack in slots:
		data.append(stack.capture() if stack != null else {})
	return data

func restore(data: Array) -> void:
	slots.resize(CAPACITY)
	for i in CAPACITY:
		if i < data.size() and not (data[i] as Dictionary).is_empty():
			slots[i] = ItemStack.restore(data[i])
		else:
			slots[i] = null
	changed.emit()
