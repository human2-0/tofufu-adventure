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
	"combat_1", "combat_2",
	"support_1", "support_2", "support_3", "support_4"
]

var slots: Dictionary = {}

func _init() -> void:
	for slot_name in SLOTS:
		slots[slot_name] = null

func can_equip(slot_name: String, stack: ItemStack) -> bool:
	slot_name = slot_name.replace("healing_", "support_")
	if not slots.has(slot_name):
		return false
	if stack == null or stack.item == null:
		return true
	var category := stack.item.category
	if slot_name.begins_with("combat_"): return stack.item.category == "combat" and stack.count == 1
	if slot_name.begins_with("support_"):
		return category in ["healing", "consumable", "support"]
	return category == slot_name

func get_slot(slot_name: String) -> ItemStack:
	slot_name = slot_name.replace("healing_", "support_")
	return slots.get(slot_name, null)

func set_slot(slot_name: String, stack: ItemStack) -> void:
	slot_name = slot_name.replace("healing_", "support_")
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
		var slot_data: Variant = data.get(slot_name, data.get(slot_name.replace("support_", "healing_"), {}))
		if slot_data is Dictionary and not slot_data.is_empty():
			slots[slot_name] = ItemStack.restore(slot_data)
		else:
			slots[slot_name] = null
	changed.emit()
