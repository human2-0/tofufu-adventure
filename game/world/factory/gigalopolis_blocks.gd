class_name GigalopolisBlocks
extends RefCounted
## Authored street blocks and six reachable expedition rooftops.

const ROOFS: Array[Vector3] = [Vector3(112, 8, 40), Vector3(122, 8, 126), Vector3(122, 8, 162), Vector3(190, 10, 126), Vector3(186, 8, 240), Vector3(208, 12, 374)]
const TITLES: Array[String] = ["Gigalopolis · Factory Watch", "Gigalopolis · Rooftop Camp", "Gigalopolis · South Terrace", "Gigalopolis · Sea Lookout", "Gigalopolis · Shore Camp", "Gigalopolis · Volcano Watch"]
const BLOCKS: Array[Vector2] = [Vector2(112, -31), Vector2(134, -31), Vector2(166, -31), Vector2(134, 40), Vector2(166, 40), Vector2(198, -25), Vector2(222, -25), Vector2(198, 36), Vector2(222, 36), Vector2(122, 86), Vector2(188, 86), Vector2(188, 166), Vector2(150, 216), Vector2(176, 278), Vector2(218, 344)]

static func build(world: Meadow, parent: Node3D) -> void:
	for index in BLOCKS.size():
		var at := BLOCKS[index]
		_building(parent, at, 6.0 + (index % 3) * 2.0, false)
	for index in ROOFS.size():
		var site := ROOFS[index]
		var room := _building(parent, Vector2(site.x, site.z), site.y, true)
		var deck := GigalopolisTerrain.point(Vector2(site.x, site.z), site.y)
		GigalopolisGeometry.camp(room, Vector3.UP * site.y)
		GigalopolisGeometry.recon(room, Vector3(5, site.y, -5))
		GigalopolisInterior.finish(room, "home")
		var marker := Node3D.new()
		marker.name = "CityLookout" + str(index)
		marker.position = deck
		world.add_child(marker)
		world.map_npcs[TITLES[index]] = marker
		MeadowGeometry.signpost(parent, GigalopolisTerrain.point(Vector2(site.x + 7, site.z + 20)), "ROOFTOP CAMP  ↑")
	# A guarded roof bridge crosses the lane while leaving its ground route open.
	var start := GigalopolisTerrain.point(Vector2(122, 133), 8)
	GigalopolisGeometry.stair(parent, start, GigalopolisTerrain.point(Vector2(122, 155), 8), 3.0)

static func _building(parent: Node3D, at: Vector2, height: float, accessible: bool) -> Node3D:
	var base := GigalopolisTerrain.point(at)
	var room := GigalopolisInterior.shell(parent, base, Vector3(14, height, 14))
	room.set_meta("city_block", true)
	GigalopolisGeometry.box(room, Vector3.UP * (height - 0.15), Vector3(16, 0.3, 16), "metal", true)
	for side: float in [-1, 1]:
		for offset: float in [-4.3, 0, 4.3]:
			for floor_index in maxi(1, int(height / 3)):
				var y := 2.2 + floor_index * 3.0
				if side < 0 or offset != 0 or floor_index > 0:
					_window(room, Vector3(offset, y, side * 7.05), Vector3(2.4, 1.7, 0.12), Vector3(0, 0, side))
				_window(room, Vector3(side * 7.05, y, offset), Vector3(0.12, 1.7, 2.4), Vector3(side, 0, 0))
	GigalopolisBuildingDetails.door(room, Vector3(0, 0, 7.12), 3)
	if accessible:
		_roof_access(parent, at, base.y + height)
	else:
		GigalopolisGeometry.box(room, Vector3(0, height + 0.5, -2), Vector3(6, 1, 5), "metal")
		GigalopolisGeometry.box(room, Vector3(-4, height + 1.6, -4), Vector3(0.9, 3.2, 0.9), "brass", true)
		GigalopolisInterior.finish(room, "home")
	return room

static func _window(parent: Node3D, at: Vector3, size: Vector3, normal: Vector3) -> void:
	GigalopolisGeometry.box(parent, at, size + Vector3(0.15, 0.18, 0.15), "metal").set_meta("city_wall", true)
	MeadowGeometry.box(parent, at + normal * 0.12, size, Color("d8dfc2")).set_meta("city_wall", true)

static func _roof_access(parent: Node3D, at: Vector2, top: float) -> void:
	var start := GigalopolisTerrain.point(at + Vector2(10, 20))
	var finish := Vector3(at.x + 10, top, at.y - 1)
	GigalopolisGeometry.stair(parent, start, finish)
	GigalopolisGeometry.box(parent, Vector3(at.x + 9, top - 0.15, at.y - 3), Vector3(6, 0.3, 4), "paving", true)
	for side in [-1.0, 1.0]:
		var bridge: bool = at.x == 122 and ((at.y == 126 and side > 0) or (at.y == 162 and side < 0))
		if bridge:
			for x in [-5.5, 5.5]:
				GigalopolisGeometry.box(parent, Vector3(at.x + x, top + 0.6, at.y + side * 7.7), Vector3(4, 1.2, 0.2), "metal", true)
		else:
			GigalopolisGeometry.box(parent, Vector3(at.x, top + 0.6, at.y + side * 7.7), Vector3(15.6, 1.2, 0.2), "metal", true)
	GigalopolisGeometry.box(parent, Vector3(at.x - 7.7, top + 0.6, at.y), Vector3(0.2, 1.2, 15.6), "metal", true)
	GigalopolisGeometry.box(parent, Vector3(at.x + 7.7, top + 0.6, at.y + 3.2), Vector3(0.2, 1.2, 8.4), "metal", true)
	GigalopolisGeometry.box(parent, Vector3(at.x + 11.9, top + 0.6, at.y - 3.6), Vector3(0.2, 1.2, 3.2), "metal", true)
