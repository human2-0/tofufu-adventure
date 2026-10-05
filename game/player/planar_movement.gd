class_name PlanarMovement
extends RefCounted
## Momentum on the X/Z plane; ground grip and limited air control are explicit inputs.

static func step(direction: Vector2, velocity: Vector3, speed: float, grounded: bool, grip: float, tuning: PlayerTuning, delta: float) -> Vector3:
	var bounded := direction.limit_length()
	var planar := Vector2(velocity.x, velocity.z)
	var target := bounded * speed
	var rate := tuning.acceleration if bounded.length_squared() > 0.01 else tuning.friction
	if bounded.length_squared() > 0.01 and planar.dot(bounded) < -0.1:
		rate = tuning.turn_braking
	rate *= clampf(grip, 0.15, 1.0) if grounded else tuning.air_control
	planar = planar.move_toward(target, rate * delta)
	velocity.x = planar.x
	velocity.z = planar.y
	return velocity
