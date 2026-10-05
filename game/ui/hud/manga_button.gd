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
	var target_scale := Vector2(1.025, 1.025) if active else Vector2.ONE
	var tween := create_tween()
	tween.tween_property(self, "scale", target_scale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	if not _highlighted or disabled:
		return
	var ink := MenuStyle.INK
	var spark := MenuStyle.SOY_GOLD
	var y := size.y * 0.5
	draw_line(Vector2(-9, y), Vector2(-2, y), ink, 2.0, true)
	draw_line(Vector2(size.x + 2, y), Vector2(size.x + 9, y), ink, 2.0, true)
	draw_circle(Vector2(9, 8), 2.0, spark)
	draw_circle(Vector2(size.x - 9, size.y - 8), 2.0, spark)
