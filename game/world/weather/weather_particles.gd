class_name WeatherParticles
extends Node3D
## Bounded world-space rain, leaves and snow, animated in three instanced draws.
## No per-drop nodes, physics, screen overlays or network state.

const SIDE: int = 12
const SPACING: float = 3.0
const RAIN_PER_CELL: int = 4
var focus: Node3D
var ground_point: Callable
var raining: bool = false
var snow_strength: float = 0.0
var winter: bool = false
var sheltered: bool = false
var _snow: MultiMeshInstance3D
var _snow_material: ShaderMaterial
var _snow_amount: float = 0.0
var _rain: MultiMeshInstance3D
var _leaves: MultiMeshInstance3D
var _rain_material: ShaderMaterial
var _leaf_material: ShaderMaterial
var _wet: float = 0.0
var _gust: float = 0.0
var _heights: Dictionary[Vector2i, float] = {}
var _center := Vector2i(2147483647, 2147483647)

func _ready() -> void:
	_rain_material = _material(false)
	_leaf_material = _material(true)
	var streak := BoxMesh.new()
	streak.size = Vector3(0.014, 0.32, 0.014)
	_rain = _batch(streak, _rain_material, SIDE * SIDE * RAIN_PER_CELL)
	var leaf := PrismMesh.new()
	leaf.size = Vector3(0.13, 0.025, 0.065)
	_leaves = _batch(leaf, _leaf_material, SIDE * SIDE)
	_snow_material = ShaderMaterial.new()
	_snow_material.shader = preload("res://game/world/weather/snowfall.gdshader")
	_snow = _batch(SnowflakeMesh.build(), _snow_material, SIDE * SIDE * RAIN_PER_CELL)
	_snow.visible = false
	_rain.visible = false
	_leaves.visible = false

func _material(leaves: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/weather/weather_particles.gdshader")
	material.set_shader_parameter("leaves", leaves)
	return material

func _batch(mesh: Mesh, material: ShaderMaterial, count: int) -> MultiMeshInstance3D:
	var batch := MultiMeshInstance3D.new()
	batch.multimesh = MultiMesh.new()
	batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	batch.multimesh.use_custom_data = true
	batch.multimesh.mesh = mesh
	batch.multimesh.instance_count = count
	batch.material_override = material
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(batch)
	return batch

func present_wind(direction: Vector2, strength: float) -> void:
	_gust = strength
	_leaf_material.set_shader_parameter("wind", direction)
	_leaf_material.set_shader_parameter("strength", strength)
	_rain_material.set_shader_parameter("wind", direction)
	_snow_material.set_shader_parameter("wind", direction)
	_snow_material.set_shader_parameter("gust", strength)

func _process(delta: float) -> void:
	_wet = move_toward(_wet, 1.0 if raining and not winter and not sheltered else 0.0, delta * 0.55)
	_snow_amount = move_toward(_snow_amount, snow_strength if winter and not sheltered else 0.0, delta * 0.45)
	_rain.visible = _wet > 0.01 and not winter and not sheltered
	_leaves.visible = _gust > 0.02 and not winter and not sheltered
	_snow.visible = _snow_amount > 0.01 and winter and not sheltered
	_snow_material.set_shader_parameter("strength", _snow_amount)
	if not _rain.visible and not _leaves.visible and not _snow.visible: return
	_rain_material.set_shader_parameter("strength", _wet)
	var cell := Vector2i(floori(focus.global_position.x / SPACING), floori(focus.global_position.z / SPACING))
	if cell != _center: _place(cell)

func _place(center: Vector2i) -> void:
	_center = center
	# Stable world-cell seeds keep overlapping drops in place as the volume moves.
	var rng := RandomNumberGenerator.new()
	var low := INF
	var high := -INF
	var heights: Dictionary[Vector2i, float] = {}
	for z in SIDE:
		for x in SIDE:
			var cell := center + Vector2i(x - SIDE / 2, z - SIDE / 2)
			if _heights.has(cell):
				heights[cell] = _heights[cell]
				low = minf(low, heights[cell])
				high = maxf(high, heights[cell] + 13.0)
				continue
			rng.seed = hash(cell)
			var at := Vector2(cell) * SPACING
			var floor_at: Vector3 = ground_point.call(at.x, at.y, 0.0)
			heights[cell] = floor_at.y
			low = minf(low, floor_at.y)
			high = maxf(high, floor_at.y + 13.0)
			var index := posmod(cell.y, SIDE) * SIDE + posmod(cell.x, SIDE)
			for drop in RAIN_PER_CELL:
				var origin := floor_at + Vector3(rng.randf() * SPACING, 0, rng.randf() * SPACING)
				_rain.multimesh.set_instance_transform(index * RAIN_PER_CELL + drop, Transform3D(Basis.IDENTITY, origin))
				_rain.multimesh.set_instance_custom_data(index * RAIN_PER_CELL + drop, Color(rng.randf(), rng.randf(), rng.randf(), 1))
				_snow.multimesh.set_instance_transform(index * RAIN_PER_CELL + drop, Transform3D(Basis.IDENTITY, origin))
				_snow.multimesh.set_instance_custom_data(index * RAIN_PER_CELL + drop, Color(rng.randf(), rng.randf(), rng.randf(), 1))
			_leaves.multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, floor_at))
			_leaves.multimesh.set_instance_custom_data(index, Color(rng.randf(), rng.randf(), rng.randf(), 1))
	_heights = heights
	var corner := Vector2(center - Vector2i(SIDE / 2, SIDE / 2)) * SPACING
	var bounds := AABB(Vector3(corner.x - 4, low - 1, corner.y - 4), Vector3(SIDE * SPACING + 8, high - low + 2, SIDE * SPACING + 8))
	_rain.multimesh.custom_aabb = bounds
	_leaves.multimesh.custom_aabb = bounds
	_snow.multimesh.custom_aabb = bounds
