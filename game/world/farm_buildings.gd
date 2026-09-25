class_name FarmBuildings
extends RefCounted
## Rounded storybook building placeholders and village residents, all local geometry.

static func cottage(parent: Node3D, at: Vector3, title: String, roof_color: Color, size: Vector3) -> Node3D:
	var house := Node3D.new()
	house.name = title.to_pascal_case() if not title.is_empty() else "Cottage"
	house.position = at
	house.set_meta("map_footprint", Vector2(size.x, size.z))
	parent.add_child(house)
	MeadowGeometry.box(house, Vector3(0, 0.18, 0), Vector3(size.x + 0.4, 0.36, size.z + 0.4), Color("b4a38a"), true)
	MeadowGeometry.box(house, Vector3(0, size.y * 0.5, 0), size, Color("f5deb0"), true)
	for x in [-size.x * 0.46, size.x * 0.46]:
		MeadowGeometry.box(house, Vector3(x, size.y * 0.5, size.z * 0.505), Vector3(0.18, size.y, 0.18), Color("8d694e"))
	_roof(house, size, roof_color)
	var front := size.z * 0.5 + 0.06
	MeadowGeometry.box(house, Vector3(0, 0.95, front), Vector3(1.1, 1.9, 0.12), Color("725946"))
	MeadowGeometry.rock(house, Vector3(0.35, 0.95, front + 0.09), Vector3.ONE * 0.06, Color("efd08a"))
	for x in [-size.x * 0.31, size.x * 0.31]:
		MeadowGeometry.box(house, Vector3(x, 1.65, front), Vector3(1.0, 1.05, 0.12), Color("739da3"))
		MeadowGeometry.box(house, Vector3(x, 1.65, front + 0.08), Vector3(1.1, 0.09, 0.1), Color("ffedc3"))
		MeadowGeometry.box(house, Vector3(x, 1.65, front + 0.08), Vector3(0.09, 1.1, 0.1), Color("ffedc3"))
		MeadowGeometry.box(house, Vector3(x, 1.03, front + 0.2), Vector3(1.2, 0.26, 0.48), Color("9d6c50"))
		for i in 4:
			MeadowGeometry.rock(house, Vector3(x - 0.42 + i * 0.28, 1.23, front + 0.2), Vector3(0.16, 0.14, 0.16), Color("f2b8bc"))
	if not title.is_empty():
		MeadowGeometry.signpost(house, Vector3(0, 1.8, front + 0.2), title)
	return house

static func seed_bank(parent: Node3D, at: Vector3) -> Node3D:
	var bank := Node3D.new()
	bank.name = "SeedBank"
	bank.position = at
	bank.set_meta("map_footprint", Vector2(8.4, 7.0))
	parent.add_child(bank)
	# A clear, walkable doorway replaces the old solid cottage volume.
	MeadowGeometry.box(bank, Vector3(0, 0.16, 0), Vector3(8.8, 0.32, 7.4), Color("b4a38a"), true)
	# The finished planked floor is solid at its visible height, keeping Fufu above the foundation.
	MeadowGeometry.box(bank, Vector3(0, 0.42, 0), Vector3(8.2, 0.16, 6.8), Color("e5c991"), true)
	MeadowGeometry.box(bank, Vector3(0, 2.15, -3.25), Vector3(8.2, 3.7, 0.35), Color("f5deb0"), true)
	for side in [-1.0, 1.0]:
		MeadowGeometry.box(bank, Vector3(side * 3.93, 2.15, 0), Vector3(0.35, 3.7, 6.85), Color("f5deb0"), true)
		MeadowGeometry.box(bank, Vector3(side * 2.55, 2.15, 3.25), Vector3(2.4, 3.7, 0.35), Color("f5deb0"), true)
	MeadowGeometry.box(bank, Vector3(0, 3.62, 3.25), Vector3(2.35, 0.78, 0.35), Color("f5deb0"), true)
	MeadowGeometry.box(bank, Vector3(0, 0.48, 3.72), Vector3(2.5, 0.16, 1.0), Color("b98a58"), true)
	_roof(bank, Vector3(7.85, 3.7, 6.5), Color("7e9e87"))
	for x in [-2.7, -0.9, 0.9, 2.7]:
		_chest(bank, Vector3(x, 0.86, -2.58))
	for z in [-1.35, 0.0, 1.35]:
		_chest(bank, Vector3(-3.18, 0.86, z))
		_chest(bank, Vector3(3.18, 0.86, z))
	MeadowGeometry.box(bank, Vector3(0, 3.0, -3.03), Vector3(4.0, 0.75, 0.08), Color("87684c"))
	var label := Label3D.new()
	label.text = "SEED BANK"
	label.position = Vector3(0, 3.0, 3.48)
	label.font_size = 34
	label.pixel_size = 0.008
	label.modulate = Color("f9e6af")
	label.no_depth_test = true
	label.render_priority = 127
	bank.add_child(label)
	return bank

static func _chest(parent: Node3D, at: Vector3) -> void:
	MeadowGeometry.box(parent, at, Vector3(1.25, 0.72, 0.68), Color("9d6c50"), true)
	MeadowGeometry.box(parent, at + Vector3(0, 0.4, 0.02), Vector3(1.34, 0.2, 0.76), Color("c79b7b"))
	MeadowGeometry.rock(parent, at + Vector3(0, 0.4, 0.41), Vector3(0.09, 0.1, 0.04), Color("efd08a"))

static func _roof(house: Node3D, size: Vector3, color: Color) -> void:
	var pitch := 0.48
	var width := (size.x * 0.5 + 0.65) / cos(pitch)
	for side in [-1.0, 1.0]:
		var roof := MeadowGeometry.box(house, Vector3(side * width * cos(pitch) * 0.5, size.y + 0.6, 0), Vector3(width, 0.28, size.z + 1.2), color)
		roof.rotation.z = -side * pitch
		roof.create_convex_collision()
	MeadowGeometry.box(house, Vector3(0, size.y + 0.6 + width * sin(pitch) * 0.5, 0), Vector3(0.3, 0.3, size.z + 1.35), color.lightened(0.15), true)
	MeadowGeometry.box(house, Vector3(size.x * 0.27, size.y + 1.15, -size.z * 0.22), Vector3(0.65, 1.9, 0.7), Color("c79b7b"), true)

static func resident(parent: Node3D, at: Vector3, title: String, coat: Color, mayor: bool = false) -> Node3D:
	var npc := Node3D.new()
	npc.name = title.to_pascal_case()
	npc.position = at
	parent.add_child(npc)
	MeadowGeometry.rock(npc, Vector3(0, 0.65, 0), Vector3(0.37, 0.55, 0.28), coat, true)
	MeadowGeometry.rock(npc, Vector3(0, 1.37, 0), Vector3(0.43, 0.43, 0.36), Color("ffe2b5"), true)
	for side in [-1.0, 1.0]:
		MeadowGeometry.rock(npc, Vector3(side * 0.15, 0.12, 0.08), Vector3(0.16, 0.13, 0.23), Color("6d5549"))
		MeadowGeometry.rock(npc, Vector3(side * 0.14, 1.39, 0.34), Vector3(0.045, 0.075, 0.025), Color("403e43"))
	MeadowGeometry.rock(npc, Vector3(0, 1.69, 0), Vector3(0.55, 0.1, 0.44), Color("eac580"))
	MeadowGeometry.rock(npc, Vector3(0, 1.79, 0), Vector3(0.32, 0.21, 0.28), Color("eac580"))
	if mayor:
		MeadowGeometry.rock(npc, Vector3(0, 1.22, 0.35), Vector3(0.22, 0.075, 0.07), Color("fff2d7"))
	var label := Label3D.new()
	label.name = "ResidentTitle"
	label.text = title
	if not mayor and "Gear" not in title:
		label.text += "\nSHOP · Coming soon"
	label.position.y = 2.45
	label.font_size = 28
	label.pixel_size = 0.009
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("fff0c5")
	label.no_depth_test = true
	label.render_priority = 127
	npc.add_child(label)
	return npc

static func fence(parent: Node3D, terrain: FarmTerrain, from: Vector2, to: Vector2) -> void:
	var count := int(ceil(from.distance_to(to) / 1.8))
	for i in count + 1:
		var p := from.lerp(to, float(i) / count)
		MeadowGeometry.box(parent, terrain.point(p.x, p.y, 0.48), Vector3(0.15, 0.96, 0.15), Color("b18a5e"), true)
		if i == count:
			continue
		var q := from.lerp(to, float(i + 1) / count)
		var start := terrain.point(p.x, p.y)
		var end := terrain.point(q.x, q.y)
		for y in [0.32, 0.72]:
			var rail := MeadowGeometry.box(parent, (start + end) * 0.5 + Vector3.UP * y, Vector3(0.09, 0.12, start.distance_to(end)), Color("d6b685"), true)
			rail.look_at(end + Vector3.UP * y, Vector3.UP)
