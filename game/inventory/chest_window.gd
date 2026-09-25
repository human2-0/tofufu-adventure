class_name ChestWindow
extends CanvasLayer
## Focused modal for moving gathered items into the seed bank's 24 chest slots.

signal closed

var transfer_handler: Callable

var inventory: PlayerInventory:
	set(value):
		if inventory != null and inventory.changed.is_connected(refresh): inventory.changed.disconnect(refresh)
		inventory = value
		if inventory != null: inventory.changed.connect(refresh)
		refresh()

var chest: ChestInventory:
	set(value):
		if chest != null and chest.changed.is_connected(refresh): chest.changed.disconnect(refresh)
		chest = value
		if chest != null: chest.changed.connect(refresh)
		refresh()

var _bag_buttons: Array[InventorySlotButton] = []
var _chest_buttons: Array[InventorySlotButton] = []
var _status: Label
var _description: Label
var _inspected_button: InventorySlotButton
var _selected_source := ""
var _selected_slot: Variant = null

func _ready() -> void:
	layer = 16
	visible = false
	_build_ui()

func open() -> void:
	if visible: return
	visible = true
	_selected_source = ""
	_selected_slot = null
	_inspected_button = null
	if _description != null: _description.text = "Hover or focus an item to see its description."
	refresh()
	if not _bag_buttons.is_empty(): _bag_buttons[0].call_deferred("grab_focus")

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
	panel.offset_left = -400
	panel.offset_right = 400
	panel.offset_top = -265
	panel.offset_bottom = 265
	var style := StyleBoxFlat.new()
	style.bg_color = Color("173632f7")
	style.border_color = Color("d9b566")
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = "SEED BANK · SAFE STORAGE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("f5dfac"))
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "✕"
	close_button.pressed.connect(close)
	header.add_child(close_button)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 32)
	content.add_child(body)
	_build_grid(body, "YOUR BAG · UP TO 20 SLOTS", "inventory", PlayerInventory.MAX_CAPACITY, 5, _bag_buttons)
	_build_grid(body, "CHEST WALL · 24 SLOTS", "chest", ChestInventory.CAPACITY, 6, _chest_buttons)
	_description = Label.new()
	_description.custom_minimum_size.y = 42
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.add_theme_color_override("font_color", Color("e9f4dd"))
	_description.text = "Hover or focus an item to see its description."
	content.add_child(_description)
	_status = Label.new()
	_status.add_theme_color_override("font_color", Color("aee6d0"))
	content.add_child(_status)
	var guide := Label.new()
	guide.text = "Drag items between slots, or select one slot then another. Stored items are included in your adventure save."
	guide.add_theme_color_override("font_color", Color("9fb8ac"))
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(guide)

func _build_grid(parent: HBoxContainer, title: String, source: String, capacity: int, columns: int, buttons: Array[InventorySlotButton]) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	parent.add_child(box)
	var label := Label.new()
	label.text = title
	label.add_theme_color_override("font_color", Color("aee6d0"))
	box.add_child(label)
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	box.add_child(grid)
	for index in capacity:
		var button := InventorySlotButton.new()
		button.source = source
		button.slot_id = index
		button.window_ref = self
		button.custom_minimum_size = Vector2(54, 54)
		button.pressed.connect(_on_slot_clicked.bind(source, index))
		button.transfer_requested.connect(execute_transfer)
		button.mouse_entered.connect(_show_description.bind(button))
		button.focus_entered.connect(_show_description.bind(button))
		button.mouse_exited.connect(_hide_description.bind(button))
		button.focus_exited.connect(_hide_description.bind(button))
		grid.add_child(button)
		buttons.append(button)

func refresh() -> void:
	if not is_inside_tree(): return
	for index in _bag_buttons.size():
		_bag_buttons[index].visible = inventory != null and index < inventory.capacity
		_bag_buttons[index].present(inventory.get_slot(index) if inventory != null else null, null, "Bag slot %d" % (index + 1), "", _selected_source == "inventory" and _selected_slot == index)
	for index in _chest_buttons.size():
		_chest_buttons[index].present(chest.get_slot(index) if chest != null else null, null, "Chest slot %d" % (index + 1), "", _selected_source == "chest" and _selected_slot == index)
	if _status != null:
		_status.text = "%d / %d chest slots in use" % [chest.occupied_slots() if chest != null else 0, ChestInventory.CAPACITY]
	if _inspected_button != null: _show_description(_inspected_button)

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

func _on_slot_clicked(source: String, slot: int) -> void:
	if _selected_source.is_empty():
		var stack := inventory.get_slot(slot) if source == "inventory" and inventory != null else (chest.get_slot(slot) if chest != null else null)
		if stack != null:
			_selected_source = source
			_selected_slot = slot
	else:
		if _selected_source != source or _selected_slot != slot:
			execute_transfer(_selected_source, _selected_slot, source, slot)
		_selected_source = ""
		_selected_slot = null
	refresh()

func execute_transfer(src: String, src_id: Variant, dst: String, dst_id: Variant) -> void:
	if transfer_handler.is_valid():
		transfer_handler.call(src, src_id, dst, dst_id)
		_status.text = "Storage request sent."
	elif ChestTransfer.apply(inventory, chest, src, src_id, dst, dst_id):
		_status.text = "Stored safely." if dst == "chest" else "Moved to your bag."
	refresh()
