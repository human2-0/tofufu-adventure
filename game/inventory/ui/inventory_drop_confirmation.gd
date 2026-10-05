class_name InventoryDropConfirmation
extends ConfirmationDialog
## Confirms a manual inventory drop and remembers an approved opt-out locally.

signal approved(source: String, id: Variant)
signal skip_future_approved

var skip_future: bool = false
var _checkbox: CheckBox
var _source := ""
var _slot_id: Variant = null

func _ready() -> void:
	title = "Drop this item?"
	dialog_hide_on_ok = false
	cancel_button_text = "Keep item"
	get_ok_button().text = "Drop item"
	_checkbox = CheckBox.new()
	_checkbox.text = "Don't ask again"
	_checkbox.add_theme_color_override("font_color", Color("e9f4dd"))
	add_child(_checkbox)
	_checkbox.position = Vector2(24, 70)
	_checkbox.custom_minimum_size = Vector2(220, 32)
	confirmed.connect(_approve)
	canceled.connect(_cancel)
	close_requested.connect(_cancel)

func request(source: String, id: Variant, stack: ItemStack) -> void:
	if skip_future:
		approved.emit(source, id)
		return
	_source = source
	_slot_id = id
	_checkbox.button_pressed = false
	var name := stack.item.name if stack != null and stack.item != null else "this item"
	var count := " ×%d" % stack.count if stack != null and stack.count > 1 else ""
	dialog_text = "Are you sure you want to drop %s%s onto the ground?" % [name, count]
	popup_centered(Vector2i(420, 170))

func _approve() -> void:
	var remember := _checkbox.button_pressed
	if remember: skip_future = true
	var source := _source
	var id: Variant = _slot_id
	_source = ""
	_slot_id = null
	hide()
	if remember: skip_future_approved.emit()
	approved.emit(source, id)

func _cancel() -> void:
	_source = ""
	_slot_id = null
	hide()
