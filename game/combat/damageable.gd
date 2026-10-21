class_name Damageable
extends Node3D
## Explicit hit/health contract. Attach to a body or a destructible prop. Helpers use the annotated signals/state.

signal changed(current: float, maximum: float)
signal hit(amount: float, direction: Vector3)
@warning_ignore("unused_signal") signal reflected_hit(weapon: String)
@warning_ignore("unused_signal") signal pushed(impulse: Vector3)
signal engaged
@warning_ignore("unused_signal") signal attack_confirmed(normal: bool)
var guard_payment: Callable
signal restored
signal depleted

enum HitKind { MELEE, SLIME, SOY, KNIFE }
var last_hit_amount: float = 0.0
var last_hit_kind: HitKind = HitKind.MELEE
var hit_counts: Array[int] = [0, 0, 0, 0]
var impact_point := Vector3.INF
var hit_absorbed: bool = false
var damage_filter: Callable
## Optional match authority routes attributed attacks; adventure keeps normal damage.
var attack_receiver: Callable
@export var launch_immune: bool = false
@export_range(0.0, 1.0) var knockback_multiplier: float = 1.0
var projectile_guard: Callable
var armor_multiplier: float = 1.0

var trains_weapons: bool = false
var paralysis_allowed: bool = false
var paralysis: float = 0:
	set(value):
		paralysis = clampf(value, 0, 4)
		if not is_inside_tree(): return
		if paralysis > 0:
			BengalRiftVFX.paralysis(self)
		elif has_node("ParalysisSeal"):
			get_node("ParalysisSeal").queue_free()

@export var maximum: float = 60.0
@export var body: CollisionObject3D
var current: float = 60.0
var invulnerability: float = 0.0

func _ready() -> void:
	current = maximum

func _physics_process(delta: float) -> void:
	invulnerability = maxf(0.0, invulnerability - delta)
	paralysis = maxf(0, paralysis - delta) if current > 0 else 0.0

func paralyze(seconds: float) -> void:
	if paralysis_allowed and current > 0:
		paralysis = maxf(paralysis, clampf(seconds, 0, 4))

func damage(amount: float, direction: Vector3 = Vector3.ZERO, kind: HitKind = HitKind.MELEE, point: Vector3 = Vector3.INF) -> bool:
	hit_absorbed = false
	if current <= 0.0 or invulnerability > 0.0 or amount <= 0.0:
		return false
	engaged.emit()
	impact_point = point
	if damage_filter.is_valid(): amount = damage_filter.call(amount, direction, kind)
	amount *= clampf(armor_multiplier, 0.0, 1.0)
	if amount <= 0.0: return false
	last_hit_amount = minf(current, amount)
	last_hit_kind = kind
	hit_counts[kind] += 1
	current = maxf(0.0, current - amount)
	changed.emit(current, maximum)
	direction *= knockback_multiplier
	if launch_immune: direction.y = minf(0.0, direction.y)
	hit.emit(amount, direction)
	if current <= 0.0:
		depleted.emit()
	return true

func receive_attack(amount: float, direction: Vector3, kind: HitKind, point: Vector3, attacker: Damageable) -> bool:
	if attack_receiver.is_valid(): return attack_receiver.call(amount, direction, kind, point, attacker)
	return damage(amount, direction, kind, point)

func heal(amount: float) -> void:
	if current > 0.0:
		current = minf(maximum, current + maxf(0.0, amount))
		changed.emit(current, maximum)

func restore() -> void:
	paralysis = 0
	current = maximum
	restored.emit()
	invulnerability = 2.0
	changed.emit(current, maximum)

## Local-space upper hit region, configured only on creatures and practice targets.
var headshot_height: float = INF

func is_headshot(point: Vector3) -> bool:
	return body != null and body.to_local(point).y >= headshot_height

func reflection_normal(incoming: Vector3, point: Vector3, confirmed: bool, amount: float = 0.0) -> Vector3:
	if current <= 0 or not projectile_guard.is_valid(): return Vector3.ZERO
	var normal: Vector3 = projectile_guard.call(incoming, point, false)
	if normal.is_zero_approx(): return normal
	if confirmed:
		engaged.emit()
		if guard_payment.is_valid() and not guard_payment.call(amount): return Vector3.ZERO
	return projectile_guard.call(incoming, point, confirmed)
