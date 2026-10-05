class_name DungeonRunMenu
extends CanvasLayer
## Explicit run exit and exhausted-attempt restart controls.

signal opened
signal closed
signal action_requested(action: int)

const RESTART := 0
const ABANDON := 1

var _restart: Button
var _continue: Button

func _ready() -> void:
	layer = 25
	visible = false
	var shade := ColorRect.new()
	shade.color = Color("071715b8")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.theme = MenuStyle.make_theme()
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(450, 0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	MenuStyle.label(column, "FACTORY RUN", 21)
	MenuStyle.paragraph(column, "Your personal gear and earned rewards are retained.")
	_restart = MenuStyle.button(column, "Restart factory attempt", func() -> void: _choose(RESTART))
	MenuStyle.button(column, "Evacuate factory", func() -> void: _choose(ABANDON))
	_continue = MenuStyle.button(column, "Continue run", close)

func open(restart_available: bool) -> void:
	opened.emit()
	_restart.visible = restart_available
	visible = true
	MenuStyle.focus_later(_restart if restart_available else _continue)

func close() -> void:
	if not visible: return
	visible = false
	closed.emit()

func _choose(action: int) -> void:
	close()
	action_requested.emit(action)

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
