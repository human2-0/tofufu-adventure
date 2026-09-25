class_name InventoryWindow
extends CanvasLayer
## Modal frosted interface for 10 inventory slots and character equipment.

var transfer_handler: Callable
var conversion_handler: Callable

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
var _currency: Label
var _description: Label
var _inspected_button: InventorySlotButton
var _conversion_status: Label
var _refine_menu: PopupMenu
var _refine_slot: int = -1
var _refine_id: String = ""
var _bag_label: Label
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
	_inspected_button = null
	if _description != null: _description.text = "Hover or focus an item to see its description."
	if _conversion_status != null: _conversion_status.text = ""
	refresh()
	if not _inv_buttons.is_empty():
		_inv_buttons[0].call_deferred("grab_focus")
	opened.emit()

func close() -> void:
	if not visible: return
	if _refine_menu != null: _refine_menu.hide()
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
	style.bg_color = Color("173632f5")
	style.set_corner_radius_all(18)
	style.set_content_margin_all(22)
	style.border_color = Color("9bd58c")
	style.set_border_width_all(3)
	style.shadow_color = Color("07171599")
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 6)
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
	_currency = Label.new()
	_currency.add_theme_color_override("font_color", Color("eacb83"))
	_currency.add_theme_font_size_override("font_size", 12)
	header.add_child(_currency)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 30)
	vbox.add_child(body)
	_build_columns(body)
	_description = Label.new()
	_description.custom_minimum_size.y = 42
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.add_theme_font_size_override("font_size", 12)
	_description.add_theme_color_override("font_color", Color("e9f4dd"))
	_description.text = "Hover or focus an item to see its description."
	vbox.add_child(_description)
	_refine_menu = PopupMenu.new()
	_refine_menu.id_pressed.connect(_on_refine_menu_pressed)
	add_child(_refine_menu)
	_conversion_status = Label.new()
	_conversion_status.add_theme_color_override("font_color", Color("aee6d0"))
	_conversion_status.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_conversion_status)
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
		_watch_description(btn)
		eq_grid.add_child(btn)
		_eq_buttons[slot_name] = btn

	var inv_box := VBoxContainer.new()
	inv_box.add_theme_constant_override("separation", 12)
	body.add_child(inv_box)
	_bag_label = Label.new()
	_bag_label.add_theme_font_size_override("font_size", 12)
	_bag_label.add_theme_color_override("font_color", Color("aee6d0"))
	inv_box.add_child(_bag_label)
	var inv_grid := GridContainer.new()
	inv_grid.columns = 5
	inv_grid.add_theme_constant_override("h_separation", 8)
	inv_grid.add_theme_constant_override("v_separation", 8)
	inv_box.add_child(inv_grid)
	_inv_buttons.clear()
	for i in PlayerInventory.MAX_CAPACITY:
		var btn := InventorySlotButton.new()
		btn.source = "inventory"
		btn.slot_id = i
		btn.window_ref = self
		btn.custom_minimum_size = Vector2(60, 60)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
		btn.pressed.connect(_on_slot_clicked.bind("inventory", i))
		btn.transfer_requested.connect(execute_transfer)
		btn.context_requested.connect(_open_currency_menu)
		_watch_description(btn)
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
	if _currency != null:
		_currency.text = "E %d · M %d · W %d · T %d · G %d  " % [_count("edamame"), _count("mature_bean"), _count("tofu_white_chunk"), _count("toasted_tofu_chunk"), _count("golden_tofu_chunk")]
	if _bag_label != null:
		_bag_label.text = "BAG · %d SLOTS" % (inventory.capacity if inventory != null else 0)
	for slot_name in CharacterEquipment.SLOTS:
		var btn: InventorySlotButton = _eq_buttons.get(slot_name)
		if btn == null: continue
		var stack: ItemStack = equipment.get_slot(slot_name) if equipment != null else null
		var hotkey: String = slot_name.right(1) if slot_name.begins_with("combat_") else (str(int(slot_name.right(1)) + 2) if slot_name.begins_with("support_") else "")
		var slot_title: String = slot_name.capitalize()
		btn.present(stack, EquipmentLayout.ICONS[slot_name], slot_title, hotkey, _selected_source == "equipment" and _selected_slot == slot_name)
	for i in _inv_buttons.size():
		var btn: InventorySlotButton = _inv_buttons[i]
		btn.visible = inventory != null and i < inventory.capacity
		var stack: ItemStack = inventory.get_slot(i) if inventory != null else null
		btn.present(stack, null, "Bag slot %d" % (i + 1), "", _selected_source == "inventory" and _selected_slot == i)
	if _inspected_button != null: _show_description(_inspected_button)

func _watch_description(button: InventorySlotButton) -> void:
	button.mouse_entered.connect(_show_description.bind(button))
	button.focus_entered.connect(_show_description.bind(button))
	button.mouse_exited.connect(_hide_description.bind(button))
	button.focus_exited.connect(_hide_description.bind(button))

func _show_description(button: InventorySlotButton) -> void:
	_inspected_button = button
	if _description == null: return
	var stack := button.current_stack
	_description.text = "%s ×%d · %s" % [stack.item.name, stack.count, stack.item.description] if stack != null and stack.item != null else "Hover or focus an item to see its description."

func _hide_description(button: InventorySlotButton) -> void:
	if _inspected_button != button or button.has_focus() or button.get_global_rect().has_point(button.get_global_mouse_position()): return
	var focused := get_viewport().gui_get_focus_owner() as InventorySlotButton
	if focused != null and focused.window_ref == self:
		_show_description(focused)
		return
	_inspected_button = null
	if _description != null: _description.text = "Hover or focus an item to see its description."

func _count(id: String) -> int:
	return inventory.count_item(id) if inventory != null else 0

func _open_currency_menu(slot: int) -> void:
	if inventory == null: return
	var stack := inventory.get_slot(slot)
	if stack == null or stack.item == null or not CurrencyExchange.NEXT_TIER.has(stack.item.id): return
	_refine_slot = slot
	_refine_id = stack.item.id
	_refine_menu.clear()
	var target: InventoryItem = InventoryItem.currency(CurrencyExchange.NEXT_TIER[_refine_id])
	var cost := CurrencyExchange.required_count(_refine_id)
	var input_count := stack.count if cost == 1 else cost
	var output_count := stack.count if cost == 1 else 1
	_refine_menu.add_item("Refine %d → %d %s" % [input_count, output_count, target.name] if inventory.refining_unlocked else "Locked · Complete Tofu Dungeon", 0)
	_refine_menu.set_item_disabled(0, not inventory.refining_unlocked or stack.count < cost)
	_refine_menu.popup(Rect2i(Vector2i(get_viewport().get_mouse_position()), Vector2i(300, 40)))

func _on_refine_menu_pressed(_id: int) -> void:
	_request_conversion(_refine_slot, _refine_id)

func _request_conversion(slot: int, source_id: String) -> void:
	var message := "Refining is unavailable."
	if conversion_handler.is_valid():
		message = str(conversion_handler.call(slot, source_id))
	if _conversion_status != null: _conversion_status.text = message
	refresh()

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
