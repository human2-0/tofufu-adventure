class_name ShopItemTile
extends Button

signal inspected(description: String)
signal inspection_ended

var item: InventoryItem

func setup(value: InventoryItem, footer: String, tile_size: Vector2) -> void:
	item = value
	custom_minimum_size = tile_size
	focus_mode = Control.FOCUS_ALL
	clip_contents = true
	_apply_style(false)
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 3
	content.offset_top = 3
	content.offset_right = -3
	content.offset_bottom = -3
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 1)
	add_child(content)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = InventoryIconQuality.for_slot(item.icon)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	content.add_child(icon)
	var item_name := Label.new()
	item_name.text = item.name
	item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_name.max_lines_visible = 2
	item_name.add_theme_font_size_override("font_size", 10)
	item_name.add_theme_color_override("font_color", Color("f2f2dc"))
	content.add_child(item_name)
	var note := Label.new()
	note.text = footer
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 8)
	note.add_theme_color_override("font_color", Color("eacb83"))
	content.add_child(note)
	tooltip_text = "%s\n%s" % [item.name, item.description]
	mouse_entered.connect(_inspect)
	focus_entered.connect(_inspect)
	mouse_exited.connect(_inspection_ended)
	focus_exited.connect(_inspection_ended)

func setup_empty(tile_size: Vector2) -> void:
	item = null
	custom_minimum_size = tile_size
	disabled = true
	focus_mode = Control.FOCUS_NONE
	_apply_style(true)
	var label := Label.new()
	label.text = "Empty"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color("829b96"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func _apply_style(empty: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("1a3834") if empty else Color("2a5548")
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(3)
	normal.border_color = Color("3e6055") if empty else Color("76ab87")
	normal.set_border_width_all(1)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("426d58")
	hover.border_color = Color("f5dfac")
	var focus := hover.duplicate() as StyleBoxFlat
	focus.set_border_width_all(2)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("focus", focus)
	add_theme_stylebox_override("pressed", hover)

func _inspect() -> void:
	if item != null: inspected.emit("%s · %s" % [item.name, item.description])

func _inspection_ended() -> void:
	if not has_focus() and not get_global_rect().has_point(get_global_mouse_position()):
		inspection_ended.emit()
