class_name OceanIslandScenery
extends RefCounted
## Palms, a sea arch, shell terraces and a quiet lookout above the tidal lagoon.

static func build(ocean: OceanWorld) -> Node3D:
	var island := Node3D.new()
	island.name = "TideglassAtoll"
	ocean.add_child(island)
	var rng := RandomNumberGenerator.new()
	rng.seed = ocean.farm.noise.seed + 21401
	for i in 28:
		var at := OceanIslands.CENTER + Vector2(rng.randf_range(-24, 24), rng.randf_range(-21, 21))
		var ground := ocean.point(at.x, at.y)
		if ground.y < 3.0: continue
		if i % 3 == 0:
			OceanProps.sea_rock(island, ground, Vector3(0.8, 0.35, 0.65))
		else:
			DesertProps.palm(island, ground, rng.randf_range(3.7, 6.4), rng.randf_range(0, TAU))
			DesertProps.yucca(island, ground + Vector3(0.8, 0, 0.7), 0.7)
	var arch := ocean.point(85, -157)
	for side in [-1.0, 1.0]:
		OceanProps.sea_rock(island, arch + Vector3(side * 2.1, 0, 0), Vector3(1.1, 2.4, 1.2))
	MeadowGeometry.rock(island, arch + Vector3.UP * 4.3, Vector3(3.5, 0.85, 1.3), Color("759a9b"))
	var marker := Marker3D.new()
	marker.name = "AtollLookout"
	marker.position = ocean.point(80, -169, 0.1)
	island.add_child(marker)
	MeadowGeometry.signpost(island, marker.position, "TIDEGLASS ATOLL · THE MOON'S POCKET")
	for i in 18:
		var angle := i * TAU / 18.0
		var at := OceanIslands.CENTER + Vector2(cos(angle) * 17, sin(angle) * 14)
		var ground := ocean.point(at.x, at.y)
		if ground.y < 1.9: continue
		OceanCreatureArt.ellipsoid(island, ground + Vector3.UP * 0.12, Vector3(0.45, 0.20, 0.35), Color("f4d5b1") if i % 2 else Color("c1ddd3"))
	for isle in OceanIslands.ISLETS:
		DesertProps.palm(island, ocean.point(isle.x, isle.y), 4.0, isle.z)
	return marker
