class_name SoyHitFlash
extends Control
## Brief amber impact ring and bean flecks, with a clear center for aiming.

var remaining: float = 0.0
const DURATION: float = 0.45

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func splash() -> void:
	remaining = DURATION
	queue_redraw()

func _process(delta: float) -> void:
	if remaining <= 0.0: return
	remaining = maxf(0.0, remaining - delta)
	queue_redraw()

func _draw() -> void:
	if remaining <= 0.0: return
	var strength := remaining / DURATION
	var center := size * 0.5
	var radius := minf(size.x, size.y) * (0.28 + 0.12 * (1.0 - strength))
	for index in 8:
		var angle := index * TAU / 8.0
		var point := center + Vector2.from_angle(angle) * radius
		draw_circle(point, 6.0 * strength + 2.0, Color(1.0, 0.83, 0.4, strength * 0.8))
	draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.72, 0.3, strength * 0.55), false, 12.0 * strength)
