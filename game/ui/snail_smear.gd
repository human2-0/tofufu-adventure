class_name SnailSmear
extends ColorRect
## Local view-only slime stroke. Retriggering refreshes one bounded effect.

const DURATION: float = 1.6
var remaining: float = 0.0
var _shader: ShaderMaterial

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shader = ShaderMaterial.new()
	_shader.shader = preload("res://game/ui/snail_smear.gdshader")
	material = _shader
	visible = false

func splash() -> void:
	remaining = DURATION
	_shader.set_shader_parameter("strength", 1.0)
	_shader.set_shader_parameter("age", 0.0)
	_shader.set_shader_parameter("slant", randf_range(-0.3, 0.3))
	visible = true

func _process(delta: float) -> void:
	remaining = maxf(0.0, remaining - delta)
	visible = remaining > 0.0
	_shader.set_shader_parameter("strength", smoothstep(0.0, DURATION, remaining))
	_shader.set_shader_parameter("age", DURATION - remaining)
