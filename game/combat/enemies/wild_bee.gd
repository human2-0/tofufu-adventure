class_name WildBee
extends TrainingMob
## Ground-colliding skirmisher with a hovering view and committed ranged stings.

signal stung(victim: Node3D, amount: float, source: Vector3)
const LEVEL: int = 3
const SIGHT_RANGE: float = 22.0
const STING_RANGE: float = 18.0
const WINDUP: float = 0.7
const COOLDOWN: float = 2.3
var sting: BeeSting
var _bee_visual: BeeVisuals
var _sting_aim := Vector3.ZERO
var _provoked: float = 0.0
var facing := Vector3.BACK

func _ready() -> void:
	tuning = preload("res://game/combat/enemies/default_bee.tres")
	leash_radius = 12.0
	super()
	sting = BeeSting.new()
	add_child(sting)
	sting.struck.connect(_sting_struck)
	target.headshot_height = 0.8

func _physics_process(delta: float) -> void:
	_provoked = maxf(0.0, _provoked - delta)
	super(delta)
	if available and visible and _respawn <= 0.0:
		sting.step(delta, protected_area, get_rid())
	else:
		sting.clear()

func _create_visual() -> void:
	_bee_visual = BeeVisuals.new()
	add_child(_bee_visual)

func _present_visual(aim: Vector3, delta: float) -> void:
	if is_physics_processing():
		if _windup > 0.0: facing = Vector3(_sting_aim.x, 0, _sting_aim.z).normalized()
		elif aim.length_squared() > 0.01: facing = Vector3(aim.x, 0, aim.z).normalized()
		elif velocity.length_squared() > 0.01: facing = Vector3(velocity.x, 0, velocity.z).normalized()
	_bee_visual.present(facing, _windup, delta)

func _flash_visual() -> void:
	_bee_visual.flash()

func _reaction_visual() -> Node3D:
	return _bee_visual

func _nameplate_text() -> String:
	return "WILD BEE · LV %d" % LEVEL

func _nameplate_height() -> float:
	return 1.65

func _choose_direction(delta: float) -> Vector3:
	var home := _home - position
	home.y = 0.0
	if not is_instance_valid(quarry) or _protected(quarry.global_position) or home.length() > leash_radius:
		_returning = true
	if _returning:
		_cancel_sting()
		sting.clear()
		if home.length() < 0.4:
			_returning = false
			return Vector3.ZERO
		return home.normalized() * 3.8
	var offset := quarry.global_position - global_position
	var distance := offset.length()
	if distance > SIGHT_RANGE and _provoked <= 0.0:
		_cancel_sting()
		return SnailSteering._wander(self, delta)
	targeting.emit(quarry)
	if _windup > 0.0:
		_windup = maxf(0.0, _windup - delta)
		if _windup <= 0.0:
			_warning.visible = false
			if _can_reach_quarry(): sting.launch(global_position + Vector3.UP * 0.7, _sting_aim)
			_rest = COOLDOWN
		return Vector3.ZERO
	if _rest <= 0.0 and not sting.active and distance <= STING_RANGE and _can_reach_quarry():
		# Lock aim at the warning, leaving time to sidestep the straight flight.
		_sting_aim = (quarry.global_position + Vector3.UP * 0.7 - (global_position + Vector3.UP * 0.7)).normalized()
		_windup = WINDUP
		_warning.visible = true
		return Vector3.ZERO
	offset.y = 0.0
	if distance < 4.0: return -offset.normalized() * 3.4
	if distance > 7.0: return offset.normalized() * 3.4
	return Vector3.ZERO

func _hit(amount: float, direction: Vector3) -> void:
	super(amount, direction)
	_provoked = 8.0

func _die() -> void:
	sting.clear()
	_provoked = 0.0
	super()

func _cancel_sting() -> void:
	_windup = 0.0
	_warning.visible = false

func _sting_struck(victim: Node3D, source: Vector3) -> void:
	stung.emit(victim, tuning.dry_damage, source)
