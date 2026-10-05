class_name ChestInventory
extends RefCounted
## Fixed, persisted storage for a world chest bank.

signal changed

const CAPACITY: int = 24
var slots: Array[ItemStack] = []

func _init() -> void:
	slots.resize(CAPACITY)
	for index in CAPACITY:
		slots[index] = null

func get_slot(index: int) -> ItemStack:
	return slots[index] if index >= 0 and index < CAPACITY else null

func set_slot(index: int, stack: ItemStack) -> void:
	if index < 0 or index >= CAPACITY:
		return
	slots[index] = stack
	changed.emit()

func occupied_slots() -> int:
	var occupied := 0
	for stack in slots:
		if stack != null and stack.item != null:
			occupied += 1
	return occupied

func capture() -> Array:
	var data: Array = []
	for stack in slots:
		data.append(stack.capture() if stack != null else {})
	return data

func restore(data: Variant) -> void:
	slots.resize(CAPACITY)
	var rows: Array = data if data is Array else []
	for index in CAPACITY:
		slots[index] = ItemStack.restore(rows[index]) if index < rows.size() and rows[index] is Dictionary else null
	changed.emit()
