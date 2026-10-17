class_name BengalMonster
extends TrainingMob
## Fast, committed jungle claws with a short recovery that rewards sidestepping.

const LEVEL: int = 15
const EXPERIENCE: int = 250
const RUN_SPEED: float = 5.6
const WINDUP: float = 0.42
var facing := Vector3.BACK
var claw_time: float = 0.0
var art: BengalVisuals

func _ready() -> void:
	tuning = preload("res://game/combat/enemies/bengal.tres")
	leash_radius = 18.0
	super._ready()
	target.headshot_height = 0.85

func _create_visual() -> void:
	art = BengalVisuals.new()
	add_child(art)

func _reaction_visual() -> Node3D:
	return art

func _present_visual(_aim: Vector3, delta: float) -> void:
	art.present(facing, velocity.length_squared() > 0.2 and target.paralysis <= 0, _windup, claw_time, delta)

func _flash_visual() -> void:
	art.modulate = Color(3, 1.4, 0.8)

func _nameplate_text() -> String:
	return "CHIBI BENGAL · LV 15"

func _nameplate_height() -> float:
	return 1.75

func _choose_direction(delta: float) -> Vector3:
	claw_time = maxf(0, claw_time - delta)
	var home := _home - position
	home.y = 0
	if not is_instance_valid(quarry) or home.length() > leash_radius or _protected(quarry.global_position):
		_returning = true
	if _returning:
		_windup = 0
		_warning.visible = false
		if home.length() < 0.4:
			_returning = false
			return Vector3.ZERO
		return _face(home.normalized() * RUN_SPEED)
	var offset := quarry.global_position - global_position
	var distance := offset.length()
	if distance < 12 or _windup > 0: targeting.emit(quarry)
	if _windup > 0:
		_windup = maxf(0, _windup - delta)
		if _windup <= 0:
			_warning.visible = false
			claw_time = 0.25
			var planar := Vector3(offset.x, 0, offset.z)
			if distance < 2.0 and planar.normalized().dot(facing) > 0.55 and _can_reach_quarry():
				attacked.emit(tuning.dry_damage, global_position)
			_rest = 0.9
		return Vector3.ZERO
	if _rest > 0: return Vector3.ZERO
	if distance < 1.65:
		_face(Vector3(offset.x, 0, offset.z))
		_windup = WINDUP
		_warning.visible = true
		return Vector3.ZERO
	if distance < 12:
		return _face(Vector3(offset.x, 0, offset.z).normalized() * RUN_SPEED)
	return _face(SnailSteering._wander(self, delta) * 1.5)

func _face(motion: Vector3) -> Vector3:
	if motion.length_squared() > 0.01: facing = motion.normalized()
	return motion

func _die() -> void:
	claw_time = 0
	super._die()
