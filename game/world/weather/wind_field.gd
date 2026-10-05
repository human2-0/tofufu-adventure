class_name WindField
extends RefCounted
## Deterministic weather rule shared by local and co-op movement/presentation.

var direction: Vector2 = Vector2.RIGHT
var strength: float = 0.0

func step(phase: float, windy: bool, delta: float) -> void:
	var progress := clampf((phase - 0.08) / 0.14, 0.0, 1.0)
	var target_angle := lerpf(-0.55, 2.45, progress) + sin(progress * TAU) * 0.32
	var target_direction := Vector2.from_angle(target_angle)
	var turn := 1.0 - exp(-delta * 2.0)
	direction = Vector2.from_angle(lerp_angle(direction.angle(), target_direction.angle(), turn))
	var target_strength := 0.78 + sin(progress * PI) * 0.14 if windy else 0.0
	strength = move_toward(strength, target_strength, delta * 0.34)

func movement_multiplier(motion: Vector2) -> float:
	if strength <= 0.0 or motion.is_zero_approx(): return 1.0
	var headwind := maxf(0.0, -motion.normalized().dot(direction))
	return 1.0 - headwind * strength * 0.42
