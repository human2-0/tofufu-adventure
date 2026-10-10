class_name MeadowWorkingUnits
extends RefCounted
## Four separate concrete rooms: coop, locked store, wood kitchen and guest room.

static func build(world: Meadow, at: Vector3) -> void:
	var block := Node3D.new()
	block.name = "D_WorkingUnits"
	block.position = at
	block.set_meta("map_footprint", Vector2(25, 8))
	world.add_child(block)
	for index in 4:
		var room := MeadowBarn.shell(block, Vector3(-9.3 + index * 6.2, 0, 0), "", Vector3(6, 3, 8), Color("a2a498"))
		room.name = ["ChickenCoop", "LockedStore", "Kitchen", "GuestRoom"][index]
		world.interiors.append(room)
		if index == 0: _chickens(world, room)
		elif index == 1:
			MeadowGeometry.box(room, Vector3(0, 2.9, 0), Vector3(6, 0.25, 8), Color("a2a498"), true)
			MeadowGeometry.box(room, Vector3(0, 1.5, 4), Vector3(4.1, 3, 0.3), Color("5b605c"), true)
			MeadowGeometry.box(room, Vector3(0.4, 1.1, 4.22), Vector3(0.16, 0.25, 0.1), Color("a99b65"))
		elif index == 2: _kitchen(room)
		else:
			for x in [-1.7, 1.7]: _couch(room, Vector3(x, 0.5, -0.5))
		MeadowSurfaces.apply_tree(room)

static func _chickens(world: Meadow, room: Node3D) -> void:
	for i in 7:
		var chicken := MeadowAnimal.new()
		chicken.kind = "chick" if i < 3 else "chicken"
		chicken.home = Vector2(room.global_position.x, room.global_position.z)
		chicken.roam_radius = 1.8
		chicken.ground_point = func(x: float, z: float, lift: float = 0.0) -> Vector3: return world.ground_point(x, z, 0.5 + lift)
		chicken.seed_value = 600 + i
		world.add_child(chicken)
	for x in [-1.8, 0, 1.8]:
		MeadowGeometry.box(room, Vector3(x, 0.7, -3), Vector3(1.0, 0.4, 0.8), Color("c7ae69"))
	MeadowGeometry.box(room, Vector3(0, 0.75, 3.8), Vector3(2, 0.5, 0.12), Color("8c7854"), true)

static func _kitchen(room: Node3D) -> void:
	var hearth := MeadowHearth.new()
	room.add_child(hearth)
	MeadowGeometry.box(room, Vector3(1.4, 1.3, -2.5), Vector3(1.9, 0.12, 1), Color("9a8a71"), true)
	MeadowGeometry.rock(room, Vector3(1.4, 1.46, -2.5), Vector3(0.13, 0.15, 0.13), Color("e0dbc3"))
	MeadowGeometry.box(room, Vector3(1.4, 0.95, -0.7), Vector3(0.7, 0.12, 0.7), Color("81603f"), true)
	MeadowGeometry.box(room, Vector3(1.4, 1.35, -0.4), Vector3(0.7, 0.9, 0.12), Color("81603f"), true)
	for x in [1.15, 1.65]:
		for z in [-0.95, -0.45]:
			MeadowGeometry.box(room, Vector3(x, 0.7, z), Vector3(0.10, 0.5, 0.10), Color("81603f"), true)
	for i in 6:
		MeadowGeometry.box(room, Vector3(-1.8 + (i % 3) * 0.4, 0.65 + (i / 3) * 0.25, 1.6), Vector3(0.3, 0.22, 0.8), Color("80573b"))

static func _couch(room: Node3D, at: Vector3) -> void:
	MeadowGeometry.box(room, at + Vector3.UP * 0.35, Vector3(1.5, 0.65, 2.5), Color("842d32"), true)
	MeadowGeometry.box(room, at + Vector3(0, 0.95, -1.1), Vector3(1.5, 0.85, 0.2), Color("a63e42"), true)
	for side in [-1.0, 1.0]:
		MeadowGeometry.box(room, at + Vector3(side * 0.7, 0.65, 0), Vector3(0.16, 0.5, 2.5), Color("69352d"), true)
