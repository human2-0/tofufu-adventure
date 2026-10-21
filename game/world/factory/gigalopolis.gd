class_name Gigalopolis
extends RefCounted
## Factory old town, southern wards and a coastal city reaching Embercrown.

static func build(world: Meadow) -> void:
	var parent := Node3D.new()
	parent.name = "Gigalopolis"
	world.add_child(parent)
	GigalopolisTerrain.build(parent)
	# Broad elevated causeway blends into the graded meadow road.
	# It is presentation-only: the meadow and district ground provide one continuous
	# collision surface underneath, avoiding coplanar z-fighting at x=80..84.
	MeadowGeometry.box(parent, Vector3(110, 0.025, 6), Vector3(140, 0.05, 7), Color("c9ba96"))
	for x in range(88, 178, 10):
		MeadowGeometry.box(parent, Vector3(x, 0.02, 6), Vector3(3, 0.02, 0.16), Color("fff0bf"))
	MeadowGeometry.signpost(parent, Vector3(65, 0, 10), "GIGALOPOLIS  >")
	MeadowGeometry.signpost(parent, Vector3(104, 0, 10), "GIGALOPOLIS · FACTORY DISTRICT")
	GigalopolisBlocks.build(world, parent)
	world.city_rooms.append_array(parent.get_meta("city_rooms", []))
	GigalopolisStreets.build(parent)
	GigalopolisEast.build(world, parent)
	# The old walls become short north-side remnants; south/east streets stay open.
	for x in [116.0, 160.0]:
		GigalopolisGeometry.box(parent, Vector3(x, 1.1, -44), Vector3(30, 2.2, 0.6), "stone", true)
