class_name WorldContours
extends RefCounted
## Seeded coherent terrain variation; no global RNG state or runtime allocations.

static func noise(at: Vector2, seed: int) -> float:
	var cell := Vector2i(floori(at.x), floori(at.y))
	var t := at - Vector2(cell)
	t = t * t * (Vector2.ONE * 3.0 - t * 2.0)
	return lerpf(lerpf(_hash(cell.x, cell.y, seed), _hash(cell.x + 1, cell.y, seed), t.x), lerpf(_hash(cell.x, cell.y + 1, seed), _hash(cell.x + 1, cell.y + 1, seed), t.x), t.y)

static func _hash(x: int, z: int, seed: int) -> float:
	var value := (x * 73856093 ^ z * 19349663 ^ seed * 83492791) & 0x7fffffff
	value = ((value >> 13) ^ value) * 1274126177 & 0x7fffffff
	return float(value) / 1073741823.5 - 1.0

static func coast(x: float, seed: int) -> float:
	var variation := noise(Vector2(x / 37.0, 2.7), seed) * 13.0 + noise(Vector2(x / 13.0, 5.1), seed + 91) * 4.0
	return variation * smoothstep(8.0, 25.0, absf(x))

static func edge_x(z: float, width: float, seed: int, side: float) -> float:
	return width - 9.0 + noise(Vector2(z / 32.0, side * 4.7), seed) * 5.0 + noise(Vector2(z / 11.0, side * 8.3), seed + 47) * 2.0

static func rim(x: float, z: float, width: float, start: float, end: float, seed: int, cap: bool = false) -> float:
	var side := -1.0 if x < 0.0 else 1.0
	var edge := edge_x(z, width, seed, side)
	var distance := absf(x) - edge
	if cap:
		var end_distance := absf(z - start) - (absf(end - start) - 9.0 + coast(x, seed) * 0.35)
		distance = maxf(distance, end_distance)
	var band := smoothstep(-6.0, 3.0, distance)
	return band * (12.0 + noise(Vector2(x, z) / 23.0, seed + 67) * 3.0)
