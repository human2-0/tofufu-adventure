class_name RunEndurance
extends RefCounted
## Separate per-actor running reserve. Walking, attacks and healing do not spend it.

const MAXIMUM: float = 100.0
const DRAIN: float = 18.0
const RECOVERY: float = 16.0
const REST_DELAY: float = 1.2
const RESUME: float = 30.0
var current: float = MAXIMUM
var rest_remaining: float = 0.0
var exhausted: bool = false
var running: bool = false

func step(requested: bool, moving: bool, permitted: bool, delta: float) -> void:
	if exhausted and not requested and current >= RESUME: exhausted = false
	running = requested and moving and permitted and not exhausted and current > 0.0
	if running:
		current = maxf(0.0, current - DRAIN * delta)
		rest_remaining = REST_DELAY
		if current <= 0.0:
			exhausted = true
			running = false
	else:
		var recovering := maxf(0.0, delta - rest_remaining)
		rest_remaining = maxf(0.0, rest_remaining - delta)
		current = minf(MAXIMUM, current + RECOVERY * recovering)

func reset() -> void:
	current = MAXIMUM
	rest_remaining = 0.0
	exhausted = false
	running = false

func capture() -> Dictionary:
	return {"current": current, "rest": rest_remaining, "exhausted": exhausted}

func restore(data: Dictionary) -> void:
	current = clampf(float(data.get("current", MAXIMUM)), 0.0, MAXIMUM)
	rest_remaining = clampf(float(data.get("rest", 0.0)), 0.0, REST_DELAY)
	exhausted = bool(data.get("exhausted", false)) or current <= 0.0
	running = false
