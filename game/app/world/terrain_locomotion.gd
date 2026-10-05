class_name TerrainLocomotion
extends RefCounted
## App bridge from authored biome surfaces to the independent movement rules.

static func apply(actor: Player, world: Meadow) -> void:
	actor.surface_speed = 0.55 if world.is_water(actor.position) else 1.0
	actor.motor.surface_grip = 0.8 if actor.surface_speed < 1.0 else 1.0
	actor.motor.immersion = immersion(actor.position, world)
	if actor.motor.immersion > 0.0:
		actor.surface_speed = lerpf(0.72, 0.43, actor.motor.immersion)
		actor.motor.surface_grip = 0.62
	if not winter(actor.position): return
	actor.surface_speed = 0.9
	actor.motor.surface_grip = 0.68
	if Vector2(actor.position.x - 44, actor.position.z + 298).length() < 8.5:
		actor.surface_speed = 1.0
		actor.motor.surface_grip = 0.24

static func immersion(at: Vector3, world: Meadow) -> float:
	if world.volcanic != null and world.volcanic.is_water(at):
		return clampf((VolcanicTerrain.WATER_LEVEL - at.y - 0.25) / 1.1, 0.0, 1.0)
	if world.ocean == null or not world.ocean.is_water(at): return 0.0
	return clampf((OceanTerrain.WATER_LEVEL - at.y - 0.25) / 1.1, 0.0, 1.0)

static func saved_position(at: Vector3, world: Meadow) -> Vector3:
	if world.ocean == null or at.z > OceanTerrain.NORTH_START or at.z < OceanTerrain.NORTH_END or absf(at.x) > OceanTerrain.HALF_WIDTH: return at
	# Older saves may sit below the beach that replaced the shallow seabed.
	at.y = maxf(at.y, world.ocean.point(at.x, at.z, 0.05).y)
	return at

static func fallen(at: Vector3, world: Meadow) -> bool:
	# Keep nursery recovery, but permit authored floors below the old Y=-5 cutoff.
	var floor_height := world.ground_point(at.x, at.z).y
	return at.y < minf(-5.0, floor_height - 4.0)

static func winter(at: Vector3) -> bool:
	return at.z <= FrostTerrain.NORTH_START and at.z >= FrostTerrain.NORTH_END and absf(at.x) <= FrostTerrain.HALF_WIDTH
