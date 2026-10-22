class_name BattleDamageFlash
extends ColorRect
## Brief pulsing damage vignette; clear centre and mouse-transparent HUD edges.
const DURATION: float = 0.65
var remaining: float = 0.0
var shader: ShaderMaterial

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = -1
	shader = ShaderMaterial.new()
	shader.shader = preload("res://game/ui/effects/battle_damage_flash.gdshader")
	material = shader
	hide()

func hurt() -> void:
	remaining = DURATION
	visible = true
	shader.set_shader_parameter("strength", 1.0)

static func strength(seconds: float) -> float:
	if seconds <= 0: return 0
	var elapsed := DURATION - seconds
	return pow(seconds / DURATION, 0.65) * (0.6 + 0.4 * maxf(0, cos(elapsed * TAU / 0.24)))

func _process(delta: float) -> void:
	if remaining <= 0: return
	remaining = maxf(0, remaining - delta)
	shader.set_shader_parameter("strength", strength(remaining))
	visible = remaining > 0

func cancel() -> void:
	remaining = 0
	shader.set_shader_parameter("strength", 0.0)
	hide()
