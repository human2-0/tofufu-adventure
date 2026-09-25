class_name RainGroundEffects
extends Node3D
## Local rain presentation: terrain-hugging puddles and drops that visibly land in them.

const PUDDLE_SITES: Array[Vector2] = [
	Vector2(-24.0, 6.0), Vector2(-20.5, -5.5), Vector2(-12.0, -4.5), Vector2(-11.5, 17.5),
	Vector2(-4.0, 3.5), Vector2(0.5, -4.0), Vector2(3.0, 6.5), Vector2(8.0, -3.0),
	Vector2(15.0, 5.5), Vector2(19.0, 11.0), Vector2(22.0, -5.5), Vector2(26.0, 3.0),
	Vector2(28.5, 16.0), Vector2(32.0, -11.0), Vector2(35.0, 11.0)
]
const DROP_COUNT: int = 34

var terrain: FarmTerrain
var wetness: float = 0.0
var puddle_count: int = 0
var _target: float = 0.0
var _age: float = 0.0
var _rng := RandomNumberGenerator.new()
var _puddle_materials: Array[ShaderMaterial] = []
var _drops: Array[Dictionary] = []

func _ready() -> void:
	assert(terrain != null, "RainGroundEffects requires FarmTerrain")
	_rng.seed = 9071
	_build_puddles()
	_build_drops()
	_sync_surface_materials()

func present(raining: bool) -> void:
	_target = 1.0 if raining else 0.0

func is_raining() -> bool:
	return _target > 0.0

func _process(delta: float) -> void:
	_age += delta
	wetness = move_toward(wetness, _target, delta * 0.55)
	_sync_surface_materials()
	for index in _drops.size():
		_step_drop(index, delta)

func _build_puddles() -> void:
	for index in PUDDLE_SITES.size():
		var at := PUDDLE_SITES[index]
		var radius := Vector2(0.7 + float(index % 3) * 0.18, 0.52 + float((index + 1) % 3) * 0.15)
		var puddle := MeshInstance3D.new()
		puddle.name = "RainPuddle%02d" % index
		puddle.mesh = _puddle_mesh(at, radius)
		var material := ShaderMaterial.new()
		material.shader = preload("res://game/world/rain_puddle.gdshader")
		material.set_shader_parameter("seed", float(index) * 0.137)
		puddle.material_override = material
		add_child(puddle)
		_puddle_materials.append(material)
	puddle_count = _puddle_materials.size()

func _puddle_mesh(center: Vector2, radius: Vector2) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for edge in 12:
		var start := TAU * float(edge) / 12.0
		var finish := TAU * float(edge + 1) / 12.0
		_add_puddle_vertex(surface, center, Vector2.ZERO, Vector2(0.5, 0.5))
		_add_puddle_vertex(surface, center, Vector2(cos(start) * radius.x, sin(start) * radius.y), Vector2(0.5 + cos(start) * 0.5, 0.5 + sin(start) * 0.5))
		_add_puddle_vertex(surface, center, Vector2(cos(finish) * radius.x, sin(finish) * radius.y), Vector2(0.5 + cos(finish) * 0.5, 0.5 + sin(finish) * 0.5))
	return surface.commit()

func _add_puddle_vertex(surface: SurfaceTool, center: Vector2, offset: Vector2, uv: Vector2) -> void:
	var at := terrain.point(center.x + offset.x, center.y + offset.y, 0.035)
	surface.set_uv(uv)
	surface.add_vertex(at)

func _build_drops() -> void:
	var drop_mesh := SphereMesh.new()
	drop_mesh.radius = 0.028
	drop_mesh.height = 0.16
	drop_mesh.radial_segments = 5
	drop_mesh.rings = 3
	var drop_material := StandardMaterial3D.new()
	drop_material.albedo_color = Color("c8edf4")
	drop_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mesh.material = drop_material
	for index in DROP_COUNT:
		var drop := MeshInstance3D.new()
		drop.name = "RainDrop%02d" % index
		drop.mesh = drop_mesh
		add_child(drop)
		var splash := MeshInstance3D.new()
		splash.name = "RainImpact%02d" % index
		var splash_mesh := SphereMesh.new()
		splash_mesh.radius = 1.0
		splash_mesh.height = 2.0
		splash_mesh.radial_segments = 10
		splash_mesh.rings = 3
		var splash_material := StandardMaterial3D.new()
		splash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		splash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		splash_material.albedo_color = Color(0.68, 0.91, 0.95, 0.0)
		splash_mesh.material = splash_material
		splash.mesh = splash_mesh
		splash.visible = false
		add_child(splash)
		_drops.append({"drop": drop, "splash": splash, "material": splash_material, "impact": -1.0, "site": index % PUDDLE_SITES.size()})
		_reset_drop(index, float(index) / float(DROP_COUNT) * 1.4)

func _step_drop(index: int, delta: float) -> void:
	var state := _drops[index]
	var drop := state.drop as MeshInstance3D
	var splash := state.splash as MeshInstance3D
	var impact := float(state.impact)
	if wetness < 0.02:
		drop.visible = false
		splash.visible = false
		return
	if impact >= 0.0:
		impact += delta
		state.impact = impact
		var progress := clampf(impact / 0.22, 0.0, 1.0)
		splash.visible = true
		splash.scale = Vector3.ONE * lerpf(0.018, 0.12, progress)
		splash.scale.y = 0.012
		var material := state.material as StandardMaterial3D
		material.albedo_color = Color(0.68, 0.91, 0.95, (1.0 - progress) * wetness * 0.62)
		if progress >= 1.0:
			_reset_drop(index, 0.0)
		return
	drop.visible = true
	drop.position.y -= delta * 7.5
	var ground := terrain.height_at(drop.position.x, drop.position.z) + 0.055
	if drop.position.y <= ground:
		drop.visible = false
		splash.position = Vector3(drop.position.x, ground, drop.position.z)
		state.impact = 0.0

func _reset_drop(index: int, delay: float) -> void:
	var state := _drops[index]
	var site := PUDDLE_SITES[int(state.site)]
	var angle := _rng.randf_range(0.0, TAU)
	var distance := sqrt(_rng.randf()) * 0.46
	var at := site + Vector2(cos(angle), sin(angle)) * distance
	var drop := state.drop as MeshInstance3D
	drop.position = terrain.point(at.x, at.y, 0.18 + delay * 7.5)
	(state.splash as MeshInstance3D).visible = false
	state.impact = -1.0

func _sync_surface_materials() -> void:
	terrain.ground_material.set_shader_parameter("wetness", wetness)
	for material in _puddle_materials:
		material.set_shader_parameter("wetness", wetness)
		material.set_shader_parameter("age", _age)
