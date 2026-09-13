class_name MeleeRules
extends RefCounted
## Charge and cooldown are per attacker. A release produces one strike.

var charge: float = 0.0
var cooldown: float = 0.0
var _held: bool = false
var _tuning: CombatTuning

func _init(tuning: CombatTuning) -> void:
	_tuning = tuning

func step(held: bool, delta: float, attack_speed: float = 1.0) -> float:
	cooldown = maxf(0.0, cooldown - delta * attack_speed)
	var strength := -1.0
	if held and cooldown <= 0.0:
		charge = minf(1.0, charge + delta / _tuning.charge_seconds)
	elif _held and not held and cooldown <= 0.0:
		strength = charge
		cooldown = _tuning.attack_cooldown + (0.2 if charge >= 1.0 else 0.0)
	if not held:
		charge = 0.0
	_held = held
	return strength

func cancel_charge() -> void:
	charge = 0.0
	_held = false
