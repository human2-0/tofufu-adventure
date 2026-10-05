class_name VolcanicProps
extends RefCounted
## Region-specific basalt fans, beach litter, mineral seams and pioneer vegetation.

static func build(parent: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = VolcanicTerrain.SEED
	var batch := VolcanicDetailBatch.new()
	for i in 2200:
		var at := VolcanicTerrain.CENTER + Vector2(rng.randf_range(-225, 225), rng.randf_range(-180, 180))
		var radius := VolcanicTerrain.coast_radius(at)
		if radius > 1.02 or reserved(at): continue
		var point := VolcanicTerrain.point(at)
		if point.y < 1.6: continue
		var angle := rng.randf() * TAU
		if radius > 0.82:
			_beach(batch, rng, point, angle, i)
		else:
			_inland(batch, rng, point, angle, i)
	for at in VolcanicAtmosphere.VENTS:
		for i in 12:
			var offset := Vector2(cos(i * TAU / 12), sin(i * TAU / 12)) * 1.0
			batch.add("stone", VolcanicTerrain.point(at + offset, 0.12), Vector3(0.4, 0.22, 0.4), Color("b4a36f"), i)
	for i in 64:
		var at := VolcanicTerrain.VOLCANO + Vector2(cos(i * TAU / 64), sin(i * TAU / 64)) * 17.4
		batch.add("basalt", VolcanicTerrain.point(at, 1.8), Vector3(1.7, 2.4, 1.7), Color("51434d"), i)
	batch.build(parent)

static func reserved(at: Vector2) -> bool:
	if at.distance_to(VolcanicTerrain.LANDING) < 12.0: return true
	if absf(at.x - LavaCastle.CENTER.x) < 47 and absf(at.y - LavaCastle.CENTER.y) < 65: return true
	if VolcanicRoutes.distance(at) < 7.0 or VolcanicLava.river_distance(at) < 5.5: return true
	for site in VolcanicLandmarks.SITES:
		if at.distance_to(site) < 22.0: return true
	return false

static func _beach(batch: VolcanicDetailBatch, rng: RandomNumberGenerator, at: Vector3, angle: float, index: int) -> void:
	var size := rng.randf_range(0.18, 0.65)
	if index % 5 == 0:
		batch.add("stone", at + Vector3.UP * 0.15, Vector3(1.9, 0.16, 0.2), Color("a88c6b"), angle)
	elif index % 3 == 0:
		batch.add("stone", at + Vector3.UP * 0.08, Vector3(size, 0.12, size * 0.7), Color("f0d8be"), angle)
	else:
		batch.add("stone", at + Vector3.UP * 0.12, Vector3(size, 0.23, size * 0.85), Color("575160"), angle)

static func _inland(batch: VolcanicDetailBatch, rng: RandomNumberGenerator, at: Vector3, angle: float, index: int) -> void:
	var size := rng.randf_range(0.5, 1.5)
	if index % 5 == 0:
		var height := rng.randf_range(1.5, 6.0)
		batch.add("basalt", at + Vector3.UP * height * 0.5, Vector3(size, height * 0.5, size), Color("4b424f"), angle)
	elif index % 7 == 0:
		batch.add("crystal", at + Vector3.UP * 0.75, Vector3(0.3, 0.9, 0.3), Color("dcaf63"), angle)
	elif index % 4 == 0 and at.y < 12:
		for leaf in 3:
			batch.add("stone", at + Vector3.UP * 0.3, Vector3(0.9, 0.25, 0.18), Color("758668"), angle + leaf * PI / 3)
	else:
		batch.add("stone", at + Vector3.UP * 0.3, Vector3(size, 0.5, size * 0.7), Color("6c5551"), angle)
