class_name InventorySlotButton
extends Button
## Slot button supporting click selection and drag-and-drop transfers.

signal transfer_requested(src_source: String, src_id: Variant, dst_source: String, dst_id: Variant)

var source: String = "" # "inventory" or "equipment"
var slot_id: Variant = null
var current_stack: ItemStack = null
var window_ref: Variant = null

var _image: TextureRect
var _quantity: Label
var _hotkey: Label

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("183934") if state == "normal" else Color("28554a")
		style.border_color = Color("547e6e") if state == "normal" else Color("f4c75d")
		if state == "focus":
			style.bg_color = Color("fff0b4")
			style.shadow_color = Color("f4c75d88")
			style.shadow_size = 8
		style.set_border_width_all(1 if state == "normal" else 3)
		style.set_corner_radius_all(10)
		add_theme_stylebox_override(state, style)
	_image = TextureRect.new()
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_image)
	_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_image.offset_left = 14
	_image.offset_top = 14
	_image.offset_right = -14
	_image.offset_bottom = -14
	_quantity = Label.new()
	_quantity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quantity.add_theme_font_size_override("font_size", 12)
	_quantity.add_theme_color_override("font_shadow_color", Color("101c22"))
	_quantity.add_theme_constant_override("shadow_offset_x", 1)
	_quantity.add_theme_constant_override("shadow_offset_y", 1)
	_quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_quantity)
	_quantity.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_quantity.offset_left = 4
	_quantity.offset_right = -6
	_quantity.offset_top = -22
	_quantity.offset_bottom = -3
	_hotkey = Label.new()
	_hotkey.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hotkey.position = Vector2(7, 3)
	_hotkey.add_theme_font_size_override("font_size", 11)
	_hotkey.add_theme_color_override("font_color", Color("b6c5be"))
	add_child(_hotkey)

func present(stack: ItemStack, placeholder: Texture2D, title: String, hotkey: String, selected: bool) -> void:
	current_stack = stack
	if _image == null: return
	var occupied := stack != null and stack.item != null
	text = ""
	icon = null
	_image.texture = stack.item.icon if occupied and stack.item.icon != null else placeholder
	_image.modulate = Color.WHITE if occupied else Color(0.72, 0.78, 0.77, 0.65)
	_quantity.text = str(stack.count) if occupied and stack.count > 1 else ""
	_hotkey.text = hotkey
	tooltip_text = "%s · %s ×%d" % [title, stack.item.name, stack.count] if occupied else title + " · Empty"
	self_modulate = Color("ffe5a3") if selected else Color.WHITE
	var style := get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	style.border_color = Color("f4c75d") if selected else (Color("8fc598") if occupied else Color("547e6e"))
	style.set_border_width_all(3 if selected else 1)
	if selected:
		style.shadow_color = Color("f4c75d88")
		style.shadow_size = 8
	add_theme_stylebox_override("normal", style)

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
