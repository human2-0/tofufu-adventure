class_name MeadowVillageGround
extends RefCounted
## Authored footpaths and planted/foundation exclusions share world X/Z coordinates.

const PATHS: Array[Vector2] = [
	Vector2(36, 4), Vector2(36, -51),
	Vector2(26, -45), Vector2(36, -45),
	Vector2(31, -24), Vector2(36, -24),
	Vector2(36, -16), Vector2(46, -16),
	Vector2(46, -14), Vector2(46, -30),
	Vector2(46, -30), Vector2(51, -37),
	Vector2(51, -37), Vector2(51, -46),
	Vector2(51, -46), Vector2(52.1, -50),
]

static func path_distance(at: Vector2) -> float:
	var distance := INF
	for index in range(0, PATHS.size(), 2):
		var start := PATHS[index]
		var travel := PATHS[index + 1] - start
		var along := clampf((at - start).dot(travel) / travel.length_squared(), 0, 1)
		distance = minf(distance, at.distance_to(start + travel * along))
	return distance

static func lawn(at: Vector2) -> bool:
	if Rect2(MeadowVillage.HOUSE - Vector2(5, 3.5), Vector2(10, 7)).grow(0.9).has_point(at): return false
	if Rect2(MeadowVillage.BARN - Vector2(7, 14), Vector2(14, 28)).grow(0.7).has_point(at): return false
	if Rect2(MeadowVillage.SHED - Vector2(6.5, 4), Vector2(13, 8)).grow(0.8).has_point(at): return false
	if Rect2(MeadowVillage.UNITS - Vector2(12.5, 4), Vector2(25, 8)).grow(0.8).has_point(at): return false
	if Rect2(59.8, -40.6, 9.2, 18.2).has_point(at): return false
	if Rect2(44.3, -13, 3.4, 3.8).has_point(at): return false
	if Rect2(MeadowVillage.SHED + Vector2(-5, 4), Vector2(10, 2.4)).has_point(at): return false
	if Rect2(MeadowVillage.UNITS + Vector2(-12.5, 4), Vector2(25, 2.4)).has_point(at): return false
	for side in 2:
		for row in 3:
			if ((at - flower_center(side, row)) / (flower_radii(side) + Vector2.ONE * 0.25)).length() < 1: return false
	# Walnut trunk, old well and the vegetable-facing bench have clean footing.
	if at.distance_to(Vector2(46, -35)) < 0.8: return false
	if at.distance_to(Vector2(56.5, -19)) < 2.0: return false
	return not Rect2(55.8, -27, 1.8, 3.5).has_point(at)

static func flower_center(side: int, row: int) -> Vector2:
	return MeadowVillage.FLOWERS + Vector2(-5.35 if side == 0 else 4.65, -4.9 + row * 4.8)

static func flower_radii(side: int) -> Vector2:
	return Vector2(3.0 if side == 0 else 3.6, 1.95)
