class_name MeadowVillage
extends RefCounted
## Satellite-plan farmstead; north is -Z. Buildings keep a broad courtyard.

const HOUSE := Vector2(46, -7)
const BARN := Vector2(24, -24)
const SHED := Vector2(26, -49)
const UNITS := Vector2(49, -54)
const FLOWERS := Vector2(47, -25)
const FOOD := Vector2(65, -30)
const BOUNDS := Rect2(17, -60, 55, 63)

static func build(world: Meadow) -> void:
	_house(world)
	world.seed_bank = MeadowBarn.build(world, world.ground_point(BARN.x, BARN.y))
	world.interiors.append(world.seed_bank)
	_shed(world)
	MeadowWorkingUnits.build(world, world.ground_point(UNITS.x, UNITS.y))
	MeadowGardens.build(world)
	world.quest_npc = resident(world, world.ground_point(46, -13), "Grandma Fufu · Quests", "grandma")
	world.weapon_merchant = resident(world, world.ground_point(33.5, -42.5), "Grandpa Fufu · Gear", "grandpa")
	world.map_npcs["Grandma Fufu · Quests"] = world.quest_npc
	world.map_npcs["Grandpa Fufu · Gear"] = world.weapon_merchant
	world.map_npcs["Stodoła · Personal chests"] = world.seed_bank
	MeadowGeometry.signpost(world, world.ground_point(19, 1), "STODOŁA · GRANDMA · GRANDPA ↑")
	MeadowGeometry.signpost(world, world.ground_point(69, 0), "COUNTRY ROAD · FIELDS")
	for i in 4:
		var cat := MeadowAnimal.new()
		cat.kind = "cat"
		cat.home = Vector2(36 + i * 3, -18)
		cat.roam_radius = 5.0
		cat.ground_point = world.ground_point
		cat.seed_value = 820 + i
		world.add_child(cat)

static func _house(world: Meadow) -> void:
	var house := FarmBuildings.cottage(world, world.ground_point(HOUSE.x, HOUSE.y), "A · DOM BABCI", Color("493024"), Vector3(10, 4, 7))
	house.rotation.y = PI
	# Recolor the authored shell, then add staggered mortar courses.
	(house.get_child(1) as MeshInstance3D).material_override = MeadowGeometry.material(Color("a64d39"))
	for row in 12:
		for side in [-1.0, 1.0]:
			MeadowGeometry.box(house, Vector3(side * 5.02, 0.4 + row * 0.29, 0), Vector3(0.025, 0.025, 7), Color("c18a70"))
		MeadowGeometry.box(house, Vector3(0, 0.4 + row * 0.29, -3.52), Vector3(10, 0.025, 0.025), Color("c18a70"))
		MeadowGeometry.box(house, Vector3(0, 0.4 + row * 0.29, 3.52), Vector3(10, 0.025, 0.025), Color("c18a70"))
		for column in 12:
			var x := -4.8 + column * 0.85 + (0.42 if row % 2 else 0.0)
			if absf(x) < 0.65 and row < 6: continue
			MeadowGeometry.box(house, Vector3(x, 0.54 + row * 0.29, 3.53), Vector3(0.025, 0.26, 0.025), Color("c18a70"))
	for i in 3:
		MeadowGeometry.box(house, Vector3(0, 0.08 + i * 0.09, 5.3 - i * 0.48), Vector3(3.0, 0.16 + i * 0.18, 0.48), Color("aaa99f"), true)
	MeadowGeometry.box(house, Vector3(0, 0.42, 3.95), Vector3(3, 0.2, 0.75), Color("aaa99f"), true)
	MeadowGeometry.box(house, Vector3(0.9, 0.66, 4), Vector3(0.85, 0.22, 0.56), Color("aa7d65"))
	MeadowGeometry.rock(house, Vector3(0.9, 0.8, 4), Vector3(0.32, 0.09, 0.2), Color("c9b7a1"))
	MeadowGeometry.rock(house, Vector3(1.4, 0.58, 4.25), Vector3(0.19, 0.06, 0.19), Color("699cac"))
	for side in [-1.0, 1.0]:
		MeadowGeometry.rock(house, Vector3(-0.9 + side * 0.12, 0.59, 4), Vector3(0.10, 0.06, 0.2), Color("493024"))

static func _shed(world: Meadow) -> void:
	var shed := MeadowBarn.shell(world, world.ground_point(SHED.x, SHED.y), "C · WIATA · MACHINERY", Vector3(13, 3.5, 8), Color("71503a"), 10.0)
	world.interiors.append(shed)
	for x in [-3.5, 2.0]:
		var tractor := Node3D.new()
		tractor.position = Vector3(x, 0.55, -1)
		shed.add_child(tractor)
		MeadowGeometry.box(tractor, Vector3(0, 1.1, 0), Vector3(1.3, 1.1, 2.4), Color("658948"), true)
		MeadowGeometry.box(tractor, Vector3(0, 1.8, -0.5), Vector3(1.5, 0.15, 1.4), Color("b94431"))
		for side in [-1.0, 1.0]:
			for z in [-0.8, 0.8]:
				MeadowGeometry.rock(tractor, Vector3(side * 0.85, 0.6, z), Vector3(0.28, 0.65 if z < 0 else 0.42, 0.65 if z < 0 else 0.42), Color("303633"), true)
		MeadowGeometry.box(tractor, Vector3(0, 1.75, 0.65), Vector3(0.12, 1.3, 0.12), Color("343c3d"))
	for i in 4:
		MeadowGeometry.rock(shed, Vector3(5, 0.8 + i * 0.22, -2.5), Vector3(0.6, 0.15, 0.6), Color("353b3a"))
		var plough := MeadowGeometry.box(shed, Vector3(-5 + i * 0.65, 0.65, 2), Vector3(0.4, 0.6, 0.8), Color("68727a"), true)
		plough.rotation.z = 0.45
	MeadowGeometry.box(shed, Vector3(4, 1.05, 2), Vector3(2.2, 0.15, 1), Color("997252"), true)
	for i in 4:
		MeadowGeometry.box(shed, Vector3(3.2 + i * 0.5, 1.2, 2), Vector3(0.08, 0.08, 0.8), Color("8a9398"))

static func resident(parent: Node3D, at: Vector3, title: String, asset: String) -> Node3D:
	var npc := Node3D.new()
	npc.name = asset.capitalize() + "Fufu"
	npc.position = at
	parent.add_child(npc)
	var sprite := MeadowResidentArt.new()
	sprite.asset = asset
	sprite.facing = Vector2.UP if asset == "grandma" else Vector2.DOWN
	npc.add_child(sprite)
	var body := StaticBody3D.new()
	body.name = "ResidentBody"
	body.collision_layer = 1
	body.collision_mask = 0
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.2
	collider.shape = capsule
	collider.position.y = 0.6
	body.add_child(collider)
	npc.add_child(body)
	MeadowGeometry.rock(npc, Vector3(0, 0.02, 0), Vector3(0.35, 0.02, 0.25), Color("637151"))
	var label := Label3D.new()
	label.double_sided = false
	label.name = "ResidentTitle"
	label.text = title
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.position.y = 2.6
	label.rotation.y = PI if asset == "grandma" else 0.0
	label.font_size = 28
	label.pixel_size = 0.007
	npc.add_child(label)
	return npc
