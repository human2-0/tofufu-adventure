class_name SoybeanPlot
extends Node3D
## Soil and billboard presentation; no input or reward decisions.

const VEGETATION = preload("res://assets/farming/vegetation-keyed.png")
const PODS = preload("res://assets/farming/source/pods.png")
var crop := SoybeanCrop.new()
var sprite := Sprite3D.new()
var prompt := Label3D.new()
var ring := MeshInstance3D.new()
var _material := ShaderMaterial.new()
var _clock: float = 0

func _ready() -> void:
	var soil := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = 0.8
	shape.bottom_radius = 0.9
	shape.height = 0.08
	soil.mesh = shape
	var earth := StandardMaterial3D.new()
	earth.albedo_color = Color("694328")
	soil.material_override = earth
	soil.position.y = 0.04
	add_child(soil)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.86
	torus.outer_radius = 0.91
	ring.mesh = torus
	ring.position.y = 0.08
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("f5d779")
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = glow
	add_child(ring)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.region_enabled = true
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material.shader = preload("res://game/farming/crop_atlas.gdshader")
	sprite.material_override = _material
	add_child(sprite)
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.font_size = 28
	prompt.outline_size = 7
	prompt.pixel_size = 0.008
	prompt.position.y = 2.65
	add_child(prompt)
	present(false, "")

func _process(delta: float) -> void:
	_clock += delta
	# Cosmetic breathing; growth frames are selected exclusively from crop age.
	sprite.scale = Vector3.ONE * (1.0 + sin(_clock * 2.2) * 0.008)

func present(focused: bool, text: String) -> void:
	ring.visible = focused
	prompt.visible = focused
	prompt.text = text
	var phase := crop.phase()
	sprite.visible = phase != SoybeanCrop.Phase.EMPTY
	if not sprite.visible: return
	var pod := phase >= SoybeanCrop.Phase.PODS
	var atlas: Texture2D = PODS if pod else VEGETATION
	var region: Rect2
	if pod:
		var cell := Vector2(PODS.get_size()) / Vector2(4, 3)
		var frame := crop.pod_frame()
		region = Rect2(Vector2(frame % 4, frame / 4) * cell, cell)
	else:
		var frame := int(phase) - 1
		region = Rect2((frame % 3) * 512, 0 if frame < 3 else 400, 512, 400 if frame < 3 else 624)
	sprite.texture = atlas
	sprite.region_rect = region
	sprite.pixel_size = 1.8 / region.size.x
	sprite.offset.y = region.size.y * 0.5 - (8 if pod else 25)
	sprite.position.y = 0.1
	_material.set_shader_parameter("atlas", atlas)
	_material.set_shader_parameter("keyed", not pod)
