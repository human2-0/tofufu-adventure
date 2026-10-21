class_name BattleInventoryWindow
extends InventoryWindow
## The normal equipment/bag controls fit a compact battle viewport without changing data.

func _ready() -> void:
	super._ready()
	_currency.hide()
	_tooltip.details_reader = BattleItems.details
	_conversion_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_adapt_labels(self)
	drop_confirmation.skip_future = true
	get_viewport().size_changed.connect(_fit)
	_fit()

func _adapt_labels(node: Node) -> void:
	if node is Label and node.text.begins_with("Shift-click near the Seed Bank"):
		node.text = "Shift-click to equip. Right-click food to use it.\nDrag outside to drop. B / Esc closes the bag.\nI opens match stats. The match keeps running."
	if node is Button and node.text == "← My Tofufu": node.text = "← Match stats"
	for child in node.get_children(): _adapt_labels(child)

func refresh() -> void:
	super.refresh()
	for button in _inv_buttons: _grade(button)
	for button: InventorySlotButton in _eq_buttons.values(): _grade(button)
	_fit()

func _process(_delta: float) -> void:
	# Containers settle wrapped text after resize; fit again using their final minimum.
	if visible: _fit()

func _fit() -> void:
	if _backpack_dock == null or _equipment_dock == null or not is_inside_tree(): return
	var viewport := get_viewport().get_visible_rect().size
	var bag_height := 432.0 + maxf(0, ceili(float(inventory.capacity if inventory != null else 10) / 5) - 2) * 64
	for panel: PanelContainer in [_equipment_dock, _backpack_dock]:
		var is_bag := panel == _backpack_dock
		var height := maxf(bag_height if is_bag else 432, panel.get_combined_minimum_size().y)
		var scale_factor := minf(1, (viewport.y - 28) / height)
		panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		panel.size = Vector2(350 if is_bag else 240, height)
		panel.scale = Vector2.ONE * scale_factor
		panel.position = Vector2(viewport.x - panel.size.x * scale_factor - 16 if is_bag else 16, (viewport.y - height * scale_factor) / 2)

func _grade(button: InventorySlotButton) -> void:
	if button.current_stack == null: return
	var kind := BattlePackWire.ITEMS.find(button.current_stack.item.id) + 1
	var style := button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	style.border_color = BattleRarity.COLORS[BattleRarity.grade(kind)]
	style.set_border_width_all(2)
	button.add_theme_stylebox_override("normal", style)
