class_name InventoryWindow
extends CanvasLayer
## Modal frosted interface for 10 inventory slots and character equipment.

var transfer_handler: Callable

signal drop_requested(source: String, id: Variant)

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
var _coins: Label
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
	if visible: return
	visible = true
	_selected_source = ""
	_selected_slot = null
	refresh()
	opened.emit()

func close() -> void:
	if not visible: return
	visible = false
	_selected_source = ""
	_selected_slot = null
	closed.emit()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -350
	panel.offset_right = 350
	panel.offset_top = -265
	panel.offset_bottom = 265
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.14, 0.18, 0.94)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(22)
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
	_coins = Label.new()
	_coins.add_theme_color_override("font_color", Color("eacb83"))
	_coins.add_theme_font_size_override("font_size", 12)
	header.add_child(_coins)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 30)
	vbox.add_child(body)
	_build_columns(body)
	var drop_button := Button.new()
	drop_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	drop_button.text = "Drop selected stack"
	drop_button.pressed.connect(func() -> void:
		if not _selected_source.is_empty():
			drop_requested.emit(_selected_source, _selected_slot)
			_selected_source = ""
			refresh())
	vbox.add_child(drop_button)

func _build_columns(body: HBoxContainer) -> void:
	var eq_box := VBoxContainer.new()
	eq_box.custom_minimum_size = Vector2(264, 0)
	eq_box.add_theme_constant_override("separation", 12)
	body.add_child(eq_box)
	_label(eq_box, "EQUIPMENT", Color("aee6d0"))
	var eq_grid := EquipmentLayout.new()
	eq_box.add_child(eq_grid)
	for slot_name in CharacterEquipment.SLOTS:
		var btn := InventorySlotButton.new()
		btn.source = "equipment"
		btn.slot_id = slot_name
		btn.window_ref = self
		var edge: float = 60 if slot_name.begins_with("support_") else 72
		btn.custom_minimum_size = Vector2(edge, edge)
		btn.size = Vector2(edge, edge)
		btn.position = EquipmentLayout.POSITIONS[slot_name]
		btn.pressed.connect(_on_slot_clicked.bind("equipment", slot_name))
		btn.transfer_requested.connect(execute_transfer)
		eq_grid.add_child(btn)
		_eq_buttons[slot_name] = btn

	var inv_box := VBoxContainer.new()
	inv_box.add_theme_constant_override("separation", 12)
	body.add_child(inv_box)
	_label(inv_box, "BAG · 10 SLOTS", Color("aee6d0"))
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
		btn.custom_minimum_size = Vector2(60, 60)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
		btn.pressed.connect(_on_slot_clicked.bind("inventory", i))
		btn.transfer_requested.connect(execute_transfer)
		inv_grid.add_child(btn)
		_inv_buttons.append(btn)
	_label(inv_box, "Drag an item to equip it.\nOr select an item, then a slot.", Color("829b96"))

func _label(parent: Control, text: String, col: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)

func refresh() -> void:
	if not is_inside_tree(): return
	if _coins != null: _coins.text = "%d coins  " % (inventory.coins if inventory != null else 0)
	for slot_name in CharacterEquipment.SLOTS:
		var btn: InventorySlotButton = _eq_buttons.get(slot_name)
		if btn == null: continue
		var stack: ItemStack = equipment.get_slot(slot_name) if equipment != null else null
		var hotkey: String = slot_name.right(1) if slot_name.begins_with("combat_") else (str(int(slot_name.right(1)) + 2) if slot_name.begins_with("support_") else "")
		var slot_title: String = slot_name.capitalize()
		btn.present(stack, EquipmentLayout.ICONS[slot_name], slot_title, hotkey, _selected_source == "equipment" and _selected_slot == slot_name)
	for i in _inv_buttons.size():
		var btn: InventorySlotButton = _inv_buttons[i]
		var stack: ItemStack = inventory.get_slot(i) if inventory != null else null
		btn.present(stack, null, "Bag slot %d" % (i + 1), "", _selected_source == "inventory" and _selected_slot == i)

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
	if transfer_handler.is_valid():
		transfer_handler.call(src, src_id, dst, dst_id)
	else:
		InventoryTransfer.apply(inventory, equipment, src, src_id, dst, dst_id)
	refresh()
