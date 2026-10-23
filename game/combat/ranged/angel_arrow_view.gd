class_name AngelArrowView
extends Node3D
## A fixed, textured streak and interpolated arrow. Never participates in collisions.

var empowered: bool = false
var _previous := Vector3.ZERO
var _current := Vector3.ZERO
var _placed: bool = false
var _launch := Vector3.ZERO
var _streak: MeshInstance3D

func _ready() -> void:
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	AngelBowModel.arrow(self, empowered)
	_streak = MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var surface := ShaderMaterial.new()
	surface.shader = preload("res://game/combat/ranged/angel_arrow_trail.gdshader")
	surface.set_shader_parameter("flames", preload("res://assets/weapons/angel_bow/flames.png"))
	surface.set_shader_parameter("tint", Color("ffb83d") if empowered else Color("ffe6aa"))
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, surface)
	var length := 2.8 if empowered else 1.8
	var width := 0.16 if empowered else 0.09
	for axis in [Vector3.RIGHT, Vector3.UP]:
		for uv: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1)]:
			mesh.surface_set_color(Color(1, 0.8, 0.4, 1 - uv.y))
			mesh.surface_set_uv(uv)
			mesh.surface_add_vertex(axis * (uv.x * 2 - 1) * width + Vector3.BACK * uv.y * length)
	mesh.surface_end()
	_streak.mesh = mesh
	_streak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_streak)
	_glint(surface)

func _glint(surface: ShaderMaterial) -> void:
	var glint := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * (0.4 if empowered else 0.27)
	glint.mesh = quad
	var glow := surface.duplicate() as ShaderMaterial
	glow.set_shader_parameter("billboard", true)
	glint.material_override = glow
	glint.position.z = -0.7
	glint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glint)

func place(at: Vector3, velocity: Vector3) -> void:
	_previous = at
	_current = at
	_launch = at
	global_position = at
	if not velocity.is_zero_approx():
		var up := Vector3.RIGHT if absf(velocity.normalized().dot(Vector3.UP)) > 0.99 else Vector3.UP
		global_basis = Basis.looking_at(velocity.normalized(), up)
	_placed = true
	_streak.scale.z = 0.0

func advance(at: Vector3) -> void:
	_previous = _current
	_current = at
	_streak.scale.z = minf(1.0, _launch.distance_to(at) / (2.8 if empowered else 1.8))

func _process(_delta: float) -> void:
	if _placed: global_position = _previous.lerp(_current, Engine.get_physics_interpolation_fraction())
