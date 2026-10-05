class_name ParrotLanding
extends RefCounted
## Actual floor/water/interior queries for outdoor boarding and safe dismounting.

static func outdoor(game: AdventureGame, at: Vector3) -> bool:
	if game.world.volcanic.castle.contains(at): return false
	if TofuFactory.contains(game.world.to_local(at)): return false
	for building in game.world.interiors:
		var size: Vector2 = building.get_meta("map_footprint")
		var local := building.to_local(at)
		if absf(local.x) < size.x * 0.5 + 0.7 and absf(local.z) < size.y * 0.5 + 0.7: return false
	return true

static func surface(game: AdventureGame, actor: Player) -> Vector3:
	var at := actor.global_position
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.4, at + Vector3.DOWN * 160.0, 1, [actor.get_rid()])
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or hit.normal.y < 0.65: return Vector3.INF
	var floor_at: Vector3 = hit.position
	if not outdoor(game, floor_at) or game.world.is_water(game.world.to_local(floor_at)): return Vector3.INF
	return floor_at

static func dismount(game: AdventureGame, actor: Player, floor_at: Vector3) -> bool:
	var airborne := actor.global_position
	if not actor.relocate(floor_at + Vector3.UP * 0.05, true): return false
	if not safe_position(game, actor.global_position) or actor.global_position.distance_to(floor_at) > 2.0:
		actor.global_position = airborne
		return false
	actor.parrot_rest = actor.position
	var beside := actor.global_position
	var ray := PhysicsRayQueryParameters3D.create(beside + Vector3(2.3, 2, 0), beside + Vector3(2.3, -3, 0), 1, [actor.get_rid()])
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty() and hit.normal.y >= 0.65 and safe_position(game, hit.position) and actor.relocate(hit.position + Vector3.UP * 0.05, true):
		if safe_position(game, actor.global_position) and actor.global_position.distance_to(beside) <= 4.5: return true
	actor.global_position = beside
	return true

static func safe_position(game: AdventureGame, at: Vector3) -> bool:
	return outdoor(game, at) and not game.world.is_water(game.world.to_local(at)) and not VolcanicLava.molten(game.world.to_local(at))

static func height(game: AdventureGame, at: Vector3) -> float:
	var local := game.world.to_local(at)
	var ground := game.world.ground_point(local.x, local.z).y
	if VolcanicTerrain.contains(Vector2(local.x, local.z)):
		ground = maxf(ground, VolcanicTerrain.WATER_LEVEL)
	if local.z <= OceanTerrain.NORTH_START and local.z >= OceanTerrain.NORTH_END:
		ground = maxf(ground, OceanTerrain.WATER_LEVEL)
	if RiverCourse.contains(Vector3(local.x, ground, local.z)):
		ground = maxf(ground, RiverCourse.level(local.z))
	return game.world.to_global(Vector3(local.x, ground, local.z)).y
