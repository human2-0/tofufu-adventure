class_name BattleStormLayout
extends RefCounted
## Equal region odds among supported finale clearings, then a seeded site in that region.
static func choose(game: BattleRoyaleGame) -> void:
	game.match_state.circle = pick(candidates(game), game.room.epoch.hash() ^ 918371)

static func candidates(game: BattleRoyaleGame) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var shape := BoxShape3D.new()
	shape.size = Vector3(6, 2.2, 6)
	for site: Array in game.match_state.deployment.sites:
		var point := Vector2(site[0], site[2])
		if point.distance_to(BattleRing.CENTER) > BattleRing.MAX_ANCHOR: continue
		var at := Vector3(site[0], site[1], site[2])
		if VolcanicTerrain.contains(point) and VolcanicLava.molten(at): continue
		if not BattleChestLayout.clear(game, at, shape): continue
		var dry := true
		for i in 8:
			var offset := Vector2.from_angle(i * TAU / 8) * 8
			var ground := game.world.ground_point(at.x + offset.x, at.z + offset.y, 0.08)
			if game.world.is_water(ground) or absf(ground.y - at.y) > 1.2: dry = false; break
		if dry: result.append(point)
	return result

static func region(at: Vector2) -> int:
	if at.x >= 200: return 5 if at.y >= 188 else 4
	if at.x < -90: return 3
	if at.y < -120: return 2
	if at.y > 140: return 1
	return 0

static func pick(points: Array[Vector2], seed_value: int) -> Vector2:
	if points.is_empty(): return BattleRing.CENTER
	var regions: Dictionary = {}
	for at in points:
		var id := region(at)
		if not regions.has(id): regions[id] = []
		regions[id].append(at)
	var keys := regions.keys()
	keys.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var choices: Array = regions[keys[rng.randi_range(0, keys.size() - 1)]]
	return choices[rng.randi_range(0, choices.size() - 1)]
