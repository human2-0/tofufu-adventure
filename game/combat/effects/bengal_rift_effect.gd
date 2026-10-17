class_name BengalRiftEffect
extends Node3D
## Bounded cosmetic sequence: triple rake, open starfield tear, shards, collapse.

const OPEN: Texture2D = preload("res://assets/weapons/bengal_paws/rift-open.png")
const RAKE: Texture2D = preload("res://assets/weapons/bengal_paws/reality-rift.png")
const SHADER: Shader = preload("res://game/combat/effects/bengal_rift.gdshader")
const LIFETIME: float = 1.05
const SHARD_COUNT: int = 12
var facing := Vector3.BACK
var age: float = 0
var rake: Sprite3D
var tear: Sprite3D
var shards: MultiMeshInstance3D
var _tear_material: ShaderMaterial
var _shard_material: ShaderMaterial

func _ready() -> void:
	top_level = true
	rake = _sprite(RAKE, 2.65)
	rake.position.z = 0.04
	tear = _sprite(OPEN, 2.2)
	tear.rotation.z = -0.12
	_tear_material = _material(OPEN)
	tear.material_override = _tear_material
	_build_shards()
	present()

func _process(delta: float) -> void:
	age += delta
	if age >= LIFETIME:
		queue_free()
		return
	present()

func present() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null: global_basis = camera.global_basis.orthonormalized()
	var handed := 1.0 if facing.dot(global_basis.x) >= 0 else -1.0
	var opening := smoothstep(0.03, 0.22, age)
	var closing := smoothstep(0.66, LIFETIME, age)
	rake.visible = age < 0.28
	rake.scale = Vector3.ONE * lerpf(0.45, 1.12, smoothstep(0, 0.15, age))
	rake.rotation.z = handed * lerpf(-0.22, 0.12, smoothstep(0, 0.2, age))
	rake.modulate = Color(1.5, 1.7, 2, 1.0 - smoothstep(0.09, 0.28, age))
	tear.visible = age > 0.03
	tear.scale = Vector3(maxf(0.01, opening * (1.0 - closing)), 0.85 + opening * 0.15, 1)
	_tear_material.set_shader_parameter("age", age)
	_tear_material.set_shader_parameter("opacity", (1.0 - closing) * opening)
	_shard_material.set_shader_parameter("age", age)
	_shard_material.set_shader_parameter("opacity", 1.0 - smoothstep(0.3, LIFETIME, age))
	_present_shards()

func _sprite(texture: Texture2D, span: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.pixel_size = span / texture.get_height()
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sprite)
	return sprite

func _material(texture: Texture2D) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("art", texture)
	return material

func _build_shards() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices := [Vector3(0, 0.5, 0), Vector3(-0.3, 0, 0), Vector3(0, -0.5, 0), Vector3(0.3, 0, 0)]
	for index in [0, 1, 2, 0, 2, 3]:
		var point: Vector3 = vertices[index]
		surface.set_uv(Vector2(0.52 + point.x * 0.06, 0.54 - point.y * 0.06))
		surface.add_vertex(point)
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = surface.commit()
	instances.instance_count = SHARD_COUNT
	shards = MultiMeshInstance3D.new()
	shards.multimesh = instances
	_shard_material = _material(OPEN)
	_shard_material.set_shader_parameter("tint", Color("69f1ff"))
	shards.material_override = _shard_material
	shards.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shards)

func _present_shards() -> void:
	var travel := maxf(0, age - 0.06)
	for index in SHARD_COUNT:
		var angle := index * TAU / SHARD_COUNT + 0.23
		var speed := 1.3 + (index % 4) * 0.45
		var point := Vector3(cos(angle), sin(angle) * 0.7, 0) * travel * speed
		point.y -= travel * travel * 0.75
		point.z = 0.09 + (index % 3) * 0.03
		var size := (0.12 + (index % 3) * 0.045) * smoothstep(0, 0.07, travel)
		var shard_basis := Basis(Vector3.BACK, angle + travel * (4 + index % 3))
		shards.multimesh.set_instance_transform(index, Transform3D(shard_basis.scaled(Vector3.ONE * size), point))
