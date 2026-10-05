class_name OceanWildlife
extends Node3D
## Bounded local schools and slow reef visitors, with no gameplay or network state.

var ocean: OceanWorld
var focus: Vector3 = Vector3.INF
var creatures: Array[Node3D] = []
var _homes: Array[Vector2] = []
var _kinds: Array[int] = []
var _clock: float = 0.0

func _ready() -> void:
	name = "OceanWildlife"
	var rng := RandomNumberGenerator.new()
	rng.seed = 66218
	for i in 60:
		var kind := 0 if i < 44 else (1 if i < 48 else (2 if i < 52 else 3))
		var color := [Color("f2cd67"), Color("79d8d8"), Color("ec9f84"), Color("b5bbf0")][i % 4] as Color
		var animal := OceanCreatureArt.build(kind, color)
		add_child(animal)
		creatures.append(animal)
		_kinds.append(kind)
		var school := Vector2(-26 + (i / 11) * 18, -131 - (i % 3) * 18)
		if school.x >= 46: school.x -= 44
		if i >= 56: school = OceanIslands.CENTER - Vector2(3, 2)
		_homes.append(school + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3)))
	_pose_creatures()
	_process(0.0)

func _process(delta: float) -> void:
	_clock += delta
	# Offshore wildlife is cosmetic; do not sample seabed noise outside its region.
	var nearby := focus.is_finite() and focus.z < OceanTerrain.NORTH_START + 24.0 and focus.z > OceanTerrain.NORTH_END - 24.0 and absf(focus.x) < OceanTerrain.HALF_WIDTH + 24.0
	visible = nearby
	if not nearby: return
	_pose_creatures()

func _pose_creatures() -> void:
	for i in creatures.size():
		var kind := _kinds[i]
		var pace := 0.32 if kind == 0 else 0.12
		var phase := _clock * pace + i * 0.63
		var radius := 2.0 if i >= 56 else (5.0 if kind == 0 else 9.0)
		var center := _homes[i]
		var at := Vector3(center.x + cos(phase) * radius, 0, center.y + sin(phase) * radius * 0.65)
		var floor_height := ocean.floor_grid.interpolated_height(Vector2(at.x, at.z))
		at.y = clampf(floor_height + 1.3 + (i % 4) * 0.6 + sin(phase * 2) * 0.25, floor_height + 0.8, OceanTerrain.WATER_LEVEL - 0.7)
		if kind == 0 and at.distance_squared_to(focus) < 9.0:
			at += Vector3(at.x - focus.x, 0, at.z - focus.z).normalized() * 1.0
		var animal := creatures[i]
		animal.position = at
		animal.rotation.y = atan2(-cos(phase) * 0.65, -sin(phase))
		if kind == 0:
			(animal.get_node("Tail") as Node3D).rotation.y = sin(_clock * 9 + i) * 0.45
		elif kind < 3:
			(animal.get_node("FinLeft") as Node3D).rotation.x = sin(_clock * 2.5 + i) * 0.3
			(animal.get_node("FinRight") as Node3D).rotation.x = -sin(_clock * 2.5 + i) * 0.3
		else:
			animal.scale = Vector3.ONE * (0.9 + sin(_clock * 2 + i) * 0.10)
