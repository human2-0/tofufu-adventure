class_name AngelBow
extends Node3D
## Single-arrow authority; charging cannot fire during a reload or on replicas.

const RELOAD: float = 2.0
const CHARGE: float = 1.25
const COOLDOWN: float = 6.0
const COST: float = 25.0
const SPEED: float = 96.0
const DAMAGE_SCALE: float = 2.5
var combat: PlayerCombat
var selected: bool = false
var reload_remaining: float = 0.0
var charge: float = 0.0
var cooldown: float = 0.0
var sequence: int = 0
var origin := Vector3.ZERO
var velocity := Vector3.ZERO
var empowered: bool = false
var burst_sequence: int = 0
var burst_at := Vector3.ZERO
var visual: AngelBowView
var _spent_hold: bool = false
var _replica_sequence: int = -1
var _replica_burst: int = -1

func _ready() -> void:
	visual = AngelBowView.new()
	visual.bow = self
	add_child(visual)

func step(primary: bool, secondary: bool, aim: Vector2, point: Vector3, delta: float) -> void:
	reload_remaining = maxf(0.0, reload_remaining - delta)
	cooldown = maxf(0.0, cooldown - delta)
	visual.facing = aim
	visual.visible = selected
	if not secondary: _spent_hold = false
	if not selected or combat.replica_view or reload_remaining > 0.0:
		charge = 0.0
		return
	if secondary:
		if _spent_hold or cooldown > 0.0 or combat.vitals.current < COST:
			charge = 0.0
			return
		charge = minf(CHARGE, charge + delta)
		if charge < CHARGE - 0.00001: return
		_spent_hold = true
		if combat.vitals.spend(COST):
			cooldown = COOLDOWN
			fire(aim, point, true)
		charge = 0.0
		return
	charge = 0.0
	if primary: fire(aim, point, false)

func fire(aim: Vector2, point: Vector3, special: bool) -> void:
	if not selected or combat.replica_view or reload_remaining > 0.0: return
	origin = combat.gun.muzzle_position(aim)
	var direction := (point - origin).normalized()
	if direction.is_zero_approx(): direction = Vector3(aim.x, 0, aim.y)
	velocity = direction * SPEED
	empowered = special
	sequence += 1
	reload_remaining = RELOAD
	combat.vitals.engage()
	_spawn(true)

func _spawn(authority: bool) -> void:
	var arrow := AngelArrow.new()
	arrow.bow = self
	arrow.authoritative = authority
	arrow.velocity = velocity
	arrow.empowered = empowered
	arrow.body_damage = combat.tuning.bean_damage * DAMAGE_SCALE * combat.gun.damage_multiplier * combat.gun.enhancement_multiplier
	arrow.head_damage = combat.tuning.bean_head_damage * DAMAGE_SCALE * combat.gun.damage_multiplier * combat.gun.enhancement_multiplier
	arrow.targets.assign(combat.targets)
	arrow.targets.append_array(combat.gun.friends)
	arrow.ignored.assign(combat.gun.ignored_bodies)
	add_child(arrow)
	arrow.global_position = origin
	arrow.initial_start = combat.actor.global_position + Vector3.UP * combat.tuning.muzzle_height
	visual.kick = 1.0

func impact(at: Vector3) -> void:
	burst_at = at
	burst_sequence += 1
	AngelFlameSphere.spawn(self, at)

func present_shot(value: int, at: Vector3, flight: Vector3, special: bool) -> void:
	if _replica_sequence >= 0 and value > _replica_sequence:
		origin = at
		velocity = flight
		empowered = special
		_spawn(false)
	_replica_sequence = value
	sequence = value

func present_burst(value: int, at: Vector3) -> void:
	if _replica_burst >= 0 and value > _replica_burst: AngelFlameSphere.spawn(self, at)
	_replica_burst = value
	burst_sequence = value
	burst_at = at

func cancel() -> void:
	charge = 0.0
	_spent_hold = false

func clear_flights() -> void:
	for child in get_children():
		if child is AngelArrow:
			child.set_physics_process(false)
			child.queue_free()
