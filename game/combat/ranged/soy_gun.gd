class_name SoyGun
extends Node
## Per-actor firing cadence; only the authority spawns damaging projectiles.

signal weapon_trained(weapon: String)
signal status_changed(magazine: int, reload_seconds: float, charge_seconds: float, visible: bool)
const MAGAZINE_SIZE: int = 9
const RELOAD_SECONDS: float = 2.0
const RICOCHET_CHARGE_SECONDS: float = 2.0
var damage_multiplier: float = 1.0
var attack_speed_multiplier: float = 1.0
var spread_multiplier: float = 1.0

var visual_muzzle: Callable
var owner_health: Damageable
var actor: CollisionObject3D
var tuning: CombatTuning
var targets: Array[Damageable] = []
var friends: Array[Damageable] = []
var ignored_bodies: Array[CollisionObject3D] = []
var visual: SoyGunVisual
var selected: bool = false
var aiming: bool = false
var cooldown: float = 0.0
var magazine: int = MAGAZINE_SIZE
var reload_remaining: float = 0.0
var charge_elapsed: float = 0.0
var ricochet_sequence: int = 0
var ricochet_origin := Vector3.ZERO
var ricochet_velocity := Vector3.ZERO
var recoil := GunRecoil.new()
var shot_sequence: int = 0
var shot_origin := Vector3.ZERO
var shot_velocity := Vector3.ZERO
var _replica_sequence: int = -1
var _replica_ricochet_sequence: int = -1
var _charged_this_hold: bool = false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	visual = SoyGunVisual.new()
	add_child(visual)

func _process(_delta: float) -> void:
	visual.reload_remaining = reload_remaining

func step(held: bool, precise: bool, aim: Vector2, aim_point: Vector3, delta: float) -> void:
	recoil.step(selected and held, delta, tuning)
	cooldown = maxf(0.0, cooldown - delta * attack_speed_multiplier)
	if reload_remaining > 0.0:
		reload_remaining = maxf(0.0, reload_remaining - delta)
		if reload_remaining == 0.0: magazine = MAGAZINE_SIZE
	aiming = selected and precise
	visual.visible = selected
	visual.facing = aim
	if not selected or not held:
		charge_elapsed = 0.0
		_charged_this_hold = false
		status_changed.emit(magazine, reload_remaining, charge_elapsed, selected)
		return
	charge_elapsed = minf(RICOCHET_CHARGE_SECONDS, charge_elapsed + delta)
	if charge_elapsed >= RICOCHET_CHARGE_SECONDS - 0.001 and not _charged_this_hold:
		charge_elapsed = RICOCHET_CHARGE_SECONDS
		_charged_this_hold = true
		_fire(true, aim, aim_point)
		cooldown = tuning.gun_cooldown
		if magazine > 0:
			magazine -= 1
			if magazine == 0 and reload_remaining == 0.0: reload_remaining = RELOAD_SECONDS
		status_changed.emit(magazine, reload_remaining, charge_elapsed, selected)
		return
	if reload_remaining > 0.0 or cooldown > 0.0 or magazine <= 0:
		status_changed.emit(magazine, reload_remaining, charge_elapsed, selected)
		return
	cooldown = tuning.gun_cooldown
	_fire(false, aim, aim_point)
	magazine -= 1
	if magazine == 0: reload_remaining = RELOAD_SECONDS
	status_changed.emit(magazine, reload_remaining, charge_elapsed, selected)

func _fire(ricochet: bool, aim: Vector2, aim_point: Vector3) -> void:
	shot_origin = muzzle_position(aim)
	var direction := (aim_point - shot_origin).normalized()
	if direction.is_zero_approx(): direction = Vector3(aim.x, 0, aim.y)
	direction = spread(direction, recoil.spread_degrees(aiming, tuning) * spread_multiplier)
	shot_velocity = direction * tuning.bean_speed
	recoil.fired(tuning)
	if ricochet:
		ricochet_sequence += 1
		ricochet_origin = shot_origin
		ricochet_velocity = shot_velocity
		_spawn(true, true)
	else:
		shot_sequence += 1
		_spawn(true)

func spread(direction: Vector3, degrees: float) -> Vector3:
	var right := direction.cross(Vector3.UP).normalized()
	if right.is_zero_approx(): right = Vector3.RIGHT
	var up := right.cross(direction).normalized()
	var radius := tan(deg_to_rad(degrees)) * sqrt(_rng.randf())
	var angle := _rng.randf_range(0, TAU)
	return (direction + right * cos(angle) * radius + up * sin(angle) * radius).normalized()

func _spawn(authority: bool, ricochet: bool = false) -> void:
	var bean := SoyProjectile.new()
	bean.shooter = actor
	bean.owner_health = owner_health
	bean.velocity = shot_velocity
	bean.authoritative = authority
	bean.ricochet = ricochet
	bean.ignored_bodies.assign(ignored_bodies)
	bean.initial_path_start = actor.global_position + Vector3.UP * tuning.muzzle_height
	bean.check_initial_path = authority
	visual.refresh()
	bean.visual_origin = visual.muzzle_position() if visual.visible else shot_origin
	if visual_muzzle.is_valid(): bean.visual_origin = visual_muzzle.call()
	visual.kick = 1.0
	bean.body_damage = tuning.bean_damage * damage_multiplier
	bean.head_damage = tuning.bean_head_damage * damage_multiplier
	bean.weapon_trained.connect(weapon_trained.emit)
	bean.targets.assign(targets)
	bean.targets.append_array(friends)
	add_child(bean)
	bean.global_position = shot_origin
	bean.place_visual(bean.visual_origin)

func present_shot(sequence: int, origin: Vector3, velocity: Vector3) -> void:
	if _replica_sequence >= 0 and sequence > _replica_sequence:
		shot_origin = origin
		shot_velocity = velocity
		_spawn(false)
	_replica_sequence = sequence

func present_ricochet(sequence: int, origin: Vector3, velocity: Vector3) -> void:
	if _replica_ricochet_sequence >= 0 and sequence > _replica_ricochet_sequence:
		shot_origin = origin
		shot_velocity = velocity
		_spawn(false, true)
	_replica_ricochet_sequence = sequence

func muzzle_position(aim: Vector2) -> Vector3:
	var forward := Vector3(aim.x, 0, aim.y).normalized()
	if forward.is_zero_approx(): forward = Vector3.BACK
	return actor.global_position + Vector3.UP * tuning.muzzle_height + forward.cross(Vector3.UP) * tuning.muzzle_side + forward * tuning.muzzle_forward

func reset() -> void:
	cooldown = 0.0
	aiming = false
	charge_elapsed = 0.0
	_charged_this_hold = false
	recoil.reset()
