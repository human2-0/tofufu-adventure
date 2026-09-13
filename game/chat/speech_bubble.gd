class_name SpeechBubble
extends Label3D

var yelled: bool = false
var remaining: float = 6.0

func _ready() -> void:
	position.y = 2.15
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	font_size = 30
	pixel_size = 0.012
	outline_size = 8
	outline_modulate = Color("19312e")
	width = 340
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	no_depth_test = false

func _process(delta: float) -> void:
	remaining -= delta
	modulate.a = clampf(remaining, 0, 1)
	if remaining <= 0: queue_free()
