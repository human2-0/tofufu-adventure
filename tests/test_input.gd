extends SceneTree

var failures: int = 0
var source: LocalPlayerInput

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func axis(index: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = index
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func button(index: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = index
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _run() -> void:
	source = LocalPlayerInput.new()
	root.add_child(source)
	axis(JOY_AXIS_LEFT_X, 0.1)
	check(source.sample(Vector3.ZERO).move.is_zero_approx(), "stick drift filtered")
	axis(JOY_AXIS_LEFT_X, 0.6)
	var command := source.sample(Vector3.ZERO)
	check(command.move.x > 0.0 and command.move.x < 1.0, "analog speed preserved")
	check(command.aim.is_equal_approx(Vector2.RIGHT), "travel aims without right stick")
	axis(JOY_AXIS_RIGHT_Y, -1.0)
	command = source.sample(Vector3.ZERO)
	check(command.aim.is_equal_approx(Vector2.UP), "right stick overrides travel aim")
	check(command.dash_direction.is_equal_approx(Vector2.RIGHT), "dash follows travel")
	axis(JOY_AXIS_LEFT_X, 0.0)
	axis(JOY_AXIS_RIGHT_Y, 0.0)
	check(source.sample(Vector3.ZERO).aim.is_equal_approx(Vector2.UP), "idle aim retained")
	button(JOY_BUTTON_DPAD_LEFT, true)
	check(source.sample(Vector3.ZERO).move.is_equal_approx(Vector2.LEFT), "D-pad movement")
	button(JOY_BUTTON_DPAD_LEFT, false)
	await physics_frame
	button(JOY_BUTTON_A, true)
	button(JOY_BUTTON_B, true)
	button(JOY_BUTTON_X, true)
	await physics_frame
	command = source.sample(Vector3.ZERO)
	check(command.jump_pressed and command.jump_held and command.dash_pressed and command.attack_held,
		"controller simultaneous actions and initial edges")
	await physics_frame
	await process_frame
	await physics_frame
	command = source.sample(Vector3.ZERO)
	check(command.jump_held and not command.jump_pressed and not command.dash_pressed,
		"held buttons do not retrigger edges")
	button(JOY_BUTTON_A, false)
	button(JOY_BUTTON_B, false)
	button(JOY_BUTTON_X, false)
	check(not source.sample(Vector3.ZERO).attack_held, "release ends charge")
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_RIGHT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	Input.action_press("punch")
	command = source.sample(Vector3.ZERO)
	check(command.guard_held and command.punch_held and not command.attack_held, "guard and punch do not charge knife")
	mouse.pressed = false
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	check(not source.sample(Vector3.ZERO).guard_held, "RMB release lowers defence")
	Input.action_release("punch")
	root.size = Vector2i(1280, 720)
	var touch := TouchControls.new()
	touch.force_visible = true
	root.add_child(touch)
	check(touch.visible and touch._buttons.size() == 9, "mobile controls compose")
	await process_frame
	for index in [1, 4, 6]:
		var event := InputEventScreenTouch.new()
		event.index = index
		event.position = touch._buttons[index].get_global_transform_with_canvas().origin
		event.pressed = true
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	command = source.sample(Vector3.ZERO)
	check(command.move.x > 0.0 and command.jump_held and command.attack_held,
		"three touch fingers can move, jump and charge together")
	for index in [1, 4, 6]:
		var event := InputEventScreenTouch.new()
		event.index = index
		event.position = touch._buttons[index].get_global_transform_with_canvas().origin
		event.pressed = false
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	command = source.sample(Vector3.ZERO)
	check(command.move.is_zero_approx() and not command.jump_held and not command.attack_held,
		"touch release clears movement and held actions")
	touch.queue_free()
	source.queue_free()
	await process_frame
	print("Input tests: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
