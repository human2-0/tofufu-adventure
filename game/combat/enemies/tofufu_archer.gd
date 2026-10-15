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

func _present_visual(aim: Vector3, delta: float) -> void:
	if is_physics_processing():
		if _windup > 0.0: facing = Vector3(_sting_aim.x, 0, _sting_aim.z).normalized()
		elif aim.length_squared() > 0.01: facing = Vector3(aim.x, 0, aim.z).normalized()
	art.present(facing, _windup, delta)

func _flash_visual() -> void:
	art.modulate = Color(3, 1, 0.8)

func _reaction_visual() -> Node3D:
	return art

func _nameplate_text() -> String:
	return "TOFUFU ANGEL · LV 20"

func _nameplate_height() -> float:
	return 2.8
