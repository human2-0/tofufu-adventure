class_name ArmoredSnail
extends TrainingMob
## Directional shell protection and a telegraphed, committed headbutt rush.

const LEVEL: int = 2
const SHELL_MAX_HEALTH: float = 65.0
@export var armored_tuning: ArmoredSnailTuning = preload("res://game/combat/enemies/default_armored_snail.tres")
var _armored_visual: ArmoredSnailVisuals
var shell_health: float = SHELL_MAX_HEALTH
var _shell_collider: CollisionShape3D
var facing := Vector3.BACK
var _defend: float = 0.0
var _defend_cooldown: float = 0.0
var _rush: float = 0.0
var _rush_cooldown: float = 0.0
var _rush_aim := Vector3.ZERO
var _charging: bool = false
var _rush_hit: bool = false

func _ready() -> void:
	tuning = armored_tuning
	super()
	target.damage_filter = _filter_damage
	target.restored.connect(_restore_shell)
	_shell_collider = _add_hit_shape(0.62, 0.87, Vector3(0, 0.72, -0.1))
	_add_hit_shape(0.68, 0.44, Vector3(0, 0.22, 0))

func _physics_process(delta: float) -> void:
	_defend_cooldown = maxf(0.0, _defend_cooldown - delta)
	_rush_cooldown = maxf(0.0, _rush_cooldown - delta)
	if _protected(global_position):
		position = _outside_protected_position(global_position)
		_returning = true
	var shell_at := Vector3.UP * 0.72 - facing * 0.1
	if not _shell_collider.position.is_equal_approx(shell_at): _shell_collider.position = shell_at
	super(delta)

func _create_visual() -> void:
	_armored_visual = ArmoredSnailVisuals.new()
	add_child(_armored_visual)

func _present_visual(_aim: Vector3, delta: float) -> void:
	_armored_visual.present(velocity, facing, _windup, 0.0, delta)
	_armored_visual.rotation.y = atan2(facing.x, facing.z)

func _flash_visual() -> void:
	_armored_visual.flash()

func _nameplate_text() -> String:
	return "ARMORED SNAIL · LV %d\n%s" % [LEVEL, "SHELL %d / %d" % [ceili(shell_health), int(SHELL_MAX_HEALTH)] if shell_health > 0 else "SHELL BROKEN"]

func _nameplate_height() -> float:
	return 1.75

func _filter_damage(amount: float, direction: Vector3, _kind: Damageable.HitKind) -> float:
	var incoming := Vector3(direction.x, 0, direction.z).normalized()
	var shell_impact := incoming == Vector3.ZERO or incoming.dot(facing) > -0.65 or direction.normalized().y < -0.65
	if target.impact_point.is_finite():
		var relative := target.impact_point - global_position
		# The broad foot below the lip and the forward head are independently vulnerable.
		shell_impact = relative.y > 0.36 and Vector3(relative.x, 0, relative.z).dot(facing) < 0.32
	if shell_health > 0.0 and shell_impact:
		target.hit_absorbed = true
		var point := target.impact_point if target.impact_point.is_finite() else global_position + Vector3.UP * 0.8 - incoming * 0.45
		set_shell_health(maxf(0.0, shell_health - amount), true, point)
		return 0.0
	if shell_health > 0.0 and _defend_cooldown <= 0.0:
		facing = incoming
		_defend = armored_tuning.defend_duration
		_defend_cooldown = armored_tuning.defend_cooldown
		_cancel_rush()
	return amount

func _choose_direction(delta: float) -> Vector3:
	if not is_instance_valid(quarry):
		_cancel_rush()
		return Vector3.ZERO
	if _returning or _protected(quarry.global_position) or (not free_roaming and position.distance_to(_home) > leash_radius):
		_cancel_rush()
		_defend = 0.0
		return _face_motion(super(delta))
	if quarry.global_position.distance_to(global_position) < 7.0 or _charging or _rush > 0.0: targeting.emit(quarry)
	if _defend > 0.0:
		_defend = maxf(0.0, _defend - delta)
		return -facing * armored_tuning.reverse_speed
	if _charging:
		_windup = maxf(0.0, _windup - delta)
		if _windup <= 0.0:
			_charging = false
			_warning.visible = false
			_rush = armored_tuning.rush_duration
		return Vector3.ZERO
	if _rush > 0.0:
		_rush -= delta
		var offset := quarry.global_position - global_position
		if not _rush_hit and offset.length() < 1.5 and offset.normalized().dot(_rush_aim) > 0.2 and _can_reach_quarry():
			_rush_hit = true
			attacked.emit((tuning.rain_damage if raining else tuning.dry_damage) * armored_tuning.rush_damage_multiplier, global_position)
		if _rush <= 0.0 or is_on_wall():
			_rush = 0.0
			_rest = 1.3
			return Vector3.ZERO
		return _rush_aim * armored_tuning.rush_speed
	var offset := quarry.global_position - global_position
	if _rest <= 0.0 and _windup <= 0.0 and _rush_cooldown <= 0.0 and offset.length() > 2.0 and offset.length() < 6.5 and _can_reach_quarry():
		_rush_aim = Vector3(offset.x, 0, offset.z).normalized()
		facing = _rush_aim
		_charging = true
		_rush_hit = false
		_windup = armored_tuning.rush_windup
		_rush_cooldown = armored_tuning.rush_cooldown
		_warning.visible = true
		return Vector3.ZERO
	return _face_motion(super(delta))

func _face_motion(motion: Vector3) -> Vector3:
	if motion.length_squared() > 0.01: facing = motion.normalized()
	elif _windup > 0.0 and is_instance_valid(quarry):
		var offset := quarry.global_position - global_position
		facing = Vector3(offset.x, 0, offset.z).normalized()
	return motion

func _cancel_rush() -> void:
	_rush = 0.0
	_charging = false
	_windup = 0.0
	_warning.visible = false

func _die() -> void:
	_cancel_rush()
	_defend = 0.0
	_defend_cooldown = 0.0
	_rush_cooldown = 0.0
	super()

func _add_hit_shape(radius: float, height: float, at: Vector3) -> CollisionShape3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 4
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_convex_shape()
	shape.position = at
	add_child(shape)
	return shape

func set_shell_health(value: float, feedback: bool = false, point: Vector3 = Vector3.INF) -> void:
	var previous := shell_health
	shell_health = clampf(value, 0.0, SHELL_MAX_HEALTH)
	_armored_visual.set_shell_health(shell_health)
	_nameplate.text = _nameplate_text()
	_shell_collider.set_deferred("disabled", shell_health <= 0.0)
	if shell_health <= 0.0: _defend = 0.0
	if feedback and shell_health < previous:
		var at := point if point.is_finite() else global_position + Vector3.UP * 0.8
		SnailShellEffects.impact(get_parent(), at, shell_health <= 0.0)

func _restore_shell() -> void:
	set_shell_health(SHELL_MAX_HEALTH)

func _outside_protected_position(at: Vector3) -> Vector3:
	var bounds := protected_area
	var point := Vector2(at.x, at.z)
	var distances := [point.x - bounds.position.x, bounds.end.x - point.x, point.y - bounds.position.y, bounds.end.y - point.y]
	var nearest := 0
	for index in range(1, distances.size()):
		if distances[index] < distances[nearest]: nearest = index
	var margin := 0.08
	match nearest:
		0: point.x = bounds.position.x - margin
		1: point.x = bounds.end.x + margin
		2: point.y = bounds.position.y - margin
		_: point.y = bounds.end.y + margin
	return Vector3(point.x, at.y, point.y)
