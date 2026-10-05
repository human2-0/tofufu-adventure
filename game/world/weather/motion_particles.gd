class_name MotionParticles
extends MultiMeshInstance3D
## Reused ballistic flecks for feet, skids, landing dust and shallow-water splashes.

const CAPACITY: int = 96
var _positions := PackedVector3Array()
var _velocities := PackedVector3Array()
var _ages := PackedFloat32Array()
var _colors: Array[Color] = []
var _cursor: int = 0
var _random := RandomNumberGenerator.new()
var snow_context: bool = false

func _ready() -> void:
	_random.randomize()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 4
	mesh.rings = 2
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	multimesh.instance_count = CAPACITY
	_positions.resize(CAPACITY)
	_velocities.resize(CAPACITY)
	_ages.resize(CAPACITY)
	_colors.resize(CAPACITY)
	for i in CAPACITY:
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3.ZERO))

func burst(at: Vector3, motion: Vector3, amount: int, wet: bool, strength: float = 1.0) -> void:
	for n in mini(amount, CAPACITY):
		var i := _cursor
		_cursor = (_cursor + 1) % CAPACITY
		var direction := Vector2.from_angle(_random.randf_range(0, TAU))
		_positions[i] = at + Vector3(direction.x, 0.055, direction.y) * _random.randf_range(0.05, 0.3)
		_velocities[i] = Vector3(direction.x, _random.randf_range(1.0, 2.6), direction.y) * strength - motion * 0.08
		_ages[i] = _random.randf_range(0.35, 0.65)
		_colors[i] = Color("eaf5fa") if snow_context else (Color("bdeef2") if wet else Color("d9ca99"))

func _process(delta: float) -> void:
	for i in CAPACITY:
		if _ages[i] <= 0.0: continue
		_ages[i] = maxf(0.0, _ages[i] - delta)
		_velocities[i].y -= 7.0 * delta
		_positions[i] += _velocities[i] * delta
		var size := 0.075 * minf(1.0, _ages[i] * 5.0)
		var color := _colors[i]
		color.a = minf(0.8, _ages[i] * 3.0)
		multimesh.set_instance_color(i, color)
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), to_local(_positions[i])))
