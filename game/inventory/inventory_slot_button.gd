class_name InventorySlotButton
extends Button
## Slot button supporting click selection and drag-and-drop transfers.

signal transfer_requested(src_source: String, src_id: Variant, dst_source: String, dst_id: Variant)

var source: String = "" # "inventory" or "equipment"
var slot_id: Variant = null
var current_stack: ItemStack = null
var window_ref: Variant = null

func _get_drag_data(_at_position: Vector2) -> Variant:
	if current_stack == null or current_stack.item == null:
		return null
	var preview := TextureRect.new()
	preview.texture = current_stack.item.icon
	preview.custom_minimum_size = Vector2(40, 40)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	set_drag_preview(preview)
	return {
		"source": source,
		"slot_id": slot_id,
		"stack": current_stack
	}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary) or not data.has("source") or not data.has("slot_id"):
		return false
	var incoming: ItemStack = data.get("stack")
	if incoming == null:
		return false
	if source == "equipment" and window_ref != null and window_ref.equipment != null:
		return window_ref.equipment.can_equip(str(slot_id), incoming)
	elif source == "inventory" and data.get("source") == "equipment" and window_ref != null:
		if current_stack != null and not window_ref.equipment.can_equip(str(data.get("slot_id")), current_stack):
			return false
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not (data is Dictionary):
		return
	transfer_requested.emit(data.get("source"), data.get("slot_id"), source, slot_id)
