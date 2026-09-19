class_name InventoryWindow
extends CanvasLayer
## Modal frosted interface for 10 inventory slots and character equipment.

signal opened
signal closed
var inventory: PlayerInventory:
	set(val):
		if inventory != null and inventory.changed.is_connected(refresh): inventory.changed.disconnect(refresh)
		inventory = val
		if inventory != null: inventory.changed.connect(refresh)
		refresh()

var equipment: CharacterEquipment:
	set(val):
		if equipment != null and equipment.changed.is_connected(refresh): equipment.changed.disconnect(refresh)
		equipment = val
		if equipment != null: equipment.changed.connect(refresh)
		refresh()

var _inv_buttons: Array[InventorySlotButton] = []
var _eq_buttons: Dictionary = {}
var _selected_source: String = ""
var _selected_slot: Variant = null
func _ready() -> void:
	layer = 15
	visible = false
	_build_ui()

func toggle() -> void:
	if visible: close()
	else: open()

func open() -> void:
	visible = true
	_selected_source = ""
	_selected_slot = null
	refresh()
	opened.emit()

func close() -> void:
	visible = false
	_selected_source = ""
	_selected_slot = null
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("toggle_inventory") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE):
		close()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -310
	panel.offset_right = 310
	panel.offset_top = -195
	panel.offset_bottom = 195
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.14, 0.18, 0.94)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(14)
	style.border_color = Color(0.55, 0.8, 0.72, 0.45)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "INVENTORY & EQUIPMENT"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("f5dfac"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	vbox.add_child(body)
	_build_columns(body)

func _build_columns(body: HBoxContainer) -> void:
	var eq_box := VBoxContainer.new()
	eq_box.custom_minimum_size = Vector2(250, 0)
	body.add_child(eq_box)
	_label(eq_box, "EQUIPMENT", Color("aee6d0"))
	var eq_grid := GridContainer.new()
	eq_grid.columns = 2
	eq_grid.add_theme_constant_override("h_separation", 6)
	eq_grid.add_theme_constant_override("v_separation", 6)
	eq_box.add_child(eq_grid)
	for slot_name in CharacterEquipment.SLOTS:
		var btn := InventorySlotButton.new()
		btn.source = "equipment"
		btn.slot_id = slot_name
		btn.window_ref = self
		btn.custom_minimum_size = Vector2(120, 36)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_slot_clicked.bind("equipment", slot_name))
		btn.transfer_requested.connect(execute_transfer)
		eq_grid.add_child(btn)
		_eq_buttons[slot_name] = btn

	var inv_box := VBoxContainer.new()
	body.add_child(inv_box)
	_label(inv_box, "BAG (10 SLOTS)", Color("aee6d0"))
	var inv_grid := GridContainer.new()
	inv_grid.columns = 5
	inv_grid.add_theme_constant_override("h_separation", 8)
	inv_grid.add_theme_constant_override("v_separation", 8)
	inv_box.add_child(inv_grid)
	_inv_buttons.clear()
	for i in PlayerInventory.CAPACITY:
		var btn := InventorySlotButton.new()
		btn.source = "inventory"
		btn.slot_id = i
		btn.window_ref = self
		btn.custom_minimum_size = Vector2(58, 58)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
		btn.pressed.connect(_on_slot_clicked.bind("inventory", i))
		btn.transfer_requested.connect(execute_transfer)
		inv_grid.add_child(btn)
		_inv_buttons.append(btn)

func _label(parent: Control, text: String, col: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)

func refresh() -> void:
	if not is_inside_tree(): return
	for slot_name in CharacterEquipment.SLOTS:
		var btn: InventorySlotButton = _eq_buttons.get(slot_name)
		if btn == null: continue
		var stack: ItemStack = equipment.get_slot(slot_name) if equipment != null else null
		btn.current_stack = stack
		var prefix: String = "[5] " if slot_name == "healing_1" else ("[6] " if slot_name == "healing_2" else "")
		btn.text = ("%s%s (%d)" % [prefix, stack.item.name, stack.count]) if (stack != null and stack.item != null) else ("%s<%s>" % [prefix, slot_name.capitalize()])
		btn.icon = stack.item.icon if (stack != null and stack.item != null) else null
		btn.modulate = Color(1.4, 1.4, 0.8) if (_selected_source == "equipment" and _selected_slot == slot_name) else Color.WHITE
	for i in _inv_buttons.size():
		var btn: InventorySlotButton = _inv_buttons[i]
		var stack: ItemStack = inventory.get_slot(i) if inventory != null else null
		btn.current_stack = stack
		btn.icon = stack.item.icon if (stack != null and stack.item != null) else null
		btn.text = str(stack.count) if (stack != null and stack.count > 1) else ""
		btn.tooltip_text = ("%s (x%d)\nGradual +25 HP" % [stack.item.name, stack.count]) if (stack != null and stack.item != null) else ("Slot %d (Empty)" % (i + 1))
		btn.modulate = Color(1.4, 1.4, 0.8) if (_selected_source == "inventory" and _selected_slot == i) else Color.WHITE

func _on_slot_clicked(source: String, slot_id: Variant) -> void:
	if _selected_source.is_empty():
		var has_item: bool = (inventory.get_slot(int(slot_id)) != null) if source == "inventory" else (equipment.get_slot(str(slot_id)) != null)
		if has_item:
			_selected_source = source
			_selected_slot = slot_id
			refresh()
	else:
		if not (_selected_source == source and _selected_slot == slot_id):
			execute_transfer(_selected_source, _selected_slot, source, slot_id)
		_selected_source = ""
		_selected_slot = null
		refresh()

func execute_transfer(src: String, src_id: Variant, dst: String, dst_id: Variant) -> void:
	if inventory == null or equipment == null: return
	if src == "inventory" and dst == "inventory":
		inventory.swap_slots(int(src_id), int(dst_id))
	elif src == "inventory" and dst == "equipment":
		var stack := inventory.get_slot(int(src_id))
		if equipment.can_equip(str(dst_id), stack):
			inventory.set_slot(int(src_id), equipment.get_slot(str(dst_id)))
			equipment.set_slot(str(dst_id), stack)
	elif src == "equipment" and dst == "inventory":
		var inv_stack := inventory.get_slot(int(dst_id))
		if inv_stack == null or equipment.can_equip(str(src_id), inv_stack):
			var eq_stack := equipment.get_slot(str(src_id))
			equipment.set_slot(str(src_id), inv_stack)
			inventory.set_slot(int(dst_id), eq_stack)
	elif src == "equipment" and dst == "equipment":
		var s := equipment.get_slot(str(src_id))
		var d := equipment.get_slot(str(dst_id))
		if equipment.can_equip(str(dst_id), s) and equipment.can_equip(str(src_id), d):
			equipment.set_slot(str(dst_id), s)
			equipment.set_slot(str(src_id), d)
	refresh()
