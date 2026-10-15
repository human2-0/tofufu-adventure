class_name SpeechBubble
extends Label3D

var yelled: bool = false
var remaining: float = 6.0

func _ready() -> void:
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	position.y = 2.15
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	font_size = 30
	pixel_size = 0.012
	outline_size = 8
	outline_modulate = Color("19312e")
	width = 340
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	visibility_range_end = 32.0
	visibility_range_end_margin = 2.0
	no_depth_test = false
	ignore_occlusion_culling = false
	render_priority = 127

func _process(delta: float) -> void:
	remaining -= delta
	modulate.a = clampf(remaining, 0, 1)
	if remaining <= 0: queue_free()
