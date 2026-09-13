class_name PodEscapeRules
extends RefCounted
## Retryable, per-instance quest rules. No input, scene or presentation access.

enum Stage { ROCK, SNAP, FALL, SPLIT, REVEAL, COMPLETE }
const CHARGE_MIN: float = 0.55
const CHARGE_MAX: float = 0.82
var stage: Stage = Stage.ROCK
var elapsed: float = 0.0
var beat: float = 0.0
var pushes: int = 0
var direction: int = 1
var charge: float = 0.0
var feedback: String = "A little nudge can change everything."
var _last_direction: int = 0
var _held: bool = false

func step(delta: float, horizontal: float, jump_held: bool) -> void:
	elapsed += delta
	beat = fposmod(beat + delta / 1.6, 1.0)
	var edge := int(signf(horizontal)) if absf(horizontal) > 0.5 else 0
	if stage == Stage.ROCK and edge != 0 and edge != _last_direction:
		if edge == direction and rock_window():
			pushes += 1
			direction *= -1
			feedback = "Good push! The stem is loosening."
			if pushes == 4:
				_transition(Stage.SNAP)
				feedback = "One precise leap will snap the stem."
		else:
			feedback = "Wait for the gold zone, then tap the shown direction."
	elif stage == Stage.SNAP or stage == Stage.SPLIT:
		if jump_held:
			charge += delta
		elif _held:
			if charge >= CHARGE_MIN and charge <= CHARGE_MAX:
				_transition(Stage.FALL if stage == Stage.SNAP else Stage.REVEAL)
				feedback = "Here we go!" if stage == Stage.FALL else "Hello, big world."
			else:
				feedback = "Too soon — try again." if charge < CHARGE_MIN else "Too late — try a shorter hold."
			charge = 0.0
	elif stage == Stage.FALL and elapsed >= 0.9:
		_transition(Stage.SPLIT)
		feedback = "Landed! Push against the seam to open your pod."
	elif stage == Stage.REVEAL and elapsed >= 3.0:
		_transition(Stage.COMPLETE)
	_last_direction = edge
	_held = jump_held

func rock_window() -> bool:
	return cue_value() >= 0.38 and cue_value() <= 0.62

func cue_value() -> float:
	return fposmod(beat + (0.25 if direction > 0 else -0.25), 1.0)

func _transition(next: Stage) -> void:
	stage = next
	elapsed = 0.0
	charge = 0.0
