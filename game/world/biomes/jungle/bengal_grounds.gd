class_name BengalGrounds
extends RefCounted
## Twelve renewable opponents in four small packs off the sanctuary's main path.

const CENTERS: Array[Vector2] = [Vector2(-22, 246), Vector2(24, 264), Vector2(-23, 284), Vector2(24, 308)]

static func spawns() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for center in CENTERS:
		for offset in [Vector2(-3, 0), Vector2(3, 0), Vector2(0, 4)]:
			points.append(center + offset)
	return points

static func contains(at: Vector3) -> bool:
	return Rect2(-60, 225, 112, 110).has_point(Vector2(at.x, at.z))
