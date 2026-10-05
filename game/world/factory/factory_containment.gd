class_name FactoryContainment
extends RefCounted
## Authored walkable rooms and recovery points. The app supplies unlocked progression.

const OUTSIDE := -1
const RAMP := 6
const FLOOR_TOLERANCE := 0.8
const ROOM_CENTERS: Array[Vector3] = [
	Vector3(300, 0, -180), Vector3(322, 0, -180), Vector3(344, 0, -180),
	Vector3(344, 4, -206), Vector3(322, 4, -206), Vector3(300, 4, -206),
]
const SAFE_ANCHORS: Array[Vector3] = [
	Vector3(300, 0.2, -176), Vector3(322, 0.2, -176), Vector3(344, 0.2, -176),
	Vector3(344, 4.2, -202), Vector3(322, 4.2, -202), Vector3(300, 4.2, -202),
	Vector3(356, 2.2, -193),
]

static func room_at(at: Vector3) -> int:
	if not at.is_finite(): return OUTSIDE
	# The ramp joins the two decks. Its floor height is derived from its length.
	if at.x >= 352.5 and at.x <= 359.0 and at.z >= -209.0 and at.z <= -177.0:
		var ramp_y := clampf((-at.z - 180.0) * 4.0 / 26.0, 0.0, 4.0)
		if at.y >= ramp_y - FLOOR_TOLERANCE and at.y <= ramp_y + 2.6:
			return RAMP
	for index in ROOM_CENTERS.size():
		var center := ROOM_CENTERS[index]
		if absf(at.x - center.x) > 11.5 or absf(at.z - center.z) > 10.3: continue
		if at.y >= center.y - FLOOR_TOLERANCE and at.y <= center.y + 3.5:
			return index
	return OUTSIDE

static func contains(at: Vector3) -> bool:
	return room_at(at) != OUTSIDE

static func permitted_transition(from_room: int, to_room: int, cleared_stage: int) -> bool:
	if to_room == OUTSIDE or to_room > RAMP or to_room < 0: return false
	if from_room == to_room: return true
	if from_room == OUTSIDE: return false
	if to_room == RAMP: return from_room == 2 and cleared_stage >= 3 or from_room == 3 and cleared_stage >= 3
	if from_room == RAMP: return to_room == 2 or to_room == 3 and cleared_stage >= 3
	if abs(from_room - to_room) != 1: return false
	if mini(from_room, to_room) == 2: return false
	return cleared_stage > mini(from_room, to_room)

static func recovery_anchor(room: int) -> Vector3:
	if room < 0 or room >= SAFE_ANCHORS.size(): return SAFE_ANCHORS[0]
	return SAFE_ANCHORS[room]

static func legal_ground_anchor(at: Vector3, cleared_stage: int) -> bool:
	var room := room_at(at)
	if room == OUTSIDE: return false
	if room == RAMP: return cleared_stage >= 3
	if room > cleared_stage: return false
	var expected_y := 0.0 if room < 3 else 4.0
	return absf(at.y - expected_y) <= FLOOR_TOLERANCE
