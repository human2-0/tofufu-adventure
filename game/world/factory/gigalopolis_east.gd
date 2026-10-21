class_name GigalopolisEast
extends RefCounted
## Six authored eastern quarters with nine distinct structural families.

const COLUMNS: Array[float] = [292, 356, 420, 484, 548, 612]
const MIDDLE: Array[String] = ["arcade", "warehouse", "hall", "workshop", "arcade", "warehouse"]
const SOUTH: Array[String] = ["apartments", "water_tower", "apartments", "apartments", "clocktower", "water_tower"]
const LOOKOUTS: Array[Dictionary] = [
	{"at": Vector2(292, 50), "height": 8.0, "start": Vector2(23, 26), "finish": Vector2(23, -8), "landing": Vector2(23, -10), "deck": Vector2(16, -10), "title": "Gigalopolis · Grand Market"},
	{"at": Vector2(420, 50), "height": 12.0, "start": Vector2(23, 28), "finish": Vector2(23, -12), "landing": Vector2(23, -14), "deck": Vector2(17, -14), "title": "Gigalopolis · Civic Courtyard"},
	{"at": Vector2(548, 132), "height": 22.0, "start": Vector2(14, 46), "finish": Vector2(14, -3), "landing": Vector2(14, -5), "deck": Vector2(7, -5), "title": "Gigalopolis · East Clocktower"}
]

static func build(world: Meadow, parent: Node3D) -> void:
	for index in COLUMNS.size():
		var x := COLUMNS[index]
		_site(world, parent, Vector2(x, -24), "terraces")
		_site(world, parent, Vector2(x, 50), MIDDLE[index])
		_site(world, parent, Vector2(x, 88), "shops")
		_site(world, parent, Vector2(x, 132), SOUTH[index])
	for lookout in LOOKOUTS:
		var at: Vector2 = lookout.at
		var marker := Node3D.new()
		var offset := Vector2(-14, -3) if lookout.title == "Gigalopolis · Grand Market" else (Vector2(-6, -12) if lookout.title == "Gigalopolis · Civic Courtyard" else Vector2(-3, 1))
		marker.position = GigalopolisTerrain.point(at, lookout.height) + Vector3(offset.x, 0, offset.y)
		world.add_child(marker)
		world.map_npcs[lookout.title] = marker
		MeadowGeometry.signpost(parent, GigalopolisTerrain.point(at + lookout.start + Vector2(-4, 0)), "EASTERN ROOFTOP CAMP  ↑")
	GigalopolisEastStreets.build(parent)

static func _site(world: Meadow, parent: Node3D, at: Vector2, kind: String) -> void:
	var site := Node3D.new()
	site.name = "East_" + kind + "_" + str(int(at.x)) + "_" + str(int(at.y))
	site.position = GigalopolisTerrain.point(at)
	site.set_meta("city_structure", kind)
	parent.add_child(site)
	match kind:
		"terraces": GigalopolisHousing.terraces(site)
		"apartments": GigalopolisHousing.apartments(site)
		"shops": GigalopolisHousing.shops(site)
		"warehouse": GigalopolisIndustry.warehouse(site)
		"workshop": GigalopolisIndustry.workshop(site)
		"water_tower": GigalopolisIndustry.water_tower(site)
		"arcade": GigalopolisCivic.arcade(site)
		"hall": GigalopolisCivic.hall(site)
		"clocktower": GigalopolisCivic.clocktower(site)
	world.city_rooms.append_array(site.get_meta("city_rooms", []))
