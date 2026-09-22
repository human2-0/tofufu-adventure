class_name Meadow
extends Node3D
## Fufufarm composition: seeded terrain, countryside scenery and village placeholders.

const TREE: PackedScene = preload("res://game/world/tree.tscn")
@export var world_seed: int = 1847
var weapon_merchant: Node3D
var quest_npc: Node3D
var map_npcs: Dictionary[String, Node3D] = {}
var jungle: JungleWorld
var terrain: FarmTerrain
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = world_seed
	terrain = FarmTerrain.new(world_seed)
	terrain.build(self)
	_river_and_bridge()
	_farmstead()
	_village()
	FarmCombatGrounds.build(self, terrain)
	_countryside()
	FarmFoliage.populate(self, terrain, _rng)
	jungle = JungleWorld.new()
	jungle.farm = terrain
	add_child(jungle)

func ground_point(x: float, z: float, lift: float = 0.0) -> Vector3:
	if x > 42 and jungle != null: return jungle.point(x, z, lift)
	return terrain.point(x, z, lift)

func is_water(at: Vector3) -> bool:
	return absf(at.x - terrain.river_x(at.z)) < 2.65 and at.y < -0.15

func _river_and_bridge() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-42, 42):
		for corner in [Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(1, 0), Vector2(1, 1), Vector2(-1, 1)]:
			var depth: float = z + corner.y
			surface.set_uv(Vector2((corner.x + 1) * 0.5, (depth + 42) / 84))
			surface.add_vertex(Vector3(terrain.river_x(depth) + corner.x * 2.6, -0.28, depth))
	surface.generate_normals()
	var water := MeshInstance3D.new()
	water.name = "IrrigationStream"
	water.mesh = surface.commit()
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/river.gdshader")
	water.material_override = material
	add_child(water)
	for i in 19:
		MeadowGeometry.box(self, Vector3(7.04 + i * 0.44, -0.055, 4), Vector3(0.42, 0.15, 2.8), Color("be9868"), true)
	for side in [-1.0, 1.0]:
		for x in [7.0, 9.0, 11.0, 13.0, 15.0]:
			MeadowGeometry.box(self, Vector3(x, 0.5, 4 + side * 1.4), Vector3(0.17, 1.0, 0.17), Color("8b6c4e"), true)
		MeadowGeometry.box(self, Vector3(11, 0.85, 4 + side * 1.4), Vector3(8.3, 0.12, 0.12), Color("d7b383"), true)
	for i in 70:
		var z := _rng.randf_range(-40, 40)
		if absf(z - 4) < 3.0:
			continue
		var x := terrain.river_x(z) + (-1.0 if i % 2 == 0 else 1.0) * _rng.randf_range(2.9, 3.5)
		MeadowGeometry.rock(self, ground_point(x, z), Vector3(0.4, 0.25, 0.3), Color("9eac89"), true)
	MeadowGeometry.signpost(self, ground_point(5.5, 6.5), "VILLAGE  >")

func _farmstead() -> void:
	var bank := FarmBuildings.cottage(self, ground_point(-22, -22), "SEED BANK", Color("7e9e87"), Vector3(7.4, 3.7, 5.3))
	for x in [-2.6, -1.4, 1.5, 2.7]:
		MeadowGeometry.box(bank, Vector3(x, 0.35, 3.2), Vector3(0.8, 0.7, 0.7), Color("bb915b"), true)
		MeadowGeometry.box(bank, Vector3(x, 0.4, 3.56), Vector3(0.35, 0.23, 0.025), Color("f4e2b2"))
	# Round grain silo anchors the storage silhouette.
	MeadowGeometry.rock(self, ground_point(-28, -23, 2.0), Vector3(1.5, 2.7, 1.5), Color("cbbda0"), true)
	MeadowGeometry.rock(self, ground_point(-28, -23, 4.2), Vector3(1.65, 0.75, 1.65), Color("80a193"), true)
	MeadowGeometry.signpost(self, ground_point(-18, -15), "SEED STORAGE  ^")
	MeadowGeometry.signpost(self, ground_point(-4.8, 1.7), "FUFUFARM · NURSERY")
	MeadowGeometry.signpost(self, ground_point(-15, 24.5), "SOYBEAN FIELDS")
	for ends in [Vector4(-17.5, -12, -7, -12), Vector4(-17.5, -12, -17.5, -2), Vector4(-6.5, -10.5, 5, -10.5), Vector4(-18, 11, -18, 23), Vector4(-18, 24, -6, 24)]:
		FarmBuildings.fence(self, terrain, Vector2(ends.x, ends.y), Vector2(ends.z, ends.w))
	# A small scarecrow marks the second field.
	var at := ground_point(-10, 17)
	MeadowGeometry.box(self, at + Vector3.UP, Vector3(0.13, 2, 0.13), Color("8e7351"), true)
	MeadowGeometry.box(self, at + Vector3.UP * 1.4, Vector3(1.5, 0.45, 0.25), Color("bf8a65"), true)
	MeadowGeometry.rock(self, at + Vector3.UP * 1.9, Vector3.ONE * 0.3, Color("f3d694"), true)
	MeadowGeometry.rock(self, at + Vector3.UP * 2.12, Vector3(0.48, 0.1, 0.4), Color("957552"), true)

func _village() -> void:
	FarmBuildings.cottage(self, ground_point(20, -8), "ITEM SHOP", Color("779ea0"), Vector3(5.7, 3.1, 4.4))
	FarmBuildings.cottage(self, ground_point(30, 0), "WEAPON SHOP", Color("aa7e89"), Vector3(5.8, 3.1, 4.6))
	FarmBuildings.cottage(self, ground_point(32, 14), "MAYOR'S HOUSE", Color("c4926f"), Vector3(6.5, 3.5, 4.6))
	FarmBuildings.cottage(self, ground_point(31, -14), "", Color("a8ad7d"), Vector3(4.3, 2.6, 3.7))
	map_npcs["Mugi · Items"] = FarmBuildings.resident(self, ground_point(19.5, -4), "Mugi · Items", Color("8ab6a8"))
	weapon_merchant = FarmBuildings.resident(self, ground_point(29, 3.7), "Kaji · Weapons", Color("b98791"))
	quest_npc = FarmBuildings.resident(self, ground_point(30, 18), "Mayor Mame", Color("7c99bb"), true)
	map_npcs["Kaji · Weapons"] = weapon_merchant
	map_npcs["Mayor Mame"] = quest_npc
	# Well, market produce and a smith's anvil identify the village services.
	var well := ground_point(21, 4)
	MeadowGeometry.rock(self, well + Vector3.UP * 0.45, Vector3(1.0, 0.55, 1.0), Color("b1b5a2"), true)
	MeadowGeometry.rock(self, well + Vector3.UP * 0.92, Vector3(0.65, 0.04, 0.65), Color("69999e"))
	for side in [-1.0, 1.0]:
		MeadowGeometry.box(self, well + Vector3(side * 0.9, 1.25, 0), Vector3(0.15, 2.5, 0.15), Color("8e7558"), true)
	MeadowGeometry.box(self, well + Vector3.UP * 2.5, Vector3(2.5, 0.2, 1.9), Color("b98773"), true)
	var stall := ground_point(16.5, -3.6)
	MeadowGeometry.box(self, stall + Vector3.UP * 0.65, Vector3(2.1, 1.3, 0.9), Color("c9a172"), true)
	for i in 5:
		MeadowGeometry.rock(self, stall + Vector3(-0.8 + i * 0.4, 1.4, 0), Vector3(0.18, 0.15, 0.2), Color("cddd86"))
	var anvil := ground_point(32, 3.5)
	MeadowGeometry.box(self, anvil + Vector3.UP * 0.4, Vector3(0.85, 0.8, 0.75), Color("8b7054"), true)
	MeadowGeometry.box(self, anvil + Vector3.UP * 0.95, Vector3(1.35, 0.35, 0.6), Color("66747c"), true)

func _countryside() -> void:
	for i in 85:
		var x := _rng.randf_range(-39, 39)
		var z := _rng.randf_range(-39, 39)
		if x > 33 and z > 21 and z < 31: continue
		if terrain.path_distance(x, z) < 3.2 or terrain.is_field(x, z) or absf(x - terrain.river_x(z)) < 4.5:
			continue
		if FarmCombatGrounds.is_clearing(x, z):
			continue
		if Vector2(x, z).length() < 12 or (x > 14 and z > -19 and z < 22) or Vector2(x + 22, z + 22).length() < 7:
			continue
		var tree := TREE.instantiate() as Node3D
		tree.position = ground_point(x, z)
		tree.scale = Vector3.ONE * _rng.randf_range(0.85, 1.6)
		add_child(tree)
	# Uneven wooded hills hide the traversal edge and frame the farm valley.
	for i in 42:
		var angle := i * TAU / 42.0
		var radius := 47.0 + sin(angle * 3.0) * 3.0 + _rng.randf_range(-1, 3)
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		if x > 38 and z > 16 and z < 37: continue
		var hill_height := _rng.randf_range(3.0, 6.5)
		for center in FarmCombatGrounds.CAMPS:
			if Vector2(x, z).distance_to(center) < 17.0:
				hill_height = 1.0
		MeadowGeometry.rock(self, ground_point(x, z, 0.5), Vector3(5, hill_height, 5), Color("88a17a").lerp(Color("b6be8d"), _rng.randf_range(0, 0.6)))
	for side in [-1.0, 1.0]:
		var wall := MeadowGeometry.box(self, Vector3(side * 40, 6, 0), Vector3(1, 100, 81), Color.WHITE, true)
		wall.visible = false
		if side > 0:
			wall.queue_free()
			for segment in [Vector2(-9.5, 61), Vector2(35.5, 9)]:
				var edge := MeadowGeometry.box(self, Vector3(40, 35, segment.x), Vector3(1, 100, segment.y), Color.WHITE, true)
				edge.visible = false
		wall = MeadowGeometry.box(self, Vector3(0, 6, side * 40), Vector3(81, 20, 1), Color.WHITE, true)
		wall.visible = false
