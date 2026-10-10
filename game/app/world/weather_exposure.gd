class_name WeatherExposure
extends RefCounted
## Local precipitation exposure; the shared weather clock remains authoritative.

static func covered(game: AdventureGame, at: Vector3) -> bool:
	var castle := game.world.volcanic.castle
	# The three maze decks are enclosed; the royal rooftop is open to the sky.
	var royal := castle.to_local(at)
	if castle.contains(at) and absf(royal.x) < 27.0 and absf(royal.z) < 27.0 and royal.y < 24.0: return true
	if TofuFactory.contains(game.world.to_local(at)): return true
	for building in game.world.interiors:
		var size: Vector2 = building.get_meta("map_footprint")
		var local := building.to_local(at)
		if absf(local.x) < size.x * 0.5 and absf(local.z) < size.y * 0.5 and local.y > -0.5:
			if local.y < float(building.get_meta("weather_roof_height", 6.0)): return true
	return false

static func submerged(game: AdventureGame, at: Vector3) -> bool:
	return TerrainLocomotion.immersion(game.world.to_local(at), game.world) > 0.0

static func precipitation_floor(x: float, z: float, extra: float, game: AdventureGame) -> Vector3:
	var floor_at := game.world.ground_point(x, z, extra)
	# Drops stop at the water surface rather than falling through to the seabed.
	floor_at.y = maxf(floor_at.y, ParrotLanding.height(game, game.world.to_global(floor_at)))
	var castle := game.world.volcanic.castle
	var royal := castle.to_local(game.world.to_global(floor_at))
	if absf(royal.x) < 27.0 and absf(royal.z) < 27.0:
		floor_at.y = maxf(floor_at.y, castle.position.y + 24.0)
	for building in game.world.interiors:
		var size: Vector2 = building.get_meta("map_footprint")
		var local := building.to_local(game.world.to_global(floor_at))
		if absf(local.x) < size.x * 0.5 and absf(local.z) < size.y * 0.5:
			var roof := building.to_global(Vector3(0, float(building.get_meta("weather_roof_height", 6.0)), 0))
			floor_at.y = maxf(floor_at.y, game.world.to_local(roof).y)
	return floor_at
