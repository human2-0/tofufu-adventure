class_name OceanIslands
extends RefCounted
## Tideglass Atoll: a broken crescent, a tidal lagoon and three smaller islets.

const CENTER := Vector2(66, -157)
const ISLETS: Array[Vector3] = [Vector3(-86, -134, 8), Vector3(105, -186, 10), Vector3(-103, -193, 6)]

static func height_at(x: float, z: float, seabed: float, seed: int) -> float:
	var at := Vector2(x, z)
	var local := at - CENTER
	var distance := (local / Vector2(27, 23)).length()
	if distance < 1.7:
		distance += WorldContours.noise(at / 9.0, seed + 282) * 0.10
		var peak := 5.2 + WorldContours.noise(at / 12.0, seed + 741) * 0.7
		var island := lerpf(peak, seabed, smoothstep(0.66, 1.43, distance))
		var lagoon := ((local + Vector2(3, 2)) / Vector2(10, 8)).length()
		island = lerpf(minf(-0.75, island), island, smoothstep(0.80, 1.95, lagoon))
		var inlet := local.distance_to(Geometry2D.get_closest_point_to_segment(local, Vector2(-30, 4), Vector2(-3, -2)))
		island = lerpf(minf(-0.8, island), island, smoothstep(2.2, 5.4, inlet))
		seabed = maxf(seabed, island)
	for isle in ISLETS:
		var offset := at - Vector2(isle.x, isle.y)
		if offset.length_squared() > pow(isle.z * 2.0, 2): continue
		var radius := (offset / Vector2(isle.z, isle.z * 0.72)).length()
		radius += WorldContours.noise(at / 5.0, seed + 663) * 0.14
		seabed = maxf(seabed, lerpf(3.4, seabed, smoothstep(0.4, 1.65, radius)))
	return seabed
