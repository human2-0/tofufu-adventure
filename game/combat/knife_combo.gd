class_name KnifeCombo
extends RefCounted
## Per-attacker timing streak. A confirmed knife hit keeps the next input window open.

var count: int = 0
var window_remaining: float = 0.0
var _hit_this_attack: bool = false
var _tuning: CombatTuning

func _init(tuning: CombatTuning) -> void:
	_tuning = tuning

func step(delta: float) -> bool:
	if count <= 0:
		return false
	window_remaining = maxf(0.0, window_remaining - delta)
	if window_remaining > 0.0:
		return false
	count = 0
	return true

func can_stab() -> bool:
	return count > 0 and window_remaining > 0.0

func critical_chance() -> float:
	return minf(_tuning.combo_critical_chance_cap, count * _tuning.combo_critical_chance_per_hit)

func begin_attack() -> void:
	_hit_this_attack = false

func confirm_hit() -> bool:
	if _hit_this_attack:
		return false
	_hit_this_attack = true
	count = mini(_tuning.combo_max_count, count + 1)
	window_remaining = _tuning.combo_window_seconds
	return true

func finish_attack() -> bool:
	if _hit_this_attack:
		return false
	var changed := count > 0
	count = 0
	window_remaining = 0.0
	return changed

func reset() -> void:
	count = 0
	window_remaining = 0.0
	_hit_this_attack = false

func restore(saved_count: int, saved_window: float) -> void:
	count = clampi(saved_count, 0, _tuning.combo_max_count)
	window_remaining = clampf(saved_window, 0.0, _tuning.combo_window_seconds)
	_hit_this_attack = false
