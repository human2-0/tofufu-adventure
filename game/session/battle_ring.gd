class_name BattleRing
extends RefCounted
## Large-map circles stay nested; longer early closes leave time to rotate.
const RADII := [1000.0, 650.0, 360.0, 180.0, 46.0, 22.0, 7.0, 0.0]
const CLOSES := [120.0, 100.0, 60.0, 50.0, 40.0, 40.0, 40.0]
const HOLD: float = 20.0
const GRACE: float = 12.0
const MAX_ANCHOR: float = 900.0
const CENTER := Vector2(-22, -22)

static func start_of(index: int) -> float:
	var time := GRACE
	for i in mini(index, CLOSES.size()): time += HOLD + CLOSES[i]
	return time

static func total_time() -> float:
	return start_of(CLOSES.size())

static func stage(time: float) -> int:
	for i in CLOSES.size() - 1:
		if time < start_of(i + 1): return i
	return CLOSES.size() - 1

static func radius(time: float) -> float:
	var index := stage(time)
	return lerpf(RADII[index], RADII[index + 1], clampf((time - start_of(index) - HOLD) / CLOSES[index], 0, 1))

static func damage(time: float) -> float:
	return 2.0 + stage(time) * 2.0 + maxf(0, time - total_time()) * 2.0

static func remaining(time: float) -> float:
	return maxf(0, start_of(stage(time) + 1) - time)

static func center(time: float, anchor: Vector2 = CENTER) -> Vector2:
	return CENTER.lerp(anchor, clampf((RADII[0] - radius(time)) / (RADII[0] - RADII[4]), 0, 1))

static func next_center(time: float, anchor: Vector2 = CENTER) -> Vector2:
	var next_radius: float = RADII[stage(time) + 1]
	return CENTER.lerp(anchor, clampf((RADII[0] - next_radius) / (RADII[0] - RADII[4]), 0, 1))

static func phase_remaining(time: float) -> float:
	var elapsed := maxf(0, time - start_of(stage(time)))
	return maxf(0, (HOLD if elapsed < HOLD else HOLD + CLOSES[stage(time)]) - elapsed)

static func closing(time: float) -> bool:
	return time >= start_of(stage(time)) + HOLD

static func outside(at: Vector3, time: float, anchor: Vector2 = CENTER) -> bool:
	return radius(time) <= 0 or Vector2(at.x, at.z).distance_to(center(time, anchor)) > radius(time)
