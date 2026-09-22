class_name LocalPlayerInput
extends PlayerCommandSource
## Actions share keyboard, gamepad and touch bindings; rules see only commands.

var first_person_view: bool = false
var shoulder_view: bool = false
var enabled: bool = true
var pickup_target: int = 0
var focus_point: Vector3 = Vector3.INF
var chat_blocked: bool = false
var _aim: Vector2 = Vector2.DOWN
var _shot_direction: Vector3 = Vector3.BACK
var _pointer_aim: bool = not OS.has_feature("mobile")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.relative.length_squared() > 1.0:
		_pointer_aim = true
	elif event is InputEventMouseButton:
		_pointer_aim = true
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		_pointer_aim = false
	elif event is InputEventJoypadButton and event.pressed:
		_pointer_aim = false
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.25:
		_pointer_aim = false

func sample(world_position: Vector3) -> PlayerCommand:
	var command := PlayerCommand.new()
	if not enabled or chat_blocked:
		command.cancel_actions = true
		return command
	command.move = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	var vp := get_viewport()
	var ui_active: bool = vp != null and vp.gui_get_hovered_control() != null
	if _pointer_aim and not shoulder_view and not ui_active:
		_update_mouse_aim(world_position)
	elif not shoulder_view and not stick.is_zero_approx():
		_aim = stick.normalized()
	elif not shoulder_view and not command.move.is_zero_approx():
		_aim = command.move.normalized()
	command.aim_point = _shooting_point(world_position)
	focus_point = command.aim_point
	_shot_direction = (command.aim_point - world_position - Vector3.UP * 0.65).normalized()
	if shoulder_view:
		var camera := get_viewport().get_camera_3d()
		var right := Vector2(camera.global_basis.x.x, camera.global_basis.x.z).normalized()
		var back := Vector2(camera.global_basis.z.x, camera.global_basis.z.z).normalized()
		command.move = right * command.move.x + back * command.move.y
		if _camera_aim_active():
			var direction := command.aim_point - world_position
			_aim = Vector2(direction.x, direction.z).normalized()
	command.face_aim = first_person_view
	command.aim = _aim
	command.dash_direction = command.move.normalized() if command.move.length_squared() > 0.01 else _aim
	command.camp_pressed = Input.is_action_just_pressed("return_to_camp")
	command.time_pressed = Input.is_action_just_pressed("skip_time")
	command.jump_held = Input.is_action_pressed("jump")
	command.attack_held = not ui_active and Input.is_action_pressed("attack")
	command.guard_held = not ui_active and Input.is_action_pressed("guard")
	command.punch_held = not ui_active and Input.is_action_pressed("punch")
	command.drop_pressed = Input.is_action_just_pressed("drop_weapon")
	command.pickup_pressed = Input.is_action_just_pressed("pickup_weapon")
	command.pickup_id = pickup_target
	command.weapon_slot = 1 if Input.is_action_just_pressed("combat_slot_1") else (2 if Input.is_action_just_pressed("combat_slot_2") else 0)
	command.use_healing_1 = Input.is_action_just_pressed("use_support_1")
	command.use_healing_2 = Input.is_action_just_pressed("use_support_2")
	command.use_healing_3 = Input.is_action_just_pressed("use_support_3")
	command.use_healing_4 = Input.is_action_just_pressed("use_support_4")
	command.jump_pressed = Input.is_action_just_pressed("jump")
	command.dash_pressed = Input.is_action_just_pressed("dash")
	return command

func _update_mouse_aim(world_position: Vector3) -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
	var mouse := get_viewport().get_mouse_position()
	var plane := Plane(Vector3.UP, world_position.y)
	var hit: Variant = plane.intersects_ray(
		camera.project_ray_origin(mouse), camera.project_ray_normal(mouse))
	if hit != null:
		var offset: Vector3 = hit - world_position
		var planar := Vector2(offset.x, offset.z)
		if planar.length_squared() > 0.09:
			_aim = planar.normalized()

func _shooting_point(world_position: Vector3) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if shoulder_view and not _camera_aim_active():
		return world_position + Vector3.UP * 0.65 + _shot_direction * 60
	if camera == null or (not _pointer_aim and not shoulder_view):
		return world_position + Vector3.UP * 0.65 + Vector3(_aim.x, 0, _aim.y) * 60
	var pointer := get_viewport().get_visible_rect().size * 0.5 if shoulder_view else get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(pointer)
	var direction := camera.project_ray_normal(pointer)
	var excluded: Array[RID] = []
	if get_parent() is CollisionObject3D: excluded.append(get_parent().get_rid())
	var ray := PhysicsRayQueryParameters3D.create(origin, origin + direction * 90, 3, excluded)
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty(): return hit.position
	if not shoulder_view:
		var point: Variant = Plane(Vector3.UP, world_position.y + 0.65).intersects_ray(origin, direction)
		if point != null: return point
	return origin + direction * 90

func _camera_aim_active() -> bool:
	return first_person_view or Input.is_action_pressed("attack") or Input.is_action_pressed("guard")

func focus_direction() -> Vector2:
	return _aim
