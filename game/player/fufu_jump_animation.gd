class_name FufuJumpAnimation
extends RefCounted
## Contact/velocity-driven presentation. Never controls movement or collision.

const TEXTURES: Array[Texture2D] = [
	preload("res://assets/characters/fufu/jump/frame_01_takeoff.png"),
	preload("res://assets/characters/fufu/jump/frame_02_push_off.png"),
	preload("res://assets/characters/fufu/jump/frame_03_ascent.png"),
	preload("res://assets/characters/fufu/jump/frame_04_apex.png"),
	preload("res://assets/characters/fufu/jump/frame_05_fall_start.png"),
	preload("res://assets/characters/fufu/jump/frame_06_mid_fall.png"),
	preload("res://assets/characters/fufu/jump/frame_07_pre_landing.png"),
	preload("res://assets/characters/fufu/jump/frame_08_landing_impact.png"),
	preload("res://assets/characters/fufu/jump/frame_09_rebound.png"),
	preload("res://assets/characters/fufu/jump/frame_10_settled.png")]
const PIXEL_SIZE: float = 0.0012
const FEET: Array[float] = [1046, 1062, 1039, 1057, 1009, 1041, 1081, 1065, 1054, 1135]
const CENTERS: Array[float] = [615, 615, 625, 620, 625, 620, 620, 627, 630, 630]
const HANDS: Array[Vector2] = [Vector2(770,890), Vector2(744,795), Vector2(713,779), Vector2(870,698), Vector2(743,786), Vector2(752,845), Vector2(744,828), Vector2(846,940), Vector2(750,855), Vector2(733,918)]
var directional := DirectionalJumpArt.new()
var hand := Vector2.ZERO
var frame: int = -1
var _airborne: bool = false
var _air_time: float = 0.0
var _landing_time: float = -1.0
var _launched: bool = false

func launch() -> void:
	_launched = true
	_air_time = 0.0
	_landing_time = -1.0

func reset() -> void:
	frame = -1
	_airborne = false
	_air_time = 0.0
	_landing_time = -1.0
	_launched = false

func step(grounded: bool, vertical_speed: float, charging: bool, clearance: float, delta: float) -> void:
	frame = -1
	if not grounded:
		_airborne = true
		_air_time += delta
		_landing_time = -1.0
		if _launched and _air_time < 0.07:
			frame = 0
		elif _launched and _air_time < 0.14 and vertical_speed > 0.0:
			frame = 1
		elif vertical_speed > 2.0:
			frame = 2
		elif vertical_speed > -2.0:
			frame = 3
		elif clearance < maxf(0.4, -vertical_speed * 0.08):
			frame = 6
		else:
			frame = 4 if vertical_speed > -5.0 else 5
	else:
		if _airborne:
			_landing_time = 0.0
		_airborne = false
		_launched = false
		_air_time = 0.0
		if _landing_time >= 0.0:
			frame = 7 + mini(2, int(_landing_time / 0.07))
			_landing_time += delta
			if _landing_time >= 0.21:
				_landing_time = -1.0
		if charging:
			frame = 0

func apply(sprite: Sprite3D, facing: int = 2) -> void:
	if directional.apply(sprite, facing, frame):
		hand = directional.hand
		return
	hand = HANDS[frame]
	sprite.material_override = null
	sprite.texture = TEXTURES[frame]
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	sprite.flip_h = false
	sprite.pixel_size = PIXEL_SIZE
	sprite.offset = Vector2(627 - CENTERS[frame], FEET[frame] - 627 - 0.56 / PIXEL_SIZE)
