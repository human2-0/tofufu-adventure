class_name BattleRing
extends RefCounted
## Authored closing stages. One shared clock drives damage, map and boundary.

const RADII := [420.0, 240.0, 140.0, 82.0, 46.0, 22.0, 7.0, 0.0]
const HOLD: float = 20.0
const CLOSE: float = 40.0
const GRACE: float = 12.0
const CENTER := Vector2(-22, -22)

static func stage(time: float) -> int:
	return clampi(int(maxf(0, time - GRACE) / (HOLD + CLOSE)), 0, RADII.size() - 2)

static func radius(time: float) -> float:
	var index := stage(time)
	var elapsed := maxf(0, time - GRACE) - index * (HOLD + CLOSE)
	return lerpf(RADII[index], RADII[index + 1], clampf((elapsed - HOLD) / CLOSE, 0, 1))

static func damage(time: float) -> float:
	var closed_for := maxf(0, time - GRACE - (RADII.size() - 1) * (HOLD + CLOSE))
	return 2.0 + stage(time) * 2.0 + closed_for * 2.0

static func remaining(time: float) -> float:
	return maxf(0, GRACE + (stage(time) + 1) * (HOLD + CLOSE) - time)

static func center(time: float, anchor: Vector2 = CENTER) -> Vector2:
	# Move to the dry finale site before the last three circles. All circles nest.
	return CENTER.lerp(anchor, clampf((RADII[0] - radius(time)) / (RADII[0] - RADII[4]), 0, 1))

static func next_center(time: float, anchor: Vector2 = CENTER) -> Vector2:
	var next_radius: float = RADII[stage(time) + 1]
	return CENTER.lerp(anchor, clampf((RADII[0] - next_radius) / (RADII[0] - RADII[4]), 0, 1))

static func phase_remaining(time: float) -> float:
	var elapsed := maxf(0, time - GRACE) - stage(time) * (HOLD + CLOSE)
	return maxf(0, (HOLD if elapsed < HOLD else HOLD + CLOSE) - elapsed)

static func closing(time: float) -> bool:
	return fmod(maxf(0, time - GRACE), HOLD + CLOSE) >= HOLD

static func outside(at: Vector3, time: float, anchor: Vector2 = CENTER) -> bool:
	return radius(time) <= 0 or Vector2(at.x, at.z).distance_to(center(time, anchor)) > radius(time)
