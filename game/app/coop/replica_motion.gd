class_name ReplicaMotion
extends RefCounted
## Bounded snapshot interpolation for remote views, including uneven packet arrivals.

const DELAY: float = 0.075
const MAX_SAMPLES: int = 8
var _samples: Array[Dictionary] = []

func push(at: Vector3, velocity: Vector3, stamp: float, reset: bool = false) -> void:
	if reset or (not _samples.is_empty() and at.distance_squared_to(_samples.back().at) > 25.0):
		_samples.clear()
	_samples.append({"at": at, "velocity": velocity, "stamp": stamp})
	while _samples.size() > MAX_SAMPLES: _samples.pop_front()

func sample(stamp: float) -> Vector3:
	if _samples.is_empty(): return Vector3.ZERO
	var when := stamp - DELAY
	for index in range(1, _samples.size()):
		var before := _samples[index - 1]
		var after := _samples[index]
		if when <= after.stamp:
			var span := maxf(0.000001, after.stamp - before.stamp)
			return (before.at as Vector3).lerp(after.at, clampf((when - before.stamp) / span, 0.0, 1.0))
	var last: Dictionary = _samples.back()
	return last.at + last.velocity * clampf(when - last.stamp, 0.0, 0.1)
