class_name MeadowGardens
extends RefCounted
## Floral garden, walnut/pump, food beds and distant agricultural scenery.

static func build(world: Meadow) -> void:
	var garden := Node3D.new()
	garden.name = "E_FloralGarden"
	garden.position = world.ground_point(47, -25)
	world.add_child(garden)
	MeadowFlowers.build(garden, world.world_seed)
	_walnut(world, world.ground_point(46, -35))
	MeadowGardenFurniture.build(world)
	var butterflies := MeadowButterflies.new()
	butterflies.position = garden.position
	world.add_child(butterflies)
	_food_beds(world)
	_fields(world)
	_forest(world)

static func _walnut(world: Meadow, at: Vector3) -> void:
	var tree := Node3D.new()
	tree.name = "WalnutTree"
	tree.position = at
	world.add_child(tree)
	MeadowGeometry.box(tree, Vector3(0, 2.3, 0), Vector3(0.75, 4.6, 0.75), Color("76644a"), true)
	for offset in [Vector3(0, 5, 0), Vector3(-1.6, 4.3, 0), Vector3(1.6, 4.5, 0), Vector3(0, 4.2, 1.8)]:
		MeadowGeometry.rock(tree, offset, Vector3(2.6, 1.6, 2.2), Color("69834b"))
	MeadowWalnuts.scatter(tree)

static func _food_beds(world: Meadow) -> void:
	var names: Array[String] = ["POTATOES", "CUCUMBERS", "RED BERRIES", "BEETROOTS"]
	for row in 4:
		var z := -39.0 + row * 5
		MeadowGeometry.signpost(world, world.ground_point(69.5, z), "F · " + names[row])
		for i in 5:
			var at := world.ground_point(61 + i * 1.5, z)
			MeadowGeometry.box(world, at + Vector3.UP * 0.04, Vector3(1.3, 0.08, 2.8), Color("72533a"))
			var plant := MeadowProduce.new()
			plant.item_id = ["potato", "cucumber", "red_berries", "beetroot"][row]
			plant.position = at
			world.add_child(plant)
			world.produce.append(plant)

static func _fields(world: Meadow) -> void:
	var soy_mesh := SphereMesh.new()
	soy_mesh.radius = 0.25
	soy_mesh.height = 0.65
	soy_mesh.radial_segments = 12
	soy_mesh.rings = 6
	soy_mesh.material = MeadowGeometry.material(Color("759f4e"))
	var wheat_mesh := CylinderMesh.new()
	wheat_mesh.top_radius = 0.05
	wheat_mesh.bottom_radius = 0.018
	wheat_mesh.height = 1.25
	wheat_mesh.radial_segments = 8
	wheat_mesh.material = MeadowGeometry.material(Color("d7b963"))
	for kind in 2:
		var poses: Array[Transform3D] = []
		for i in 1800:
			var x := 73.8 + (i % 40) * 0.72 if kind == 0 else 18.4 + (i % 30) * 0.70
			var z := -77.2 + (i / 40) * 0.63 if kind == 0 else 20.4 + (i / 30) * 0.56
			poses.append(Transform3D(Basis.IDENTITY, world.ground_point(x, z, 0.4 if kind == 0 else 0.63)))
		SceneryInstances.build(world, "NortheastSoyFields" if kind == 0 else "SouthernWheatFields", soy_mesh if kind == 0 else wheat_mesh, poses)
	MeadowGeometry.signpost(world, world.ground_point(74, -46), "NORTHEAST · SOYBEANS")
	MeadowGeometry.signpost(world, world.ground_point(22, 19), "SOUTH · WHEAT")

static func _forest(world: Meadow) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world.world_seed + 341
	for i in 95:
		var x := rng.randf_range(16, 70)
		var z := rng.randf_range(-80, -56)
		if world.terrain.path_distance(x, z) < 3 or absf(x - world.terrain.river_x(z)) < 4: continue
		if MeadowVillage.BOUNDS.grow(1.5).has_point(Vector2(x, z)): continue
		var crowded := false
		for spawn: Vector2 in FarmCombatGrounds.FOREST_ARMORED_SPAWNS + FarmCombatGrounds.CAMPS:
			if Vector2(x, z).distance_to(spawn) < 7.0: crowded = true
		if crowded: continue
		var tree := Meadow.TREE.instantiate() as Node3D
		tree.position = world.ground_point(x, z)
		tree.scale = Vector3.ONE * rng.randf_range(0.9, 1.45)
		world.add_child(tree)
		for j in 2:
			var at := world.ground_point(x + 1.3 + j * 0.5, z + 0.8)
			MeadowGeometry.box(world, at + Vector3.UP * 0.18, Vector3(0.1, 0.36, 0.1), Color("e5d8b7"))
			MeadowGeometry.rock(world, at + Vector3.UP * 0.38, Vector3(0.25, 0.12, 0.25), Color("946442"))
	for i in 16:
		var plant := MeadowProduce.new()
		plant.item_id = "forest_mushroom"
		plant.position = world.ground_point(19 + (i % 8) * 6.1, -61 - (i / 8) * 9)
		world.add_child(plant)
		world.produce.append(plant)
