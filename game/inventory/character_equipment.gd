class_name CharacterEquipment
extends RefCounted
## Equipment slots for worn gear and active consumable/healing items.

signal changed

const SLOTS: Array[String] = [
	"helmet",
	"armor",
	"legs",
	"boots",
	"backpack",
	"accessory",
	"healing_1",
	"healing_2"
]

var slots: Dictionary = {}

func _init() -> void:
	for slot_name in SLOTS:
		slots[slot_name] = null

func can_equip(slot_name: String, stack: ItemStack) -> bool:
	if not slots.has(slot_name):
		return false
	if stack == null or stack.item == null:
		return true
	var category := stack.item.category
	if slot_name == "healing_1" or slot_name == "healing_2":
		return category == "healing" or category == "consumable"
	return category == slot_name

func get_slot(slot_name: String) -> ItemStack:
	return slots.get(slot_name, null)

func set_slot(slot_name: String, stack: ItemStack) -> void:
	if slots.has(slot_name):
		slots[slot_name] = stack
		changed.emit()

func equip(slot_name: String, stack: ItemStack) -> ItemStack:
	if not can_equip(slot_name, stack):
		return stack
	var old: ItemStack = slots.get(slot_name, null)
	slots[slot_name] = stack
	changed.emit()
	return old

func capture() -> Dictionary:
	var data: Dictionary = {}
	for slot_name in SLOTS:
		var stack: ItemStack = slots.get(slot_name)
		data[slot_name] = stack.capture() if stack != null else {}
	return data

func restore(data: Dictionary) -> void:
	for slot_name in SLOTS:
		var slot_data: Dictionary = data.get(slot_name, {})
		if not slot_data.is_empty():
			slots[slot_name] = ItemStack.restore(slot_data)
		else:
			slots[slot_name] = null
	changed.emit()
