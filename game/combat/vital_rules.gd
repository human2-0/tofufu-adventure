class_name VitalRules
extends RefCounted
## Per-actor stamina and combat recovery clock. Configuration is shared read-only.
const BASE_SP: float = 100.0
const SP_GROWTH: float = 1.02
const HP_GROWTH: float = 1.05
const DASH_COST: float = 15.0
const SUPER_COST: float = 25.0
const SPECIAL_COST: float = 25.0
const SP_REGEN: float = 0.05
const HP_REGEN: float = 0.02
const COMBAT_SECONDS: float = 30.0
var maximum: float = BASE_SP
var current: float = BASE_SP
var combat_remaining: float = 0.0

func set_level(level: int) -> void:
	var next := BASE_SP * pow(SP_GROWTH, clampi(level, 1, 99) - 1)
	if is_equal_approx(next, maximum): return
	current = clampf(current / maximum * next, 0.0, next)
	maximum = next

func spend(amount: float) -> bool:
	if amount < 0.0 or current + 0.00001 < amount: return false
	current = maxf(0.0, current - amount)
	return true

func engage() -> void:
	combat_remaining = COMBAT_SECONDS

func confirmed_hit(normal: bool = true) -> void:
	engage()
	if normal: current = minf(maximum, current + maximum * 0.01)

## Returns the fraction of maximum health recoverable during this tick.
func step(delta: float, alive: bool = true) -> float:
	if not alive: return 0.0
	var recovery_seconds := maxf(0.0, delta - combat_remaining)
	combat_remaining = maxf(0.0, combat_remaining - delta)
	current = minf(maximum, current + maximum * SP_REGEN * delta)
	return recovery_seconds * HP_REGEN

func reset() -> void:
	current = maximum
	combat_remaining = 0.0

func capture() -> Dictionary:
	return {"stamina": current, "combat_remaining": combat_remaining}

func restore(data: Dictionary) -> void:
	current = clampf(float(data.get("stamina", maximum)), 0.0, maximum)
	combat_remaining = clampf(float(data.get("combat_remaining", 0.0)), 0.0, COMBAT_SECONDS)
