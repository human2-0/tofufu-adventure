class_name OceanWorld
extends Node3D
## Northern underwater world: a visible water ceiling above a walkable reef floor.

var farm: FarmTerrain
var access_open: bool = true

func _ready() -> void:
	name = "OceanWorld"
	OceanTerrain.build(self, farm)
	_water_surface()
	_entrance()
	_reef_ruins()
	_scatter()
	_boundaries()

func point(x: float, z: float, lift: float = 0.0) -> Vector3:
	return Vector3(x, OceanTerrain.height_at(x, z, farm) + lift, z)

func is_water(at: Vector3) -> bool:
	return at.z <= OceanTerrain.NORTH_START and at.z >= OceanTerrain.NORTH_END and absf(at.x) <= OceanTerrain.HALF_WIDTH and at.y < OceanTerrain.WATER_LEVEL

func _water_surface() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(OceanTerrain.HALF_WIDTH * 2.0, absf(OceanTerrain.NORTH_END - OceanTerrain.NORTH_START))
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.10, 0.53, 0.72, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.24
	material.metallic = 0.18
	plane.material = material
	var water := MeshInstance3D.new()
	water.name = "AquaDepthsSurface"
	water.mesh = plane
	water.position = Vector3(0, OceanTerrain.WATER_LEVEL, (OceanTerrain.NORTH_START + OceanTerrain.NORTH_END) * 0.5)
	add_child(water)

func _entrance() -> void:
	MeadowGeometry.signpost(self, point(0, OceanTerrain.NORTH_START + 5), "AQUADEPTHS · TEST ROUTE OPEN")
	var gate := MeadowGeometry.box(self, Vector3(0, 35, OceanTerrain.NORTH_START), Vector3(OceanTerrain.HALF_WIDTH * 2.0 + 2.0, 100, 2), Color.WHITE, true)
	gate.name = "DeepwaterGearGate"
	gate.visible = false
	if access_open:
		(gate.get_child(0) as StaticBody3D).collision_layer = 0
	for x in [-16.0, 16.0]: OceanProps.sea_rock(self, point(x, OceanTerrain.NORTH_START - 10), Vector3(4.8, 5.4, 4.4))

func _reef_ruins() -> void:
	var ruin := point(-52, -160)
	for side in [-1.0, 1.0]:
		MeadowGeometry.box(self, ruin + Vector3(side * 4.0, 2.3, 0), Vector3(1.1, 4.6, 1.1), Color("5b8b86"), true)
	MeadowGeometry.box(self, ruin + Vector3(0, 4.5, 0), Vector3(9.2, 0.8, 1.3), Color("6aa097"), true)
	for i in 10:
		var angle := i * TAU / 10.0
		OceanProps.coral(self, ruin + Vector3(cos(angle) * 6.2, 0, sin(angle) * 5.1), 0.8 + (i % 3) * 0.2, Color("dc7d8d") if i % 2 == 0 else Color("f0ad65"))
	for at in [Vector2(36, -188), Vector2(42, -192), Vector2(30, -194)]:
		OceanProps.sea_rock(self, point(at.x, at.y), Vector3(2.5, 3.2, 2.0))
	MeadowGeometry.box(self, point(36, -190, 1.4), Vector3(15, 1.1, 4.0), Color("785d48"), true)
	MeadowGeometry.signpost(self, point(10, -212), "FROSTCROWN REACH  ^")

func _scatter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4431
	for i in 125:
		var x := rng.randf_range(-132.0, 132.0)
		var z := rng.randf_range(-210.0, -98.0)
		if OceanTerrain.trail_distance(x, z) < 4.3 or Vector2(x + 52, z + 160).length() < 20.0 or Vector2(x - 36, z + 190).length() < 12.0:
			continue
		if i % 5 == 0:
			OceanProps.coral(self, point(x, z), rng.randf_range(0.8, 1.6), Color("e57890") if i % 2 == 0 else Color("f2a75e"))
		elif i % 2 == 0:
			OceanProps.kelp(self, point(x, z), rng.randf_range(1.2, 2.8))
		else:
			OceanProps.sea_rock(self, point(x, z), Vector3(0.8, 0.65, 0.7))
		if i % 6 == 0:
			OceanProps.fish(self, point(x + 0.6, z, rng.randf_range(1.8, 4.6)), Color("f4d45e"))

func _boundaries() -> void:
	for spec in [Vector4(-141, -152, 1, 140), Vector4(141, -152, 1, 140)]:
		var wall := MeadowGeometry.box(self, Vector3(spec.x, 30, spec.y), Vector3(spec.z, 100, spec.w), Color.WHITE, true)
		wall.visible = false
