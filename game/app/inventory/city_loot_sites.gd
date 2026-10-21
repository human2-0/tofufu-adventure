class_name CityLootSites
extends RefCounted
## Append-only indices persist in the city chest mask; never reorder shipped sites.

const POINTS: Array[Vector2] = [Vector2(112, -35), Vector2(166, 36), Vector2(122, 82), Vector2(188, 162), Vector2(176, 274), Vector2(288, -29), Vector2(302, 85), Vector2(278, 50), Vector2(350, 40), Vector2(359, 132), Vector2(406, 47), Vector2(424, -29), Vector2(477, 40), Vector2(475, 123), Vector2(534, 50), Vector2(545, 128), Vector2(606, 40), Vector2(616, -29)]
const MASK: int = (1 << 18) - 1
const PRIMARY: Array[String] = ["apple", "edamame", "red_berries", "soy_milk", "tofu_white_chunk", "potato", "cucumber", "apple", "mature_bean", "soy_milk", "bright_leaf_boots", "red_berries", "knife", "tofu_white_chunk", "potato", "seed_satchel", "edamame", "apple"]
const COUNTS: Array[int] = [3, 5, 3, 1, 3, 3, 3, 3, 2, 1, 1, 3, 1, 3, 3, 1, 5, 3]

static func contents(index: int) -> Array:
	return [[PRIMARY[index], COUNTS[index]], ["tofu_white_chunk" if index % 3 == 0 else "apple", 1]]

static func position_for(world: Meadow, index: int) -> Vector3:
	var at := POINTS[index]
	var result := world.ground_point(at.x, at.y, 0.02)
	for room in world.city_rooms:
		var local := room.to_local(result)
		var size: Vector3 = room.get_meta("city_size")
		if absf(local.x) < size.x / 2 and absf(local.z) < size.z / 2:
			result.y = room.global_position.y + float(room.get_meta("city_floor")) + 0.02
			break
	return result
