class_name CameraMotion
extends RefCounted
## Presentation samples only; never changes an actor's physical transform.

var previous: Vector3
var current: Vector3
var initialized: bool = false

func reset(at: Vector3) -> void:
	previous = at
	current = at
	initialized = true

func push(at: Vector3) -> void:
	if not initialized or current.distance_squared_to(at) > 64.0:
		reset(at)
		return
	previous = current
	current = at

func sample(fraction: float) -> Vector3:
	return previous.lerp(current, clampf(fraction, 0.0, 1.0))
