class_name MeadowBarn
extends RefCounted
## Twenty open-front chest cubicles, a wide central aisle and owner display tables.

const BAY_COUNT: int = 20
const SIZE := Vector3(14, 4.4, 28)

static func bay_position(index: int) -> Vector3:
	return Vector3(-4.9 if index < 10 else 4.9, 0.5, -11.7 + (index % 10) * 2.6)

static func front(index: int) -> Vector3:
	return Vector3.RIGHT if index < 10 else Vector3.LEFT

static func table_position(index: int) -> Vector3:
	return bay_position(index) + front(index) * 1.1 + Vector3.UP * 0.7

static func build(parent: Node3D, at: Vector3) -> Node3D:
	var barn := shell(parent, at, "B · STODOŁA · NON-PVP", SIZE, Color("78543a"), 4.0, true)
	barn.name = "Stodola"
	for index in BAY_COUNT:
		var bay := bay_position(index)
		MeadowGeometry.box(barn, bay + Vector3.UP * 0.4, Vector3(1.2, 0.8, 0.85), Color("946342"), true)
		MeadowGeometry.box(barn, bay + Vector3.UP * 0.88, Vector3(1.3, 0.18, 0.96), Color("bb8754"))
		MeadowGeometry.box(barn, bay + front(index) * 0.63 + Vector3.UP * 0.55, Vector3(0.07, 0.16, 0.15), Color("d6b360"))
		var table := table_position(index)
		MeadowGeometry.box(barn, table, Vector3(1.0, 0.12, 1.05), Color("ba9967"), true)
		for z in [-0.35, 0.35]:
			MeadowGeometry.box(barn, table + Vector3(0, -0.36, z), Vector3(0.10, 0.7, 0.10), Color("75543b"), true)
		if index != 14:
			MeadowGeometry.box(barn, bay + Vector3(0, 0.6, 1.22), Vector3(3.3, 1.2, 0.12), Color("84684d"), true)
		var label := Label3D.new()
		label.double_sided = false
		label.text = "%02d" % (index + 1)
		label.position = bay + front(index) * 0.65 + Vector3.UP * 1.55
		label.rotation.y = PI / 2.0 if index < 10 else -PI / 2.0
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.pixel_size = 0.006
		barn.add_child(label)
		MeadowBuildingDetails.chest(barn, index)
	for x in [-5.5, -4.0, 4.0, 5.5]:
		for level in 2:
			MeadowGeometry.box(barn, Vector3(x, 0.9 + level * 0.8, -13.2), Vector3(1.3, 0.75, 1.0), Color("c4a958"), true)
	MeadowSurfaces.apply_tree(barn)
	return barn

static func shell(parent: Node3D, at: Vector3, title: String, size: Vector3, color: Color, doorway: float = 4.0, courtyard_entry: bool = false) -> Node3D:
	var building := Node3D.new()
	building.name = title.to_pascal_case() if not title.is_empty() else "FarmRoom"
	building.position = at
	building.set_meta("map_footprint", Vector2(size.x, size.z))
	building.set_meta("weather_roof_height", size.y + 1.4)
	parent.add_child(building)
	MeadowGeometry.box(building, Vector3(0, 0.42, 0), Vector3(size.x, 0.16, size.z), Color("a8a493"), true)
	var walls: Array[MeshInstance3D] = []
	var roofs: Array[MeshInstance3D] = []
	walls.append(MeadowGeometry.box(building, Vector3(0, size.y / 2, -size.z / 2), Vector3(size.x, size.y, 0.25), color, true))
	for side in [-1.0, 1.0]:
		if courtyard_entry and side > 0:
			for end in [-1.0, 1.0]:
				walls.append(MeadowGeometry.box(building, Vector3(size.x / 2, size.y / 2, end * (size.z / 4 + 0.55)), Vector3(0.25, size.y, size.z / 2 - 1.1), color, true))
		else:
			walls.append(MeadowGeometry.box(building, Vector3(side * size.x / 2, size.y / 2, 0), Vector3(0.25, size.y, size.z), color, true))
		var panel := (size.x - doorway) / 2.0
		walls.append(MeadowGeometry.box(building, Vector3(side * (doorway / 2 + panel / 2), size.y / 2, size.z / 2), Vector3(panel, size.y, 0.25), color, true))
	for side in [-1.0, 1.0]:
		var roof := MeadowGeometry.box(building, Vector3(side * size.x / 4, size.y + 0.65, 0), Vector3(size.x / 2 + 0.8, 0.22, size.z + 0.8), Color("493d35"))
		roof.rotation.z = -side * 0.20
		roof.create_convex_collision()
		roofs.append(roof)
	building.set_meta("interior_roofs", roofs)
	building.set_meta("interior_walls", walls)
	for view in walls + roofs: SolidOcclusion.box(view)
	var ramp := MeadowGeometry.box(building, Vector3(0, 0.22, size.z / 2 + 0.75), Vector3(doorway, 0.12, 1.8), Color("a8a493"), true)
	ramp.rotation.x = 0.27
	if courtyard_entry: _courtyard_entry(building, size, walls)
	if not title.is_empty(): MeadowGeometry.signpost(building, Vector3(size.x / 2 + 1.7, 0, size.z / 2), title)
	MeadowBuildingDetails.shell(building, size, color.r > color.b * 1.25, roofs, walls)
	return building

static func _courtyard_entry(building: Node3D, size: Vector3, walls: Array[MeshInstance3D]) -> void:
	var entrance := Node3D.new()
	entrance.name = "CourtyardEntrance"
	entrance.position.x = size.x / 2
	building.add_child(entrance)
	for side in [-1.0, 1.0]:
		walls.append(MeadowGeometry.box(building, Vector3(size.x / 2, 1.7, side * 1.15), Vector3(0.35, 3.4, 0.18), Color("a57a4c"), true))
		MeadowGeometry.box(entrance, Vector3(0.35, 1.55, side * 2.0), Vector3(0.16, 3.0, 1.25), Color("9b7047"), true)
	walls.append(MeadowGeometry.box(building, Vector3(size.x / 2, 3.5, 0), Vector3(0.35, 0.25, 2.6), Color("a57a4c"), true))
	var ramp := MeadowGeometry.box(entrance, Vector3(0.75, 0.22, 0), Vector3(1.8, 0.12, 2.0), Color("a8a493"), true)
	ramp.rotation.z = -0.27

static func contains(barn: Node3D, at: Vector3) -> bool:
	var local := barn.to_local(at)
	return absf(local.x) < SIZE.x / 2 and absf(local.z) < SIZE.z / 2 and local.y > -0.5
