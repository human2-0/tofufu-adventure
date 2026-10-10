class_name DiscoveryPulse
extends Control
## Cosmetic activity indicator, never a fabricated connection percentage.

var active: bool = false:
	set(value):
		active = value
		_sync_processing()
		queue_redraw()
var failed: bool = false
var _phase: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(40, 40)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(_sync_processing)
	_sync_processing()

func _sync_processing() -> void:
	set_process(active and is_visible_in_tree())

func _process(delta: float) -> void:
	_phase = fmod(_phase + delta * 0.65, 1.0)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var color := MenuStyle.BERRY if failed else MenuStyle.MINT
	draw_circle(center, 5.0, color)
	if not active: return
	for index in 2:
		var phase := fmod(_phase + index * 0.5, 1.0)
		draw_arc(center, 7.0 + phase * 12.0, 0, TAU, 32, Color(color, 1.0 - phase), 1.5, true)
