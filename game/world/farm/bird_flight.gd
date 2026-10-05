class_name BirdFlight
extends RefCounted
## Per-bird cosmetic flight; terrain and threats arrive through the flock.

var at: Vector3
var origin: Vector3
var destination: Vector3
var elapsed: float = 0.0
var duration: float = 1.0
var height: float = 3.0
var resting: float = 0.0
var airborne: bool = false

func launch(to: Vector3, seconds: float, lift: float) -> void:
	origin = at
	destination = to
	elapsed = 0.0
	duration = maxf(seconds, 0.1)
	height = lift
	airborne = true

func step(delta: float) -> void:
	if not airborne:
		resting = maxf(0.0, resting - delta)
		return
	elapsed = minf(duration, elapsed + delta)
	var progress := elapsed / duration
	# Fast takeoff, a rounded arc, and gentle braking before touchdown.
	var travel := 1.0 - pow(1.0 - progress, 2.0)
	at = origin.lerp(destination, travel)
	at.y += sin(progress * PI) * height
	if elapsed >= duration:
		at = destination
		airborne = false
