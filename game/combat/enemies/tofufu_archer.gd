class_name TofufuArcher
extends WildBee
## Fallen celestial archer: the same swept ranged contract, distinct tuning and art.

const EXPERIENCE: int = 450
var art: ArcherVisuals

func _ready() -> void:
	shot_height = 1.2
	shot_windup = 0.9
	shot_cooldown = 1.65
	super()
	leash_radius = 22.0
	var capsule := _collider.shape as CapsuleShape3D
	capsule.height = 1.8
	_collider.position.y = 0.9
	target.position.y = 0.9
	target.headshot_height = 1.3

func _ranged_tuning() -> SnailTuning:
	return preload("res://game/combat/enemies/tofufu_archer.tres")

func _create_projectile() -> BeeSting:
	return GroatShot.new()

func _create_visual() -> void:
	art = ArcherVisuals.new()
	add_child(art)

func _choose_direction(delta: float) -> Vector3:
	var direction := super(delta)
	if _windup > 0.0:
		facing = Vector3(_sting_aim.x, 0, _sting_aim.z).normalized()
	elif direction.length_squared() > 0.01:
		facing = Vector3(direction.x, 0, direction.z).normalized()
	elif not _returning and is_instance_valid(quarry) and not _protected(quarry.global_position):
		var aim := quarry.global_position - global_position
		if aim.length() <= SIGHT_RANGE:
			facing = Vector3(aim.x, 0, aim.z).normalized()
	return direction

func _present_visual(_aim: Vector3, delta: float) -> void:
	var moving := Vector2(velocity.x, velocity.z).length_squared() > 0.04
	art.present(facing, _windup, delta, moving)

func _flash_visual() -> void:
	art.modulate = Color(3, 1, 0.8)

func _reaction_visual() -> Node3D:
	return art

func _nameplate_text() -> String:
	return "TOFUFU ANGEL · LV 20"

func _nameplate_height() -> float:
	return 2.8
