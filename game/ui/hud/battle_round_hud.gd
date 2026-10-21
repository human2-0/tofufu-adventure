class_name BattleRoundHUD
extends Control
## Rotation/objective readouts and brief cosmetic combat confirmation.

signal results_requested
var storm: Label
var goals: Label
var results_button: Button
var _hit: float = 0
var _hurt: float = 0
var _kill: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stack)
	stack.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stack.offset_left = 20
	stack.offset_top = -160
	stack.offset_bottom = -65
	stack.offset_right = minf(700, size.x - 188)
	storm = MenuStyle.label(stack, "", 15, MenuStyle.SOY_GOLD)
	goals = MenuStyle.label(stack, "", 13)
	tooltip_text = tr("Armour regenerates to 50 after 8 seconds without damage. Health needs food.")
	for label: Label in [storm, goals]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		label.add_theme_color_override("font_shadow_color", MenuStyle.INK)
		label.add_theme_constant_override("shadow_outline_size", 4)
	results_button = MenuStyle.button(stack, "Match results", results_requested.emit)
	results_button.hide()
	resized.connect(func() -> void:
		stack.offset_right = minf(700, size.x - 188)
		storm.add_theme_font_size_override("font_size", 13 if size.x < 900 else 15))

func feedback(hit: bool, hurt: bool, kill: bool) -> void:
	if hit: _hit = 0.28; _kill = kill
	if hurt: _hurt = 0.35
	queue_redraw()

func _process(delta: float) -> void:
	if _hit <= 0 and _hurt <= 0: return
	_hit = maxf(0, _hit - delta)
	_hurt = maxf(0, _hurt - delta)
	queue_redraw()

func _draw() -> void:
	if _hit > 0:
		var at := size * 0.5 if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else get_local_mouse_position()
		var color := Color("f4c75d") if _kill else Color.WHITE
		color.a = _hit / 0.28
		for direction: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			draw_line(at + direction * 8, at + direction * 15, color, 2, true)
	if _hurt > 0:
		draw_rect(Rect2(Vector2.ONE * 3, size - Vector2.ONE * 6), Color(1, 0.2, 0.22, _hurt / 0.35 * 0.65), false, 5)
