class_name FufuVisuals
extends Sprite3D
## Eight-way presentation; walking faces travel, mouse aiming faces attacks/idle.

signal hand_presented(hand: Vector3, plane: Basis, outward: float, in_front: bool)

@export_enum("Full Billboard", "Y-Billboard", "Fixed Tilt", "Upright") var orientation_mode: int = 0
var idle_texture: Texture2D = preload("res://assets/characters/fufu/soybean_fufu-idle-eight.png")
var walk_texture: Texture2D = preload("res://assets/characters/fufu/soybean_fufu-walk.png")
var diagonal_texture: Texture2D = preload("res://assets/characters/fufu/soybean_fufu-diagonal.png")
const BASE_WALK_PIXEL_SIZE: float = 0.005
const BASE_IDLE_PIXEL_SIZE: float = 0.00284
const IDLE_FRAMES: Array[int] = [6, 7, 0, 1, 2, 3, 4, 3]
const IDLE_FEET: Array[float] = [411, 410, 420, 412, 407.5, 406.5, 413.5, 407.5]
const IDLE_CENTERS: Array[float] = [253, 221, 201, 219, 237.5, 230, 224.5, 234]
const DIAGONAL_PIXEL_SIZE: float = 0.0112 * 512.0 / 1254.0
const DIAGONAL_FOOT_Y: Array[float] = [297.0, 295.0, 299.0, 296.0, 282.5, 282.5, 286.5, 284.5, 269.0, 265.0, 269.0, 264.0, 256.5, 254.5, 256.5, 254.5]
# Grip landmarks in source-cell pixels, before mirroring and foot/center offsets.
const IDLE_HANDS: Array[Vector2] = [Vector2(313,301), Vector2(138,297), Vector2(117,309), Vector2(116,292), Vector2(363,286), Vector2(123,285), Vector2(321,305), Vector2(305,290)]
const WALK_HANDS: Array[Vector2] = [Vector2(195,212), Vector2(195,208), Vector2(195,208), Vector2(193,210), Vector2(218,205), Vector2(217,203), Vector2(212,204), Vector2(214,199), Vector2(120,205), Vector2(123,204), Vector2(119,204), Vector2(119,206)]
const DIAGONAL_HANDS: Array[Vector2] = [Vector2(219,226), Vector2(220,222), Vector2(218,225), Vector2(217,224), Vector2(100,218), Vector2(99,219), Vector2(100,219), Vector2(102,219), Vector2(235,184), Vector2(232,183), Vector2(234,186), Vector2(230,184), Vector2(99,180), Vector2(99,177), Vector2(98,180), Vector2(100,178)]

enum Facing { RIGHT, DOWN_RIGHT, DOWN, DOWN_LEFT, LEFT, UP_LEFT, UP, UP_RIGHT }
var current_facing: Facing = Facing.DOWN
var attack_facing: Vector2 = Vector2.ZERO
var anim_timer: float = 0.0
var anim_frame: int = 0
var anim_fps: float = 9.0
var idle_bob_time: float = 0.0
var _ghost_timer: float = 0.0
var jump_animation := FufuJumpAnimation.new()
var charge_animation := FufuChargeAnimation.new()
var _using_charge_frame: bool = false
var _using_jump_frame: bool = false

func _ready() -> void:
	alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
	alpha_scissor_threshold = 0.5
	shaded = false
	double_sided = true
	match orientation_mode:
		0: billboard = BaseMaterial3D.BILLBOARD_ENABLED
		1: billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		2:
			billboard = BaseMaterial3D.BILLBOARD_DISABLED
			rotation_degrees.x = -45.0
		3: billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_set_frame(false)

func present(command: PlayerCommand, velocity: Vector3, grounded: bool, dashing: bool, delta: float, jump_charge: float = 0.0, clearance: float = INF) -> void:
	var walking := command.move.length_squared() > 0.01 and Vector2(velocity.x, velocity.z).length_squared() > 0.01
	var direction := command.move if walking else command.aim
	if command.attack_held:
		direction = command.aim
	if not attack_facing.is_zero_approx():
		direction = attack_facing
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		var world := Vector3(direction.x, 0, direction.y)
		var back := Vector3(camera.global_basis.z.x, 0, camera.global_basis.z.z).normalized()
		direction = Vector2(world.dot(camera.global_basis.x), world.dot(back))
	if direction.length_squared() > 0.01:
		current_facing = posmod(roundi(direction.angle() / (PI / 4.0)), 8) as Facing
	if walking:
		anim_timer += delta * anim_fps
		anim_frame = int(anim_timer) % 4
		idle_bob_time = 0.0
	else:
		anim_timer = 0.0
		anim_frame = 0
		idle_bob_time += delta * 3.5
	_set_frame(walking)
	jump_animation.step(grounded, velocity.y, jump_charge > 0.0, clearance, delta)
	_using_charge_frame = false
	_using_jump_frame = false
	if grounded and jump_charge > 0.0:
		_using_charge_frame = charge_animation.apply(self, current_facing, int(anim_timer) % 6 if walking else 0)
	elif jump_animation.frame >= 0:
		jump_animation.apply(self, current_facing)
		_using_jump_frame = true
	if dashing:
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			DashGhost.spawn(self)
			_ghost_timer = 0.04
		_present_hand()
		return
	if jump_charge > 0.0:
		scale = Vector3(1.0 + jump_charge * 0.08, 1.0 - jump_charge * 0.12, 1.0)
	elif not grounded or velocity.length_squared() > 0.01:
		scale = scale.move_toward(Vector3.ONE, delta * 6.0)
	else:
		scale.x = move_toward(scale.x, 1.0 - sin(idle_bob_time) * 0.02, delta * 3.0)
		scale.y = move_toward(scale.y, 1.0 + sin(idle_bob_time) * 0.035, delta * 3.0)
	_present_hand()

func _set_frame(walking: bool) -> void:
	material_override = null
	flip_h = false
	offset = Vector2.ZERO
	if not walking:
		texture = idle_texture
		hframes = 4
		vframes = 2
		pixel_size = BASE_IDLE_PIXEL_SIZE
		frame = IDLE_FRAMES[current_facing]
		offset = Vector2(221.75 - IDLE_CENTERS[frame], IDLE_FEET[frame] - 221.75 - 0.56 / pixel_size)
		# The supplied NE cell repeats the back view. Mirror the actual NW pose.
		flip_h = current_facing == Facing.UP_RIGHT
		if flip_h:
			offset.x = -offset.x
	elif int(current_facing) % 2 == 1:
		texture = diagonal_texture
		hframes = 4
		vframes = 4
		pixel_size = DIAGONAL_PIXEL_SIZE
		# Shared sheet: SE, SW, NE, NW. Four walking frames per row.
		var rows := {Facing.DOWN_RIGHT: 0, Facing.DOWN_LEFT: 1, Facing.UP_RIGHT: 2, Facing.UP_LEFT: 3}
		frame = int(rows[current_facing]) * 4 + anim_frame
		offset.y = DIAGONAL_FOOT_Y[frame] - 156.75 - 0.56 / DIAGONAL_PIXEL_SIZE
	else:
		texture = walk_texture
		hframes = 4
		vframes = 3
		pixel_size = BASE_WALK_PIXEL_SIZE
		var row := 0 if current_facing == Facing.DOWN else (1 if current_facing == Facing.UP else 2)
		flip_h = current_facing == Facing.RIGHT
		frame = row * 4 + anim_frame

func _present_hand() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var point := IDLE_HANDS[frame] if texture == idle_texture else (DIAGONAL_HANDS[frame] if texture == diagonal_texture else WALK_HANDS[frame])
	if _using_charge_frame:
		point = charge_animation.hand
	elif _using_jump_frame:
		point = jump_animation.hand
	var cell := Vector2(texture.get_size()) / Vector2(hframes, vframes)
	if flip_h:
		point.x = cell.x - point.x
	var local := Vector3(point.x - cell.x * 0.5 + offset.x, cell.y * 0.5 - point.y + offset.y, 0) * pixel_size
	var plane := global_basis.orthonormalized()
	if billboard == BaseMaterial3D.BILLBOARD_ENABLED:
		plane = camera.global_basis.orthonormalized()
	elif billboard == BaseMaterial3D.BILLBOARD_FIXED_Y:
		var normal := Vector3(camera.global_basis.z.x, 0, camera.global_basis.z.z).normalized()
		plane = Basis(Vector3.UP.cross(normal), Vector3.UP, normal)
	var hand := global_position + plane * (local * global_basis.get_scale())
	var in_front := (_using_jump_frame and current_facing in [Facing.RIGHT, Facing.DOWN_RIGHT, Facing.DOWN, Facing.DOWN_LEFT, Facing.LEFT]) or current_facing in [Facing.DOWN_LEFT, Facing.DOWN, Facing.DOWN_RIGHT]
	if _using_charge_frame and current_facing in [Facing.LEFT, Facing.RIGHT]:
		in_front = true
	hand_presented.emit(hand, plane, -1.0 if local.x < 0 else 1.0, in_front)

func show_jump() -> void:
	jump_animation.launch()
	scale = Vector3.ONE

func show_dash() -> void:
	scale = Vector3(1.35, 0.7, 1.35)
	DashGhost.spawn(self)
	_ghost_timer = 0.04
