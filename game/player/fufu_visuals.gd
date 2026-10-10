class_name FufuVisuals
extends Sprite3D
## Eight-way presentation; walking faces travel, mouse aiming faces attacks/idle.

signal hand_presented(hand: Vector3, plane: Basis, outward: float, in_front: bool)
signal hand_tint_presented(tint: Color)

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
var worn_appearance := FufuWornAppearance.new()
var celestial_art := CelestialFufuArt.new()
var celestial_pose: Callable
var celestial_aura := CelestialAura.new()
var _using_charge_frame: bool = false
var _using_jump_frame: bool = false
var worn_set: String = ""
var _outfit_tween: Tween

func _ready() -> void:
	add_child(celestial_aura)
	celestial_aura.set_active(worn_set == "celestial")
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
	if command.attack_held or command.face_aim:
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
		var stride := clampf(Vector2(velocity.x, velocity.z).length() / 4.8, 0.45, 1.65)
		anim_timer += delta * anim_fps * stride
		anim_frame = int(anim_timer) % 4
		idle_bob_time = 0.0
	else:
		anim_timer = 0.0
		anim_frame = 0
		idle_bob_time += delta * 3.5
	if worn_set != "celestial": _set_frame(walking)
	jump_animation.step(grounded, velocity.y, jump_charge > 0.0, clearance, delta)
	_using_charge_frame = false
	_using_jump_frame = false
	if worn_set == "celestial":
		celestial_art.present(self, walking, grounded, dashing, jump_charge, delta, celestial_pose.call() if celestial_pose.is_valid() else {})
	elif worn_set.is_empty() and grounded and jump_charge > 0.0:
		_using_charge_frame = charge_animation.apply(self, current_facing, int(anim_timer) % 6 if walking else 0)
	elif jump_animation.frame >= 0:
		if worn_set.is_empty():
			jump_animation.apply(self, current_facing)
		else:
			worn_appearance.apply_jump(self, worn_set, int(current_facing), jump_animation.frame)
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
	if worn_set == "celestial":
		celestial_art.apply(self, int(current_facing), "walk" if walking else "idle", anim_frame if walking else 0)
		return
	if not worn_set.is_empty():
		worn_appearance.apply(self, worn_set, int(current_facing), walking, anim_frame)
		return
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

func set_worn_set(set_id: String, animate: bool = true) -> void:
	if set_id not in ["", "bright_leaf", "dark_leaf", "celestial"]: set_id = ""
	if worn_set == set_id: return
	if _outfit_tween != null and _outfit_tween.is_valid(): _outfit_tween.kill()
	modulate.a = 1.0
	if animate and not set_id.is_empty() and is_inside_tree():
		OutfitEquipEffect.spawn(self, Color("e6bb5a") if set_id == "celestial" else (Color("adf46c") if set_id == "bright_leaf" else Color("85d8c0")))
	worn_set = set_id
	celestial_aura.set_active(set_id == "celestial")
	_set_frame(false)
	if animate and not set_id.is_empty() and is_inside_tree():
		modulate.a = 0.0
		_outfit_tween = create_tween()
		_outfit_tween.tween_property(self, "modulate:a", 1.0, 0.35)

func _present_hand() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var point := FufuRightHand.point(self)
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
	# Anatomical right is near in E/SE/S/NE, far in W/SW/N/NW.
	var in_front := int(current_facing) in [0, 1, 2, 7]
	var outward := -1.0 if int(current_facing) in [1, 2, 3, 4] else 1.0
	hand_tint_presented.emit(FufuRightHand.tint(worn_set))
	hand_presented.emit(hand, plane, outward, in_front)

func show_jump() -> void:
	jump_animation.launch()
	scale = Vector3.ONE

func show_dash() -> void:
	scale = Vector3(1.35, 0.7, 1.35)
	DashGhost.spawn(self)
	_ghost_timer = 0.04
