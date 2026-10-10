class_name MangaButton
extends Button
## A lively menu control that makes pointer hover and controller focus equally obvious.

var _highlighted := false

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pivot_offset = size * 0.5
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	mouse_entered.connect(_set_highlight.bind(true))
	mouse_exited.connect(_set_highlight.bind(false))
	focus_entered.connect(_set_highlight.bind(true))
	focus_exited.connect(_set_highlight.bind(false))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		if not has_theme_stylebox_override(state):
			add_theme_stylebox_override(state, MenuStyle.button_box(state))

func _set_highlight(active: bool) -> void:
	_highlighted = active
	queue_redraw()
	# Container bounds remain stable when pointer/controller focus changes.

func _draw() -> void:
	if not _highlighted or disabled:
		return
	var spark := MenuStyle.SOY_GOLD
	draw_circle(Vector2(9, 8), 2.0, spark)
	draw_circle(Vector2(size.x - 9, size.y - 8), 2.0, spark)
