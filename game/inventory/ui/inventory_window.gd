class_name InventoryWindow
extends CanvasLayer
## Edge-docked equipment and backpack leave the local character unobstructed.

var transfer_handler: Callable
var conversion_handler: Callable
var consume_handler: Callable
var quick_transfer_handler: Callable

signal drop_requested(source: String, id: Variant)
signal drop_warning_skipped

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
var _backpack_dock: PanelContainer
var _equipment_dock: PanelContainer
var drop_confirmation: InventoryDropConfirmation
var _bag_label: Label
var _selected_source: String = ""
var _selected_slot: Variant = null
func _ready() -> void:
	layer = 15
	visible = false
	_build_ui()
	drop_confirmation = InventoryDropConfirmation.new()
	drop_confirmation.approved.connect(drop_requested.emit)
	drop_confirmation.skip_future_approved.connect(drop_warning_skipped.emit)
	add_child(drop_confirmation)

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
	if drop_confirmation != null: drop_confirmation.hide()
	visible = false
	_selected_source = ""
	_selected_slot = null
	closed.emit()

func _build_ui() -> void:
	InventoryWindowLayout.build_ui(self)

func refresh() -> void:
	if not is_inside_tree(): return
	if _currency != null:
		_currency.text = "E %d · M %d · W %d · T %d · G %d  " % [_count("edamame"), _count("mature_bean"), _count("tofu_white_chunk"), _count("toasted_tofu_chunk"), _count("golden_tofu_chunk")]
	if _backpack_dock != null:
		var rows := ceili(float(inventory.capacity if inventory != null else 0) / 5.0)
		var height := 432.0 + maxf(0.0, rows - 2) * 64.0
		_backpack_dock.offset_top = -height * 0.5
		_backpack_dock.offset_bottom = height * 0.5
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
	if _inspected_button != null: InventoryWindowDescriptions.show_for_slot(self, _inspected_button)

func _count(id: String) -> int:
	return inventory.count_item(id) if inventory != null else 0

func _on_slot_context(slot: int) -> void:
	if inventory == null: return
	var stack := inventory.get_slot(slot)
	if stack == null or stack.item == null: return
	if CurrencyExchange.NEXT_TIER.has(stack.item.id):
		_open_currency_menu(slot)
		return
	if consume_handler.is_valid():
		if consume_handler.call(slot):
			refresh()

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
	if Input.is_key_pressed(KEY_SHIFT): return
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

func request_drop(source: String, id: Variant) -> void:
	if not InventoryTransfer.valid_slot(source, id): return
	var stack: ItemStack = inventory.get_slot(int(id)) if source == "inventory" and inventory != null else (equipment.get_slot(str(id)) if equipment != null else null)
	if stack == null or stack.item == null: return
	drop_confirmation.request(source, id, stack)

func drop_point_is_inside(point: Vector2) -> bool:
	return (_equipment_dock != null and _equipment_dock.get_global_rect().has_point(point)) or (_backpack_dock != null and _backpack_dock.get_global_rect().has_point(point))

func request_quick_transfer(source: String, id: Variant) -> void:
	if source != "inventory" or not quick_transfer_handler.is_valid(): return
	var message: String = str(quick_transfer_handler.call(source, id))
	if _conversion_status != null: _conversion_status.text = message
	refresh()
