class_name RiverCourse
extends RefCounted
## Shared authored watercourse: terrain, surface, wildlife and wading use one profile.

const START: float = -84.0
const END: float = 157.0
const OASIS := Vector2(-38.0, 148.0)
const POND_RADIUS := Vector2(11.0, 9.0)

static func center_x(z: float) -> float:
	var farm := 11.0 + sin((z - 4.0) * 0.12) * 2.2 * smoothstep(5.0, 14.0, absf(z - 4.0))
	if z <= 84.0: return farm
	var entrance := 11.0 + sin(80.0 * 0.12) * 2.2
	return lerpf(entrance, OASIS.x, smoothstep(84.0, 134.0, z))

static func half_width(z: float) -> float:
	var stream := 2.6 * (1.0 - smoothstep(142.0, 148.0, z))
	var pond := POND_RADIUS.x * sqrt(maxf(0.0, 1.0 - pow((z - OASIS.y) / POND_RADIUS.y, 2.0)))
	return maxf(stream, pond)

static func level(z: float) -> float:
	# Gentle northern headwaters, level village reach, then a descent to the oasis.
	return 1.8 - 2.08 * smoothstep(START, -42.0, z) - 1.72 * smoothstep(42.0, 134.0, z)

static func bank_distance(x: float, z: float) -> float:
	if z < START or z > END + 4.0: return 1000.0
	var stream := absf(x - center_x(z)) - 2.6 if z <= 142.0 else 1000.0
	var pond := (Vector2((x - OASIS.x) / POND_RADIUS.x, (z - OASIS.y) / POND_RADIUS.y).length() - 1.0) * POND_RADIUS.y
	return minf(stream, pond) if z >= 132.0 else stream

static func contains(at: Vector3) -> bool:
	return at.z <= END and bank_distance(at.x, at.z) < -0.02 and at.y < level(at.z) + 0.13

static func carve(x: float, z: float, original: float) -> float:
	var edge := bank_distance(x, z)
	var outer := lerpf(3.0, 9.0, smoothstep(84.0, 104.0, z))
	if edge > outer: return original
	var bed := level(z) - 0.57
	var rim := level(z) + 0.28
	var channel := lerpf(bed, rim, smoothstep(-0.9, 0.5, edge))
	return lerpf(channel, original, smoothstep(1.25, outer, maxf(edge, 0.0)))

static func point(z: float, lane: float = 0.0, lift: float = 0.0) -> Vector3:
	return Vector3(center_x(z) + lane * half_width(z), level(z) + lift, z)
