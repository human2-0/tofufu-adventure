class_name Gigalopolis
extends RefCounted
## Eastern industrial district and the forest road connecting it to the meadow.

static func build(parent: Node3D) -> void:
	MeadowGeometry.box(parent, Vector3(132, -0.3, 6), Vector3(104, 0.6, 100), Color("8d9d8c"), true)
	# Broad elevated causeway blends into the graded meadow road.
	MeadowGeometry.box(parent, Vector3(110, -0.05, 6), Vector3(140, 0.1, 7), Color("c9ba96"), true)
	for x in range(88, 178, 10):
		MeadowGeometry.box(parent, Vector3(x, 0.02, 6), Vector3(3, 0.02, 0.16), Color("fff0bf"))
		MeadowGeometry.box(parent, Vector3(x, 1.7, 11), Vector3(0.15, 3.4, 0.15), Color("45625e"), true)
		MeadowGeometry.box(parent, Vector3(x, 3.3, 11), Vector3(0.8, 0.3, 0.8), Color("ffe1a0"))
	MeadowGeometry.signpost(parent, Vector3(65, 0, 10), "GIGALOPOLIS  >")
	MeadowGeometry.signpost(parent, Vector3(104, 0, 10), "GIGALOPOLIS · FACTORY DISTRICT")
	for x in [112.0, 134.0, 166.0]:
		for z in [-31.0, 40.0]:
			var at := Vector3(x, 0, z)
			MeadowGeometry.box(parent, at + Vector3(0, 4, 0), Vector3(13, 8, 13), Color("66817d"), true)
			MeadowGeometry.box(parent, at + Vector3(0, 8.3, 0), Vector3(14, 0.6, 14), Color("3c5755"), true)
			for dx in [-4.0, 0.0, 4.0]:
				for y in [2.0, 5.5]: MeadowGeometry.box(parent, at + Vector3(dx, y, 6.55), Vector3(1.5, 1.5, 0.1), Color("d4c998"))
	for z in [-44.0, 56.0]: MeadowGeometry.box(parent, Vector3(132, 2, z), Vector3(104, 4, 0.5), Color("58706a"), true)
	MeadowGeometry.box(parent, Vector3(184, 2, 6), Vector3(0.5, 4, 100), Color("58706a"), true)
