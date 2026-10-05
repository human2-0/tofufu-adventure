class_name SnailVisuals
extends Sprite3D
## Eight facing directions from five authored rows, with mirrored side views.

const IDLE = preload("res://assets/characters/snail/idle.png")
const WALK = preload("res://assets/characters/snail/walking.png")
const ATTACK = preload("res://assets/characters/snail/attack.png")
var _facing := Vector2.DOWN
var _age: float = 0.0
var _attack_age: float = -1.0
var _was_winding: bool = false
var _moving: bool = false

func _ready() -> void:
	texture = IDLE
	hframes = 5
	vframes = 5
	pixel_size = 0.0065
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	# Anchor the feet in the billboard plane so camera tilt cannot lift them.
	offset.y = 112.0
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	alpha_scissor_threshold = 0.1

func present(motion: Vector3, aim: Vector3, windup: float, delta: float) -> void:
	var moving := Vector2(motion.x, motion.z).length_squared() > 0.04
	var winding := windup > 0.0
	if winding:
		if Vector2(aim.x, aim.z).length_squared() > 0.001:
			_facing = Vector2(aim.x, aim.z).normalized()
		_attack_age = 0.65 - windup
	elif _was_winding:
		# Frame four lands at the existing strike time; frame five recovers.
		_attack_age = 0.65 if _attack_age >= 0.58 else -1.0
	elif _attack_age >= 0.0:
		_attack_age += delta
		if _attack_age >= 1.05: _attack_age = -1.0
	elif moving:
		_facing = Vector2(motion.x, motion.z).normalized()
	if moving != _moving: _age = 0.0
	_age += delta
	_moving = moving
	_was_winding = winding
	var relative := _facing
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		var world := Vector3(_facing.x, 0, _facing.y)
		var back := Vector3(camera.global_basis.z.x, 0, camera.global_basis.z.z).normalized()
		relative = Vector2(world.dot(camera.global_basis.x), world.dot(back))
	var angle := atan2(relative.x, relative.y)
	var direction := posmod(roundi(angle / (PI / 4.0)), 8)
	var row := direction if direction <= 4 else 8 - direction
	flip_h = direction > 4
	var column: int
	if _attack_age >= 0.0:
		texture = ATTACK
		column = mini(2, int(_attack_age / 0.217)) if winding else (3 if _attack_age < 0.85 else 4)
	else:
		texture = WALK if moving else IDLE
		column = int(_age * (8.0 if moving else 4.0)) % 5
	frame = row * 5 + column
	modulate = modulate.lerp(Color.WHITE, 1.0 - exp(-delta * 5.0))
