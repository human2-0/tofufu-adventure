class_name DungeonNoteView
extends CanvasLayer
## Inspect-only paper view; discovery and journal state belong to the app.

signal closed

const NOTE_TEXT := "Shift operator: Tofufu. Terminal access still matches the operator name."
var _active := false
var _prior_focus: WeakRef
var _close_button: Button

func _ready() -> void:
	layer = 21
	visible = false
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.theme = MenuStyle.make_theme()
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(490, 0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	MenuStyle.label(column, "FOLDED SHIFT NOTE", 20)
	MenuStyle.paragraph(column, NOTE_TEXT)
	_close_button = MenuStyle.button(column, "Back", close)

func open() -> void:
	if _active:
		return
	var focused := get_viewport().gui_get_focus_owner()
	_prior_focus = weakref(focused) if focused != null else null
	_active = true
	visible = true
	MenuStyle.focus_later(_close_button)

func close() -> void:
	if not _active:
		return
	_active = false
	visible = false
	if _prior_focus != null:
		var previous: Control = _prior_focus.get_ref()
		if previous != null and previous.is_inside_tree() and previous.is_visible_in_tree():
			MenuStyle.focus_later(previous)
	_prior_focus = null
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if _active and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
