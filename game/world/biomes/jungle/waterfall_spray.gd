class_name WaterfallSpray
extends Node3D
## Fixed pools of ballistic droplets and soft rising mist, culled outside the clearing.

const DROPS: int = 112
const MIST: int = 24
var active: bool = false
var elapsed: float = 0.0
var drops: MultiMeshInstance3D
var mist: MultiMeshInstance3D

func _ready() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.045
	sphere.height = 0.09
	sphere.radial_segments = 6
	sphere.rings = 3
	var water := StandardMaterial3D.new()
	water.albedo_color = Color("d8f6f6")
	water.roughness = 0.18
	sphere.material = water
	drops = _batch(sphere, DROPS, false)
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var haze := ShaderMaterial.new()
	haze.shader = preload("res://game/world/biomes/jungle/waterfall_mist.gdshader")
	quad.material = haze
	mist = _batch(quad, MIST, true)
	visible = false

func _batch(mesh: Mesh, count: int, colors: bool) -> MultiMeshInstance3D:
	var batch := MultiMeshInstance3D.new()
	batch.multimesh = MultiMesh.new()
	batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	batch.multimesh.use_colors = colors
	batch.multimesh.mesh = mesh
	batch.multimesh.instance_count = count
	batch.multimesh.custom_aabb = AABB(Vector3(-9, 0, -3), Vector3(18, 12, 17))
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(batch)
	return batch

func _process(delta: float) -> void:
	visible = active
	if not active: return
	elapsed += delta
	for i in DROPS:
		var age := fposmod(elapsed * 0.8 + i * 0.618, 1.0)
		var angle := i * 2.39996
		var at := Vector3(sin(i * 7.3) * 2.6, 0.12, 6.1)
		at += Vector3(cos(angle) * age * 5.0, sin(age * PI) * (1.0 + fposmod(i * 0.71, 2.0)), -absf(sin(angle)) * age * 5.5)
		drops.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(1, 1.5, 1) * (1.0 - age * 0.7)), at))
	for i in MIST:
		var age := fposmod(elapsed * 0.13 + i * 0.618, 1.0)
		var at := Vector3(sin(i * 17.0) * 3.0 + sin(elapsed * 0.3 + i), age * 4.5 + 0.5, 5.7 - age * 5.0)
		var size := 2.0 + age * 4.5
		mist.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), at))
		mist.multimesh.set_instance_color(i, Color(1, 1, 1, sin(age * PI)))
