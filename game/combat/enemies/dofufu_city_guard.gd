class_name DofufuCityGuard
extends TrainingMob
## Gate opponent using the existing authoritative encounter and replica contract.

var art: Sprite3D

func _ready() -> void:
	tuning = SnailTuning.new()
	tuning.dry_health = 130
	tuning.rain_health = 130
	tuning.dry_damage = 18
	tuning.rain_damage = 18
	tuning.dry_respawn = 30
	tuning.rain_respawn = 30
	leash_radius = 12
	super._ready()
	(_collider.shape as CapsuleShape3D).height = 1.65
	_collider.position.y = 0.825
	target.headshot_height = 1.25
	target.position.y = 0.8

func _create_visual() -> void:
	add_child(art)

func _reaction_visual() -> Node3D:
	return art

func _present_visual(aim: Vector3, _delta: float) -> void:
	var direction := velocity if velocity.length_squared() > 0.1 else aim
	if direction.length_squared() > 0.1: art.set("facing", Vector2(direction.x, direction.z).normalized())
	art.rotation.z = sin(Time.get_ticks_msec() * 0.009) * 0.055 if velocity.length_squared() > 0.1 else 0.0

func _flash_visual() -> void:
	art.modulate = Color(3, 1.0, 0.8)

func _nameplate_text() -> String:
	return "DOFUFU · GATE GUARD"

func _nameplate_height() -> float:
	return 2.2
