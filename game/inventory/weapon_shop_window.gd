class_name WeaponShopWindow
extends CanvasLayer

signal purchase_requested(item_id: String)
signal sale_requested(slot: int, item_id: String)
signal closed

var inventory: PlayerInventory
var status: Label
var balance: Label
var _description: Label
var _bag_grid: GridContainer
var _stock_grid: GridContainer
var _first_button: Button
var _bag_buttons: Array[Button] = []

func _ready() -> void:
	layer = 16
	visible = false
	_build_ui()
	_build_stock()
	if inventory != null: inventory.changed.connect(_refresh_bag)
	_refresh_bag()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.04
	panel.anchor_top = 0.045
	panel.anchor_right = 0.96
	panel.anchor_bottom = 0.955
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("173632f5")
	panel_style.set_corner_radius_all(18)
	panel_style.set_content_margin_all(14)
	panel_style.border_color = Color("9bd58c")
	panel_style.set_border_width_all(3)
	panel_style.shadow_color = Color("07171599")
	panel_style.shadow_size = 14
	panel_style.shadow_offset = Vector2(0, 6)
	panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "KAJI'S TRADING STALL"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("f5dfac"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	balance = Label.new()
	balance.add_theme_color_override("font_color", Color("eacb83"))
	header.add_child(balance)
	var close_button := Button.new()
	close_button.text = "✕"
	close_button.pressed.connect(close)
	header.add_child(close_button)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	_bag_grid = _build_section(body, "YOUR BAG")
	_stock_grid = _build_section(body, "KAJI'S STOCK · FREE")

	_description = Label.new()
	_description.custom_minimum_size.y = 30
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.add_theme_font_size_override("font_size", 12)
	_description.add_theme_color_override("font_color", Color("e9f4dd"))
	_description.text = "Hover or focus a tile to inspect it. Buy equipment for 0 Mature Beans."
	column.add_child(_description)
	status = Label.new()
	status.text = "Buy gear from Kaji's stock. Equip clothing from your bag to wear a complete set."
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 12)
	column.add_child(status)

func _build_section(parent: HBoxContainer, heading: String) -> GridContainer:
	var section := PanelContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("20433d")
	style.set_corner_radius_all(12)
	style.set_content_margin_all(8)
	style.border_color = Color("527d6d")
	style.set_border_width_all(1)
	section.add_theme_stylebox_override("panel", style)
	parent.add_child(section)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	section.add_child(content)
	var label := Label.new()
	label.text = heading
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("aee6d0"))
	content.add_child(label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	return grid

func _build_stock() -> void:
	for id in WeaponTrade.BUYABLE_IDS:
		var item := InventoryItem.from_id(id)
		if item == null: continue
		var button := ShopItemTile.new()
		button.setup(item, "0 MATURE BEANS", _tile_size())
		button.pressed.connect(func() -> void: purchase_requested.emit(item.id))
		_watch_description(button)
		_stock_grid.add_child(button)
		if _first_button == null: _first_button = button

func _refresh_bag() -> void:
	if _bag_grid == null: return
	if _description != null: _description.text = "Hover or focus a tile to inspect it. Buy equipment for 0 Mature Beans."
	for child in _bag_grid.get_children():
		_bag_grid.remove_child(child)
		child.queue_free()
	_bag_buttons.clear()
	var capacity := inventory.capacity if inventory != null else 0
	for slot in capacity:
		var stack := inventory.get_slot(slot)
		if stack == null or stack.item == null:
			var empty := ShopItemTile.new()
			empty.setup_empty(_tile_size())
			_bag_grid.add_child(empty)
			_bag_buttons.append(empty)
			continue
		var item := stack.item
		var count_text := "×%d" % stack.count if stack.count > 1 else ""
		var button := ShopItemTile.new()
		button.setup(item, count_text, _tile_size())
		button.pressed.connect(func() -> void:
			if item.category == "combat":
				sale_requested.emit(slot, item.id)
			else:
				status.text = "Kaji only buys combat gear."
		)
		_watch_description(button)
		_bag_grid.add_child(button)
		_bag_buttons.append(button)

func _tile_size() -> Vector2:
	var width := get_viewport().get_visible_rect().size.x if is_inside_tree() else 1280.0
	return Vector2(88, 96) if width < 1100 else Vector2(106, 104)

func _watch_description(button: ShopItemTile) -> void:
	button.inspected.connect(_show_description)
	button.inspection_ended.connect(_hide_description)

func _show_description(description: String) -> void:
	if _description != null: _description.text = description

func _hide_description() -> void:
	if _description != null: _description.text = "Hover or focus a tile to inspect it. Buy equipment for 0 Mature Beans."

func _process(_delta: float) -> void:
	if visible and balance != null: balance.text = "Mature Beans: %d" % (inventory.count_item("mature_bean") if inventory != null else 0)

func close() -> void:
	if not visible: return
	visible = false
	closed.emit()

func open() -> void:
	visible = true
	_refresh_bag()
	if _first_button != null: _first_button.call_deferred("grab_focus")

func _input(event: InputEvent) -> void:
	if visible and not event.is_echo() and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
