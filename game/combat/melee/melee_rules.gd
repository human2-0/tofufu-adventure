class_name MeleeRules
extends RefCounted
## Charge and cooldown are per attacker. A release produces one strike.

var charge: float = 0.0
var cooldown: float = 0.0
var _held: bool = false
var _queued: float = -1.0
var _buffer_remaining: float = 0.0
var released: bool = false
var _tuning: CombatTuning

func _init(tuning: CombatTuning) -> void:
	_tuning = tuning

func step(held: bool, delta: float, attack_speed: float = 1.0, committed: bool = false) -> float:
	cooldown = maxf(0.0, cooldown - delta * attack_speed)
	_buffer_remaining = maxf(0.0, _buffer_remaining - delta)
	if _buffer_remaining <= 0.0: _queued = -1.0
	var strength := -1.0
	released = _held and not held
	if held and (cooldown <= 0.0 or committed):
		charge = minf(1.0, charge + delta / _tuning.charge_seconds)
	elif released and (cooldown <= 0.0 or committed):
		_queued = charge
		_buffer_remaining = _tuning.input_buffer_seconds
	if not committed and cooldown <= 0.0 and _queued >= 0.0:
		strength = _queued
		_queued = -1.0
		cooldown = _tuning.attack_cooldown + (0.2 if strength >= 1.0 else 0.0)
	if not held:
		charge = 0.0
	_held = held
	return strength

func buffered() -> bool:
	return _queued >= 0.0

func cancel_charge() -> void:
	charge = 0.0
	_held = false
	_queued = -1.0
	_buffer_remaining = 0.0
