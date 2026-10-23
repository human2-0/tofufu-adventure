class_name ItemTooltip
extends Control
## Non-interactive slot-anchored inspection shared by bag, equipment, depot and shop.

static var details_enabled: bool = true
var window: CanvasLayer
var target: Control
var _item_reader: Callable
var details_reader: Callable
var title_reader: Callable
var stack_details_reader: Callable
var _panel: PanelContainer
var _title: Label
var _type: Label
var _details: Label
var _last_text := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.custom_minimum_size.x = 280
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102923fa")
	style.border_color = Color("d9b566")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	style.shadow_color = Color("00000080")
	style.shadow_size = 8
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	_panel.add_child(box)
	_title = _label(box, 15, Color("f4c75d"))
	_type = _label(box, 11, Color("aee6d0"))
	_details = _label(box, 12, Color("e9f4dd"))
	var hint := _label(box, 10, Color("9fb8ac"))
	hint.text = "R3 / Wheel / Middle-click · Toggle details"
	_panel.hide()

func _label(box: VBoxContainer, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size.x = 256
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	box.add_child(label)
	return label

func watch(button: Control, reader: Callable) -> void:
	button.mouse_entered.connect(inspect.bind(button, reader))
	button.focus_entered.connect(inspect.bind(button, reader))
	button.mouse_exited.connect(_leave.bind(button))
	button.focus_exited.connect(_leave.bind(button))

func inspect(button: Control, reader: Callable) -> void:
	target = button
	_item_reader = reader
	_update()

func clear() -> void:
	target = null
	_item_reader = Callable()
	if _panel != null: _panel.hide()

func _leave(button: Control) -> void:
	if target != button: return
	if button.has_focus() or button.get_global_rect().has_point(button.get_global_mouse_position()): return
	var focused := get_viewport().gui_get_focus_owner()
	if focused is InventorySlotButton and focused.window_ref == window:
		inspect(focused, func() -> ItemStack: return focused.current_stack)
	elif focused is ShopItemTile and window is WeaponShopWindow:
		inspect(focused, func() -> ItemStack: return ItemStack.new(focused.item, 1))
	else: clear()

func _process(_delta: float) -> void:
	_update()

func _update() -> void:
	if _panel == null: return
	if window == null or not window.visible or not details_enabled or not is_instance_valid(target) or not target.is_visible_in_tree():
		_panel.hide()
		return
	var stack: ItemStack = _item_reader.call() if _item_reader.is_valid() else null
	if stack == null or stack.item == null or get_viewport().gui_is_dragging():
		_panel.hide()
		return
	var item := stack.item
	var title: String = title_reader.call(item) if title_reader.is_valid() else item.name
	title += (" ✦ " + tr("Enhanced") if stack.enhanced else "") + (" ×%d" % stack.count if stack.count > 1 else "")
	var type := ItemTooltipContent.type_label(item)
	if item.required_level > 1: type += " · Requires Lv. %d" % item.required_level
	var details: String = details_reader.call(item) if details_reader.is_valid() else ItemTooltipContent.details(item)
	if stack_details_reader.is_valid(): details += "\n" + str(stack_details_reader.call(stack))
	if stack.enhanced: details += "\n" + MagicalTofufu.bonus_text(item.id) + "\nAlready enhanced · Once per weapon"
	var text := title + type + details
	if text != _last_text:
		_title.text = title
		_type.text = type
		_details.text = details
		_last_text = text
		_panel.size = _panel.get_combined_minimum_size()
	_panel.show()
	_position_panel()

func _position_panel() -> void:
	var rect := target.get_global_rect()
	var bounds := get_viewport_rect().size
	var extent := _panel.size
	var point := Vector2(rect.end.x + 10, rect.position.y)
	if point.x + extent.x > bounds.x - 8: point.x = rect.position.x - extent.x - 10
	point.x = clampf(point.x, 8, maxf(8, bounds.x - extent.x - 8))
	point.y = clampf(point.y, 8, maxf(8, bounds.y - extent.y - 8))
	_panel.position = point

func _input(event: InputEvent) -> void:
	if window == null or not window.visible: return
	var joy := event as InputEventJoypadButton
	var mouse := event as InputEventMouseButton
	var toggle := joy != null and joy.pressed and joy.button_index == JOY_BUTTON_RIGHT_STICK
	if mouse != null and mouse.pressed and is_instance_valid(target):
		toggle = mouse.button_index == MOUSE_BUTTON_MIDDLE or (mouse.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and target.get_global_rect().has_point(mouse.position))
	if not toggle: return
	details_enabled = not details_enabled
	_update()
	get_viewport().set_input_as_handled()
