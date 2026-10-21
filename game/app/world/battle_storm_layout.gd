class_name BattleStormLayout
extends RefCounted
## Seeded dry finale clearings, shared as two values rather than terrain queries on guests.

static func choose(game: BattleRoyaleGame) -> void:
	var candidates: Array[Vector2] = []
	var shape := BoxShape3D.new()
	shape.size = Vector3(16, 2.2, 16)
	for site: Array in game.match_state.deployment.sites:
		var point := Vector2(site[0], site[2])
		if point.distance_to(BattleRing.CENTER) > 235 or absf(site[1]) > 20: continue
		var at := Vector3(site[0], site[1], site[2])
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform.origin = at + Vector3.UP * 1.5
		query.collision_mask = 1
		if not game.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty(): continue
		var dry := true
		for i in 8:
			var offset := Vector2.from_angle(i * TAU / 8) * 8
			var ground := game.world.ground_point(at.x + offset.x, at.z + offset.y, 0.08)
			if game.world.is_water(ground) or absf(ground.y - at.y) > 1.2: dry = false; break
		if dry: candidates.append(point)
	if candidates.is_empty(): return # The authored nursery clearing remains the safe fallback.
	var rng := RandomNumberGenerator.new()
	rng.seed = game.room.epoch.hash() ^ 918371
	game.match_state.circle = candidates[rng.randi_range(0, candidates.size() - 1)]
