class_name TrainingMob
extends CharacterBody3D
## Small roaming snail: wander, chase, telegraph, strike, recover.

signal targeting(quarry: Node3D)
signal attacked(amount: float, source: Vector3)
signal defeated(at: Vector3)
@export var quarry: Node3D
@export var protected_area: Rect2
@export var leash_radius: float = 8.0
@export var tuning: SnailTuning = preload("res://game/combat/enemies/default_snail.tres")
var rain_only: bool = false
var free_roaming: bool = false
var available: bool = true
var raining: bool = false
var _returning: bool = false
var target: Damageable
var _sprite: SnailVisuals
var _nameplate: Label3D
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
var _view_visibility := MobVisibility.new()
var _floor_contact := MobRest.new()
var reaction := EnemyHitReaction.new()

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
	_create_visual()
	_warning = MobLabels.make(self, "!", 72, 0.012, Color("ffca78"), _nameplate_height() + 0.55)
	_warning.visible = false
	_create_nameplate()
	target = Damageable.new()
	target.maximum = tuning.dry_health
	target.headshot_height = 0.72
	target.position.y = 0.6
	target.body = self
	add_child(target)
	target.hit.connect(_hit)
	target.depleted.connect(_die)
	_view_visibility.build(self)

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
	if reaction.step(delta): return
	_rest = maxf(0.0, _rest - delta)
	var direction := Vector3.ZERO if reaction.stagger > 0.0 or (not is_on_floor() and velocity.y != 0.0) else _choose_direction(delta)
	if _floor_contact.can_rest(self, direction, _knockback):
		velocity = Vector3.ZERO
		return
	velocity.x = direction.x + _knockback.x
	velocity.z = direction.z + _knockback.z
	velocity.y -= 25.0 * delta
	_knockback = _knockback.move_toward(Vector3.ZERO, 25.0 * delta)
	var previous_position := position
	move_and_slide()
	_floor_contact.remember(self)
	if _protected(global_position):
		# Loaded actors inside an expanded village may retreat; outsiders cannot enter.
		if not _protected(previous_position): position = previous_position
		_knockback = Vector3.ZERO
		_returning = true
	if position.y < -4.0:
		visible = false
		collision_layer = 0
		_respawn = 0.2
		velocity = Vector3.ZERO

func _home_is_clear() -> bool:
	return MobSpawnClearance.clear(self)

func _process(delta: float) -> void:
	if not visible: return
	delta = _view_visibility.render_delta(delta)
	if delta <= 0.0: return
	var aim := quarry.global_position - global_position if is_instance_valid(quarry) else Vector3.ZERO
	# Replicas retain their last travel facing; their quarry is not authoritative.
	if not is_physics_processing(): aim = Vector3.ZERO
	_present_visual(aim, delta)
	reaction.present(_reaction_visual(), delta)

func _reaction_visual() -> Node3D:
	return _sprite

func _create_visual() -> void:
	_sprite = SnailVisuals.new()
	add_child(_sprite)

func _present_visual(aim: Vector3, delta: float) -> void:
	_sprite.present(velocity, aim, _windup, delta)

func _flash_visual() -> void:
	_sprite.modulate = Color(3, 1.0, 0.8)

func flash_hit() -> void:
	_flash_visual()
	reaction.flash(velocity)

func _create_nameplate() -> void:
	_nameplate = MobLabels.make(self, _nameplate_text(), 28, 0.008, Color("f2f4d0"), _nameplate_height())
	_nameplate.outline_size = 6

func _nameplate_text() -> String:
	return "SNAIL · LV 1"

func _nameplate_height() -> float:
	return 1.5

func _choose_direction(delta: float) -> Vector3:
	return SnailSteering.choose_direction(self, delta)

func _protected(at: Vector3) -> bool:
	return protected_area.has_area() and protected_area.has_point(Vector2(at.x, at.z))

func _can_reach_quarry() -> bool:
	return SnailSteering.can_reach_quarry(self)

func _hit(_amount: float, direction: Vector3) -> void:
	reaction.receive(direction, target.last_hit_kind)
	_knockback = Vector3(direction.x, 0, direction.z)
	if direction.y > 0.0: velocity.y = maxf(velocity.y, direction.y)
	elif direction.y < 0.0: velocity.y = minf(velocity.y, direction.y)
	_flash_visual()
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
	reaction.clear()

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
