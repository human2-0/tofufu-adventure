class_name ParrotFlight
extends RefCounted
## Per-rider free-flight steering, altitude and landing state; no input/scene reads.

const SPEED: float = 24.0
const CLIMB_SPEED: float = 10.0
const MAX_ALTITUDE: float = 96.0
var altitude: float = 8.0
var landing: bool = false
var last_position: Vector3
var planar := Vector2.ZERO

func _init(at: Vector3) -> void:
	last_position = at

func velocity(move: Vector2, rise: bool, descend: bool, clearance: float, delta: float) -> Vector3:
	if rise:
		landing = false
	altitude = clampf(altitude + (float(rise) - float(descend)) * CLIMB_SPEED * delta, 1.5, MAX_ALTITUDE)
	var target := 1.04 if landing else altitude
	planar = planar.move_toward(move.limit_length() * SPEED * (0.5 if landing else 1.0), 72.0 * delta)
	return Vector3(planar.x, clampf((target - clearance) * 4.0, -6.0 if landing else -12.0, 12.0), planar.y)
