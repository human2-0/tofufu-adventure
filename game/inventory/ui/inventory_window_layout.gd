class_name InventoryWindowLayout
extends RefCounted
## Builds inventory controls; intent callbacks and contents remain on the window.

static func build_ui(window: InventoryWindow) -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	window.add_child(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var eq_box := make_dock(window, root, false, 240)
	label(window, eq_box, "EQUIPMENT", Color("aee6d0"))
	build_equipment(window, eq_box)
	label(window, eq_box, "1–2 Combat · 3–6 Support", Color("829b96"))
	var vbox := make_dock(window, root, true, 350)
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "BACKPACK"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("f5dfac"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	window._currency = Label.new()
	window._currency.add_theme_color_override("font_color", Color("eacb83"))
	window._currency.add_theme_font_size_override("font_size", 12)
	window._currency.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(window._currency)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.pressed.connect(window.close)
	header.add_child(close_btn)

	build_backpack(window, vbox)
	_details(window, vbox)

static func _details(window: InventoryWindow, vbox: VBoxContainer) -> void:
	window._description = Label.new()
	window._description.custom_minimum_size = Vector2(0, 66)
	window._description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	window._description.add_theme_font_size_override("font_size", 12)
	window._description.add_theme_color_override("font_color", Color("e9f4dd"))
	window._description.text = "Hover or focus an item to see its description."
	vbox.add_child(window._description)
	window._refine_menu = PopupMenu.new()
	window._refine_menu.id_pressed.connect(window._on_refine_menu_pressed)
	window.add_child(window._refine_menu)
	window._conversion_status = Label.new()
	window._conversion_status.add_theme_color_override("font_color", Color("aee6d0"))
	window._conversion_status.add_theme_font_size_override("font_size", 12)
	vbox.add_child(window._conversion_status)
	var drop_button := Button.new()
	drop_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	drop_button.text = "Drop selected stack"
	drop_button.pressed.connect(func() -> void:
		if not window._selected_source.is_empty():
			window.request_drop(window._selected_source, window._selected_slot))
	vbox.add_child(drop_button)

static func make_dock(window: InventoryWindow, root: Control, right: bool, width: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.name = "BackpackDock" if right else "EquipmentDock"
	root.add_child(panel)
	if right: window._backpack_dock = panel
	else: window._equipment_dock = panel
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT if right else Control.PRESET_CENTER_LEFT)
	panel.offset_left = -width - 16 if right else 16
	panel.offset_right = -16 if right else width + 16
	panel.offset_top = -210
	panel.offset_bottom = 210
	var style := StyleBoxFlat.new()
	style.bg_color = Color("173632ef")
	style.set_corner_radius_all(14)
	style.set_content_margin_all(14)
	style.border_color = Color("9bd58c")
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	return box

static func build_equipment(window: InventoryWindow, eq_box: VBoxContainer) -> void:
	var eq_grid := EquipmentLayout.new()
	eq_box.add_child(eq_grid)
	for slot_name in CharacterEquipment.SLOTS:
		var btn := InventorySlotButton.new()
		btn.source = "equipment"
		btn.slot_id = slot_name
		btn.window_ref = window
		var edge: float = 46 if slot_name.begins_with("support_") else 56
		btn.custom_minimum_size = Vector2(edge, edge)
		btn.size = Vector2(edge, edge)
		btn.position = EquipmentLayout.POSITIONS[slot_name] * EquipmentLayout.COMPACT_SCALE
		btn.pressed.connect(window._on_slot_clicked.bind("equipment", slot_name))
		btn.transfer_requested.connect(window.execute_transfer)
		btn.quick_transfer_requested.connect(window.request_quick_transfer)
		InventoryWindowDescriptions.watch(window, btn)
		eq_grid.add_child(btn)
		window._eq_buttons[slot_name] = btn

static func build_backpack(window: InventoryWindow, inv_box: VBoxContainer) -> void:
	window._bag_label = Label.new()
	window._bag_label.add_theme_font_size_override("font_size", 12)
	window._bag_label.add_theme_color_override("font_color", Color("aee6d0"))
	inv_box.add_child(window._bag_label)
	var inv_grid := GridContainer.new()
	inv_grid.columns = 5
	inv_grid.add_theme_constant_override("h_separation", 8)
	inv_grid.add_theme_constant_override("v_separation", 8)
	inv_box.add_child(inv_grid)
	window._inv_buttons.clear()
	for i in PlayerInventory.MAX_CAPACITY:
		var btn := InventorySlotButton.new()
		btn.source = "inventory"
		btn.slot_id = i
		btn.window_ref = window
		btn.custom_minimum_size = Vector2(56, 56)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
		btn.pressed.connect(window._on_slot_clicked.bind("inventory", i))
		btn.transfer_requested.connect(window.execute_transfer)
		btn.quick_transfer_requested.connect(window.request_quick_transfer)
		btn.context_requested.connect(window._on_slot_context)
		InventoryWindowDescriptions.watch(window, btn)
		inv_grid.add_child(btn)
		window._inv_buttons.append(btn)
	label(window, inv_box, "Shift-click near the Seed Bank to store. Drag outside to drop.\nI / B / Esc · Close backpack", Color("829b96"))

static func label(window: InventoryWindow, parent: Control, text: String, col: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
