class_name TrainingMob
extends CharacterBody3D
## Small roaming snail: wander, chase, telegraph, strike, recover.

signal attacked(amount: float, source: Vector3)
signal defeated(at: Vector3)
@export var quarry: Node3D
@export var protected_area: Rect2
@export var leash_radius: float = 8.0
@export var tuning: SnailTuning = preload("res://game/combat/default_snail.tres")
var rain_only: bool = false
var available: bool = true
var raining: bool = false
var _returning: bool = false
var target: Damageable
var _sprite: SnailVisuals
var _warning: Label3D
var _home: Vector3
var _destination: Vector3
var _timer: float = 0.0
var _rest: float = 0.0
var _respawn: float = 0.0
var _windup: float = 0.0
var _knockback: Vector3 = Vector3.ZERO
var _rng := RandomNumberGenerator.new()
var _collider: CollisionShape3D
var spawn_clearance: Callable

func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
	platform_floor_layers = 1
	_home = position
	_destination = _home
	_rng.seed = hash(position)
	var collider := CollisionShape3D.new()
	_collider = collider
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.0
	collider.shape = capsule
	collider.position.y = 0.5
	add_child(collider)
	_sprite = SnailVisuals.new()
	add_child(_sprite)
	_warning = Label3D.new()
	_warning.text = "!"
	_warning.font_size = 72
	_warning.pixel_size = 0.012
	_warning.modulate = Color("ffca78")
	_warning.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_warning.position.y = 1.8
	_warning.visible = false
	add_child(_warning)
	target = Damageable.new()
	target.maximum = tuning.dry_health
	target.headshot_height = 0.72
	target.position.y = 0.6
	target.body = self
	add_child(target)
	target.hit.connect(_hit)
	target.depleted.connect(_die)

func _physics_process(delta: float) -> void:
	if not available: return
	if _respawn > 0.0:
		_respawn -= delta * (tuning.dry_respawn / tuning.rain_respawn if raining else 1.0)
		if _respawn <= 0.0:
			if not _home_is_clear():
				_respawn = 0.2
				return
			position = _home
			visible = true
			collision_layer = 2
			target.restore()
		return
	_rest = maxf(0.0, _rest - delta)
	var direction := _choose_direction(delta)
	velocity.x = direction.x + _knockback.x
	velocity.z = direction.z + _knockback.z
	velocity.y -= 25.0 * delta
	_knockback = _knockback.move_toward(Vector3.ZERO, 25.0 * delta)
	var previous_position := position
	move_and_slide()
	if _protected(global_position):
		position = previous_position
		_knockback = Vector3.ZERO
		_returning = true
	if position.y < -4.0:
		visible = false
		collision_layer = 0
		_respawn = 0.2
		velocity = Vector3.ZERO

func _home_is_clear() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _collider.shape
	query.collision_mask = 3
	query.exclude = [get_rid()]
	var spawn_transform := transform
	spawn_transform.origin = _home
	query.transform = get_parent_node_3d().global_transform * spawn_transform * _collider.transform
	if spawn_clearance.is_valid() and not spawn_clearance.call(query.shape, query.transform): return false
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func _process(delta: float) -> void:
	if not visible: return
	var aim := quarry.global_position - global_position if is_instance_valid(quarry) else Vector3.ZERO
	# Replicas retain their last travel facing; their quarry is not authoritative.
	if not is_physics_processing(): aim = Vector3.ZERO
	_sprite.present(velocity, aim, _windup, delta)

func _choose_direction(delta: float) -> Vector3:
	if not is_instance_valid(quarry):
		return Vector3.ZERO
	var home_offset := _home - position
	home_offset.y = 0.0
	if home_offset.length() > leash_radius or _protected(quarry.global_position):
		_returning = true
	if _returning:
		_windup = 0.0
		_warning.visible = false
		if home_offset.length() < 0.4:
			_returning = false
			return Vector3.ZERO
		return home_offset.normalized() * 3.5
	var offset := quarry.global_position - global_position
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_warning.visible = false
			if offset.length() < 2.0 and _can_reach_quarry():
				attacked.emit(tuning.rain_damage if raining else tuning.dry_damage, global_position)
			_rest = 1.3
		return Vector3.ZERO
	if _rest > 0.0:
		return Vector3.ZERO
	if offset.length() < 1.6:
		_windup = 0.65
		_warning.visible = true
		return Vector3.ZERO
	if offset.length() < 7.0:
		offset.y = 0.0
		return offset.normalized() * 2.5
	_timer -= delta
	if _timer <= 0.0:
		_destination = _home + Vector3(_rng.randf_range(-2.5, 2.5), 0, _rng.randf_range(-2.5, 2.5))
		_timer = _rng.randf_range(2.0, 4.0)
	var wander := _destination - position
	wander.y = 0.0
	return wander.normalized() * 1.2 if wander.length() > 0.3 else Vector3.ZERO

func _protected(at: Vector3) -> bool:
	return protected_area.has_area() and protected_area.has_point(Vector2(at.x, at.z))

func _can_reach_quarry() -> bool:
	if _protected(global_position) or _protected(quarry.global_position):
		return false
	var origin := global_position + Vector3.UP * 0.6
	var destination := quarry.global_position + Vector3.UP * 0.6
	var query := PhysicsRayQueryParameters3D.create(origin, destination, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _hit(_amount: float, direction: Vector3) -> void:
	_knockback = direction
	_sprite.modulate = Color(3, 1.0, 0.8)
	_windup = 0.0
	_warning.visible = false
	_rest = 0.3

func _die() -> void:
	_windup = 0.0
	_warning.visible = false
	_rest = 0.0
	_returning = false
	defeated.emit(global_position)
	visible = false
	collision_layer = 0
	_respawn = tuning.dry_respawn
	velocity = Vector3.ZERO
	_knockback = Vector3.ZERO

func set_rain(wet: bool) -> void:
	if raining != wet:
		var fraction := target.current / target.maximum
		raining = wet
		target.maximum = tuning.rain_health if wet else tuning.dry_health
		target.current = target.maximum * fraction
	if rain_only and available != wet:
		available = wet
		visible = false
		collision_layer = 0
		target.current = 0.0
		_respawn = tuning.dry_respawn
		_windup = 0.0
		_rest = 0.0
		_warning.visible = false
		velocity = Vector3.ZERO
		_knockback = Vector3.ZERO
