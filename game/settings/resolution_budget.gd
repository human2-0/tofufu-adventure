class_name ResolutionBudget
extends RefCounted
## Bounded pixel-cost response; loading spikes never reduce simulation fidelity.

var scale: float = 1.0
var maximum: float = 1.0
var minimum: float = 0.85
var target: float = 1.0 / 120.0
var _samples: Array[float] = []
var _elapsed: float = 0.0
var _safe_time: float = 0.0
var _warmup: float = 3.0

func reset(cap: int, ceiling: float) -> void:
	maximum = ceiling
	minimum = minf(0.85, ceiling)
	scale = ceiling
	target = 1.0 / maxi(1, cap)
	_samples.clear()
	_elapsed = 0.0
	_safe_time = 0.0
	_warmup = 3.0

func sample(seconds: float) -> float:
	if not is_finite(seconds) or seconds <= 0.0 or seconds > 0.1: return scale
	if _warmup > 0.0:
		_warmup -= seconds
		return scale
	_samples.append(seconds)
	_elapsed += seconds
	if _elapsed < 2.0 and _samples.size() < 480: return scale
	_samples.sort()
	var slow := _samples[mini(_samples.size() - 1, floori(_samples.size() * 0.9))]
	if slow > target * 1.12:
		scale = maxf(minimum, snappedf(scale - 0.05, 0.05))
		_safe_time = 0.0
	elif slow < target * 1.04:
		_safe_time += _elapsed
		if _safe_time >= 15.0:
			scale = minf(maximum, snappedf(scale + 0.05, 0.05))
			_safe_time = 0.0
	else:
		_safe_time = 0.0
	_samples.clear()
	_elapsed = 0.0
	return scale
