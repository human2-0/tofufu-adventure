class_name BattlePlantLayout
extends RefCounted
## Dry, flat deployment clearings. Reuses the map's terrain and collision queries.

static func populate(game: BattleRoyaleGame) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = game.room.epoch.hash() ^ 721871
	var cells: Array[Vector2] = []
	for z in 18:
		for x in 18: cells.append(Vector2(-324 + x * 36, -324 + z * 36))
	for i in range(cells.size() - 1, 0, -1):
		var other := rng.randi_range(0, i)
		var swap := cells[i]
		cells[i] = cells[other]
		cells[other] = swap
	var sites: Array = []
	var shape := BoxShape3D.new()
	shape.size = Vector3(5, 2.2, 5)
	for cell in cells:
		for attempt in 8:
			var point := cell + Vector2(rng.randf_range(-9, 9), rng.randf_range(-9, 9))
			if point.distance_to(BattleRing.CENTER) > 330: continue
			var at := game.world.ground_point(point.x, point.y, 0.08)
			if game.world.is_water(at) or not _flat(game, at): continue
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = shape
			query.transform.origin = at + Vector3.UP * 1.3
			query.collision_mask = 1
			if not game.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty(): continue
			sites.append([snappedf(at.x, 0.001), snappedf(at.y, 0.001), snappedf(at.z, 0.001)])
			break
		if sites.size() == BattleDeploymentState.LIMIT: break
	if sites.size() < game.bodies.size(): return false
	game.match_state.deployment = BattleDeploymentState.create(sites, game.bodies.size())
	return true

static func _flat(game: BattleRoyaleGame, at: Vector3) -> bool:
	for offset: Vector2 in [Vector2.ZERO, Vector2(-1.6, 0), Vector2(1.6, 0), Vector2(0, 1.6)]:
		var point := game.world.ground_point(at.x + offset.x, at.z + offset.y, 0.08)
		if game.world.is_water(point) or absf(point.y - at.y) > 0.25: return false
		var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP, point + Vector3.DOWN * 1.5, 1)
		var floor_hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
		if floor_hit.is_empty() or floor_hit.normal.y < 0.85 or absf(floor_hit.position.y - point.y + 0.08) > 0.2: return false
	return true

static func emerge(game: BattleRoyaleGame) -> bool:
	var state := game.match_state.deployment
	for body in game.bodies:
		body.placement_peers.assign(game.bodies)
		body.collision_layer = 0
	var success := true
	for slot in game.bodies.size():
		var site: Array = state.sites[int(state.choices[slot])]
		var offset := Vector2((-1.6 if slot % 2 == 0 else 1.6), 0) if BattleOptions.duos(game.room.options) else Vector2(0, 1.6)
		var point := game.world.ground_point(site[0] + offset.x, site[2] + offset.y, 0.08)
		if not game.bodies[slot].relocate(point):
			success = false
			break
		var row: Array = game.match_state.rows[slot]
		var at := game.bodies[slot].position
		row[0] = at.x
		row[1] = at.y
		row[2] = at.z
		for index in range(3, 6): row[index] = 0.0
	for body in game.bodies: body.collision_layer = 2
	game.camera.reset_follow()
	return success
