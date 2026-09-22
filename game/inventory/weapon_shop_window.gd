class_name WeaponShopWindow
extends CanvasLayer

signal purchase_requested(item_id: String)
signal sale_requested(slot: int, item_id: String)
signal closed
var inventory: PlayerInventory
var status: Label
var balance: Label
var _sales: VBoxContainer
var _first_button: Button

func _ready() -> void:
	layer = 16
	visible = false
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("173632f5")
	style.set_corner_radius_all(18)
	style.set_content_margin_all(24)
	style.border_color = Color("9bd58c")
	style.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 400
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var title := Label.new()
	title.text = "KAJI · BUY / SELL"
	title.add_theme_color_override("font_color", Color("f5dfac"))
	column.add_child(title)
	balance = Label.new()
	column.add_child(balance)
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(400, 230)
	column.add_child(tabs)
	var buy := VBoxContainer.new()
	buy.name = "Buy"
	tabs.add_child(buy)
	var sell_scroll := ScrollContainer.new()
	sell_scroll.name = "Sell"
	tabs.add_child(sell_scroll)
	_sales = VBoxContainer.new()
	_sales.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_scroll.add_child(_sales)
	inventory.changed.connect(_refresh_sales)
	_refresh_sales()
	for id in ["knife", "soy_gun", "sotjet"]:
		var item := InventoryItem.weapon(id)
		var button := Button.new()
		button.text = "%s    ·    1 coin" % item.name
		button.icon = item.icon
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 40)
		button.custom_minimum_size.y = 56
		button.pressed.connect(func() -> void: purchase_requested.emit(id))
		buy.add_child(button)
		if _first_button == null: _first_button = button
	status = Label.new()
	status.text = "Buy weapons or sell items from your bag."
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	var close_button := Button.new()
	close_button.text = "Leave shop · Esc"
	close_button.pressed.connect(close)
	column.add_child(close_button)

func _process(_delta: float) -> void:
	if visible: balance.text = "Your coins: %d" % inventory.coins

func close() -> void:
	if not visible: return
	visible = false
	closed.emit()

func open() -> void:
	visible = true
	if _first_button != null:
		_first_button.call_deferred("grab_focus")

func _input(event: InputEvent) -> void:
	if visible and not event.is_echo() and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _refresh_sales() -> void:
	for child in _sales.get_children():
		_sales.remove_child(child)
		child.queue_free()
	var hint := Label.new()
	hint.text = "Sell from your bag · 1 coin per item"
	_sales.add_child(hint)
	for slot in PlayerInventory.CAPACITY:
		var stack := inventory.get_slot(slot)
		if stack == null or stack.item == null: continue
		var id := stack.item.id
		var button := Button.new()
		button.text = "%s ×%d · Sell one · +1 coin" % [stack.item.name, stack.count]
		button.icon = stack.item.icon
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 32)
		button.custom_minimum_size.y = 44
		button.pressed.connect(func() -> void: sale_requested.emit(slot, id))
		_sales.add_child(button)
	if _sales.get_child_count() == 1: hint.text = "Your bag is empty. Gather items to sell."
