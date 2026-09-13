class_name DashSlot
extends Control
## Compact kawaii skill slot: circular loading recovery, darkened cooldown icon, and pop cue.

var dash_bar: ProgressBar
var dash_status: Label

var _cooldown_remaining: float = 0.0
var _cooldown_total: float = 0.0
var _was_ready: bool = true
var _icon_rect: Rect2
var _ready_flash: float = 0.0

func _init() -> void:
	custom_minimum_size = Vector2(52, 52)
	mouse_filter = MOUSE_FILTER_IGNORE
	dash_bar = ProgressBar.new()
	dash_bar.visible = false
	dash_bar.max_value = 100.0
	dash_bar.value = 100.0
	add_child(dash_bar)
	dash_status = Label.new()
	dash_status.visible = false
	dash_status.text = "DASH READY"
	add_child(dash_status)

func _ready() -> void:
	pivot_offset = size * 0.5
	_update_rects()
	resized.connect(_update_rects)

func _update_rects() -> void:
	pivot_offset = size * 0.5
	var pad := 9.0
	_icon_rect = Rect2(pad, pad, size.x - pad * 2.0, size.y - pad * 2.0)
	queue_redraw()

func set_cooldown(current: float, total: float) -> void:
	_cooldown_remaining = maxf(0.0, current)
	_cooldown_total = maxf(0.0, total)
	var ready_now := _cooldown_remaining <= 0.001
	var progress := 1.0 if _cooldown_total <= 0.0 else clampf(1.0 - _cooldown_remaining / _cooldown_total, 0.0, 1.0)
	dash_bar.value = progress * 100.0
	dash_status.text = "DASH READY" if ready_now else "DASH / RECHARGING"
	if ready_now and not _was_ready:
		_pop_ready()
	_was_ready = ready_now
	queue_redraw()

func _pop_ready() -> void:
	_ready_flash = 1.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.18, 1.18), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	var flash_tween := create_tween()
	flash_tween.tween_method(func(v: float) -> void:
		_ready_flash = v
		queue_redraw()
	, 1.0, 0.0, 0.28)

func _draw() -> void:
	var s := size
	var center := s * 0.5
	var radius := minf(s.x, s.y) * 0.5 - 2.0
	var is_ready := _cooldown_remaining <= 0.001
	var progress := 1.0 if _cooldown_total <= 0.0 else clampf(1.0 - _cooldown_remaining / _cooldown_total, 0.0, 1.0)
	var bg_col := Color(0.08, 0.14, 0.18, 0.52)
	draw_circle(center, radius, bg_col)
	_draw_dash_icon(center, is_ready)
	if not is_ready:
		draw_circle(center, radius, Color(0.03, 0.06, 0.08, 0.45))
		var track_col := Color(0.18, 0.28, 0.32, 0.35)
		draw_arc(center, radius - 2.0, 0.0, TAU, 36, track_col, 2.5, true)
		var fill_col := Color("86d6c4")
		var start_angle := -PI * 0.5
		var sweep := progress * TAU
		if sweep > 0.01:
			draw_arc(center, radius - 2.0, start_angle, start_angle + sweep, 36, fill_col, 2.5, true)
	var rim_col := Color("b8f2e2") if is_ready else Color(0.45, 0.65, 0.6, 0.4)
	if _ready_flash > 0.0:
		rim_col = rim_col.lerp(Color("ffffff"), _ready_flash)
	draw_arc(center, radius, 0.0, TAU, 40, rim_col, 1.5, true)
	_draw_hotkey_badge(center, s)

func _draw_dash_icon(center: Vector2, is_ready: bool) -> void:
	var col := Color("baf0e0") if is_ready else Color(0.38, 0.5, 0.52, 0.45)
	if _ready_flash > 0.0:
		col = col.lerp(Color("ffffff"), _ready_flash * 0.8)
	var points1 := PackedVector2Array([
		center + Vector2(-9, -7),
		center + Vector2(2, 0),
		center + Vector2(-9, 7)
	])
	var points2 := PackedVector2Array([
		center + Vector2(-1, -7),
		center + Vector2(10, 0),
		center + Vector2(-1, 7)
	])
	draw_polyline(points1, col, 2.4, true)
	draw_polyline(points2, col, 2.4, true)

func _draw_hotkey_badge(center: Vector2, s: Vector2) -> void:
	var badge_rect := Rect2(center.x - 14, s.y - 12, 28, 11)
	draw_rect(badge_rect, Color(0.06, 0.12, 0.15, 0.7), true)
	draw_rect(badge_rect, Color(0.6, 0.8, 0.75, 0.35), false, 1.0)
	var font := ThemeDB.fallback_font
	if font != null:
		draw_string(font, Vector2(center.x - 12, s.y - 3), "SHIFT", HORIZONTAL_ALIGNMENT_CENTER, 24, 8, Color("e4f3ef"))
