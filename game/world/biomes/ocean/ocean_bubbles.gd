class_name OceanBubbles
extends MultiMeshInstance3D
## Reused mouth bubbles rise, drift, expand and expire at the surface.

const CAPACITY: int = 128
var _positions := PackedVector3Array()
var _ages := PackedFloat32Array()
var _sizes := PackedFloat32Array()
var _cursor: int = 0
var _clock: float = 0.0
var _random := RandomNumberGenerator.new()

func _ready() -> void:
	name = "BreathingBubbles"
	_random.seed = 5821
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 8
	sphere.rings = 4
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.76, 0.96, 1.0, 0.58)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.08
	material.metallic = 0.35
	sphere.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = sphere
	multimesh.instance_count = CAPACITY
	_positions.resize(CAPACITY)
	_ages.resize(CAPACITY)
	_sizes.resize(CAPACITY)
	for i in CAPACITY: _hide(i)

func breathe(at: Vector3, facing: Vector2) -> void:
	var mouth := at + Vector3(facing.x * 0.22, 0.68, facing.y * 0.22)
	if mouth.y >= OceanTerrain.WATER_LEVEL - 0.1: return
	for n in 5:
		var i := _cursor
		_cursor = (_cursor + 1) % CAPACITY
		_positions[i] = mouth + Vector3(_random.randf_range(-0.08, 0.08), n * 0.10, _random.randf_range(-0.08, 0.08))
		_ages[i] = 8.0
		_sizes[i] = _random.randf_range(0.065, 0.15)

func _process(delta: float) -> void:
	_clock += delta
	for i in CAPACITY:
		if _ages[i] <= 0.0: continue
		_ages[i] = maxf(0.0, _ages[i] - delta)
		_positions[i] += Vector3(sin(_clock * 1.4 + i) * 0.12, 0.8 + _sizes[i] * 4, cos(_clock + i) * 0.09) * delta
		if _ages[i] <= 0.0 or _positions[i].y >= OceanTerrain.WATER_LEVEL:
			_ages[i] = 0.0
			_hide(i)
			continue
		var size := _sizes[i] * (1.0 + (8.0 - _ages[i]) * 0.12)
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), to_local(_positions[i])))

func _hide(i: int) -> void:
	_sizes[i] = 0.0
	multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3.ZERO))
