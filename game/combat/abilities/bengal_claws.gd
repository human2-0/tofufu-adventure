class_name BengalClaws
extends RefCounted
## Authority owns charging, collision-resolved dash hits and the separate finisher.

const DAMAGE: float = 16.0
const CADENCE: float = 0.33
const REACH: float = 1.65
const RIFT_REACH: float = 2.6
const COOLDOWN: float = 8.0
const PARALYSIS: float = 4.0
const CHARGE_SECONDS: float = 2.0
const COST: float = 20.0
const DASH_SPEED: float = 20.0
const DASH_SECONDS: float = 0.36
const WALK_BONUS: float = 1.15
const DASH_COOLDOWN: float = 0.75
const DASH_COST: float = 0.75
var selected: bool = false
var cooldown: float = 0.0
var sequence: int = 0
var launch_sequence: int = 0
var origin := Vector3.ZERO
var aim := Vector2.DOWN
var charge: float = 0.0
var charging: bool = false
var dashing: bool = false
var remaining: float = 0.0
var target_point := Vector3.INF
var _previous := Vector3.ZERO
var _was_held: bool = false
var hits := BengalClawHits.new()

func busy() -> bool:
	return charging or dashing

func step(combat: PlayerCombat, direction: Vector2, held: bool, delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	var pressed := held and not _was_held
	_was_held = held
	if combat.replica_view: return
	if not selected:
		cancel()
		return
	if dashing:
		_advance(combat, delta)
		return
	if pressed: fire(combat, direction)
	if not charging: return
	if not held:
		cancel()
		return
	aim = SwordGeometry.direction(direction)
	combat.attack_aim = aim
	charge = minf(CHARGE_SECONDS, charge + delta)
	combat.charge_changed.emit(charge / CHARGE_SECONDS)
	if charge >= CHARGE_SECONDS - 0.000001: _launch(combat)

func fire(combat: PlayerCombat, direction: Vector2) -> void:
	if not selected or busy() or combat.replica_view or cooldown > 0.0 or combat.active or combat.equipment._punch_time > 0.0: return
	if combat.vitals.current < COST: return
	charging = true
	charge = 0.0
	aim = SwordGeometry.direction(direction)
	combat.rules.cancel_charge()
	BengalRiftVFX.charge(combat)

func _launch(combat: PlayerCombat) -> void:
	if not combat.vitals.spend(COST):
		cancel()
		return
	charging = false
	dashing = true
	charge = 0.0
	cooldown = COOLDOWN
	launch_sequence += 1
	hits.reset()
	_previous = combat.actor.global_position
	remaining = hits.dash_distance(combat, target_point) / DASH_SPEED
	combat.attack_aim = aim
	combat.equipment.facing = aim

func velocity(current: Vector3, _grounded: bool, delta: float) -> Vector3:
	if not dashing: return current
	var seconds := minf(delta, remaining)
	remaining = maxf(0.0, remaining - delta)
	var forward := Vector3(aim.x, 0.0, aim.y)
	return forward * DASH_SPEED * seconds / maxf(delta, 0.000001) + Vector3.UP * minf(current.y, 0.0)

func _advance(combat: PlayerCombat, delta: float) -> void:
	var at := combat.actor.global_position
	var travel := at - _previous
	if travel.length() > DASH_SPEED * delta + 1.0:
		cancel()
		return
	hits.sweep(combat, _previous, at)
	if not dashing: return
	_previous = at
	var blocked := travel.dot(Vector3(aim.x, 0, aim.y)) < DASH_SPEED * delta * 0.4
	if remaining > 0.000001 and not blocked: return
	dashing = false
	remaining = 0.0
	origin = at
	sequence += 1
	combat.equipment._punch_time = 0.5
	hits.strike(combat, true)
	if combat.actor is CharacterBody3D:
		combat.actor.velocity.x = 0.0
		combat.actor.velocity.z = 0.0

func cancel() -> void:
	charging = false
	dashing = false
	charge = 0.0
	remaining = 0.0

func damage(combat: PlayerCombat) -> float:
	return DAMAGE * combat.fist_damage_multiplier * (1.2 if combat.equipment.weapon_enhanced else 1.0)

func strike(combat: PlayerCombat, super_claw: bool = false) -> void:
	if busy(): return
	hits.reset()
	hits.strike(combat, super_claw)
