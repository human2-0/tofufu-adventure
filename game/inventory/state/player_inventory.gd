class_name PlayerInventory
extends RefCounted
## Backpack-owned inventory with a ten-slot factory pack and expandable capacity.

signal changed

const CAPACITY: int = 10
const MAX_CAPACITY: int = 20
var slots: Array[ItemStack] = []
var capacity: int = CAPACITY
var pending_items: Array[ItemStack] = []
var refining_unlocked: bool = false

func _init() -> void:
	slots.resize(CAPACITY)
	for i in CAPACITY:
		slots[i] = null

func set_capacity(value: int) -> void:
	var next := clampi(value, 0, MAX_CAPACITY)
	if capacity == next: return
	slots.resize(next)
	if next > capacity:
		for index in range(capacity, next): slots[index] = null
	capacity = next
	changed.emit()

func has_overflow_for(next_capacity: int) -> bool:
	for index in range(clampi(next_capacity, 0, capacity), capacity):
		if slots[index] != null: return true
	return false

func clear() -> void:
	for index in capacity: slots[index] = null
	changed.emit()

func has_space_for(item: InventoryItem, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false
	var needed := amount
	for index in capacity:
		var stack := slots[index]
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
	for index in capacity:
		var stack := slots[index]
		if stack != null and stack.item != null and stack.item.id == item.id and stack.count < item.max_stack:
			remaining = stack.add(remaining)
			if remaining <= 0:
				break
	# Second pass: fill empty slots
	if remaining > 0:
		for i in capacity:
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
	for i in range(capacity - 1, -1, -1):
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
	for index in capacity:
		var stack := slots[index]
		if stack != null and stack.item != null and stack.item.id == item_id:
			total += stack.count
	return total

func get_slot(index: int) -> ItemStack:
	if index >= 0 and index < capacity:
		return slots[index]
	return null

func set_slot(index: int, stack: ItemStack) -> void:
	if index >= 0 and index < capacity:
		slots[index] = stack
		changed.emit()

func swap_slots(from_idx: int, to_idx: int) -> void:
	if from_idx < 0 or from_idx >= capacity or to_idx < 0 or to_idx >= capacity or from_idx == to_idx:
		return
	var a := slots[from_idx]
	var b := slots[to_idx]
	if a != null and b != null and a.item.id == b.item.id and b.item.max_stack > 1:
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
	for index in capacity:
		var stack := slots[index]
		data.append(stack.capture() if stack != null else {})
	return data

func restore(data: Array) -> void:
	slots.resize(capacity)
	for i in capacity:
		if i < data.size() and data[i] is Dictionary and not data[i].is_empty():
			slots[i] = ItemStack.restore(data[i])
		else:
			slots[i] = null
	changed.emit()

func restore_pending(value: Variant) -> void:
	pending_items.clear()
	if not value is Array: return
	for row: Variant in value.slice(0, 32):
		if not row is Dictionary: continue
		var stack := ItemStack.restore(row)
		if stack != null: pending_items.append(stack)
