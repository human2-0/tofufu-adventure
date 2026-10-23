class_name PlanarMovement
extends RefCounted
## Firm ground steering and finite curved release; air control remains independent.

static func step(direction: Vector2, velocity: Vector3, speed: float, grounded: bool, grip: float, tuning: PlayerTuning, delta: float) -> Vector3:
	var bounded := direction.limit_length()
	var planar := Vector2(velocity.x, velocity.z)
	var moving := bounded.length_squared() > 0.01
	if not moving: bounded = Vector2.ZERO
	var rate := tuning.acceleration if moving else tuning.friction
	if grounded:
		if moving and planar.dot(bounded) < planar.length() * bounded.length() * 0.95:
			rate = tuning.turn_braking
		rate *= tuning.ground_response * clampf(grip, 0.15, 1.0)
	else:
		if moving and planar.dot(bounded) < -0.1: rate = tuning.turn_braking
		rate *= tuning.air_control
	if grounded and not moving:
		planar = _release(planar, speed, grip, tuning.ground_stop_seconds, delta)
	else:
		planar = planar.move_toward(bounded * speed, rate * delta)
	velocity.x = planar.x
	velocity.z = planar.y
	return velocity

static func _release(planar: Vector2, speed: float, grip: float, seconds: float, delta: float) -> Vector2:
	if planar.is_zero_approx() or speed <= 0.0: return Vector2.ZERO
	# sqrt(speed) falls linearly: velocity follows a squared ease-out to exact rest.
	# No release timer is needed, so snapshots/prediction can resume from velocity.
	var root := maxf(0.0, sqrt(planar.length()) - sqrt(speed) * clampf(grip, 0.15, 1.0) * delta / maxf(0.001, seconds))
	return planar.normalized() * root * root if root > 0.0001 else Vector2.ZERO
