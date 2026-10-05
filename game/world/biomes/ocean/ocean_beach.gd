class_name OceanBeach
extends RefCounted
## A broad sandy shore with dune grass, shells and driftwood.

static func build(ocean: OceanWorld) -> void:
	var shore := Node3D.new()
	shore.name = "Beach"
	ocean.add_child(shore)
	# Rocky headlands close the shore wings beyond Meadow's collision footprint.
	for side in [-1.0, 1.0]:
		OceanProps.sea_rock(shore, ocean.point(side * 125, -85), Vector3(16, 4, 8))
	var rng := RandomNumberGenerator.new()
	rng.seed = ocean.farm.noise.seed + 90968
	for i in 90:
		var x := rng.randf_range(-130, 130)
		var z := rng.randf_range(-100, -90) - WorldContours.coast(x, ocean.farm.noise.seed)
		if absf(x) < 6.0: continue
		var at := ocean.point(x, z)
		if at.y < OceanTerrain.WATER_LEVEL + 0.3: continue
		if i % 4 == 0:
			var shell := OceanCreatureArt.ellipsoid(shore, at + Vector3.UP * 0.08, Vector3(0.24, 0.12, 0.19), Color("f1d9b6"))
			shell.rotation.y = rng.randf_range(0, TAU)
		else:
			for blade in 4:
				var grass := MeadowGeometry.box(shore, at + Vector3(blade * 0.09, 0.23, 0), Vector3(0.055, 0.46, 0.035), Color("9fba76"))
				grass.rotation.z = (blade - 1.5) * 0.19
	for x in [-39.0, 57.0, 94.0]:
		var log := MeadowGeometry.box(shore, ocean.point(x, -96, 0.16), Vector3(3.4, 0.32, 0.36), Color("b29b7a"))
		log.rotation.y = x * 0.04
