extends SceneTree

var failures: int = 0
const DT: float = 1.0 / 60.0

func _initialize() -> void:
	_test_walk_and_fall()
	_test_jump_windows()
	_test_dash_and_isolation()
	_test_super_dash()
	_test_wind_resistance()
	print("Player motor tests: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _test_walk_and_fall() -> void:
	var tuning := PlayerTuning.new()
	var motor := PlayerMotor.new(tuning)
	var command := PlayerCommand.new()
	command.move = Vector2(10.0, 10.0)
	var velocity := Vector3.ZERO
	for tick in 120:
		velocity = motor.step(command, velocity, true, DT)
	check(is_equal_approx(velocity.length(), tuning.walk_speed), "diagonal input is speed bounded")
	command.move = Vector2.ZERO
	for tick in 60:
		velocity = motor.step(command, velocity, true, DT)
	check(velocity.is_zero_approx(), "friction stops movement")
	velocity = motor.step(command, Vector3(0.0, -1.0, 0.0), false, DT)
	check(is_equal_approx(velocity.y, -1.0 - tuning.gravity * tuning.fall_gravity_multiplier * DT), "fall gravity")

func _test_jump_windows() -> void:
	var tuning := PlayerTuning.new()
	var motor := PlayerMotor.new(tuning)
	var idle := PlayerCommand.new()
	var jump := PlayerCommand.new()
	jump.jump_pressed = true
	motor.step(idle, Vector3.ZERO, true, DT)
	var velocity := motor.step(jump, Vector3.ZERO, false, DT)
	check(velocity.y == tuning.jump_velocity, "coyote jump after leaving floor")
	velocity = motor.step(jump, velocity, false, DT)
	check(velocity.y < tuning.jump_velocity, "coyote jump cannot be repeated in air")
	motor = PlayerMotor.new(tuning)
	motor.step(idle, Vector3.ZERO, true, DT)
	for tick in 20:
		motor.step(idle, Vector3.ZERO, false, DT)
	velocity = motor.step(jump, Vector3.ZERO, false, DT)
	check(velocity.y < 0.0, "expired coyote window rejects jump")
	motor = PlayerMotor.new(tuning)
	motor.step(jump, Vector3.ZERO, false, DT)
	velocity = motor.step(idle, Vector3.ZERO, true, DT)
	check(velocity.y == tuning.jump_velocity, "buffered jump fires on landing")
	motor = PlayerMotor.new(tuning)
	motor.step(jump, Vector3.ZERO, false, DT)
	for tick in 20:
		motor.step(idle, Vector3.ZERO, false, DT)
	velocity = motor.step(idle, Vector3.ZERO, true, DT)
	check(velocity.y == 0.0, "expired jump buffer does not fire")

func _test_dash_and_isolation() -> void:
	var tuning := PlayerTuning.new()
	var motor := PlayerMotor.new(tuning)
	var other := PlayerMotor.new(tuning)
	var command := PlayerCommand.new()
	command.dash_pressed = true
	command.dash_direction = Vector2.RIGHT
	motor.step(command, Vector3.ZERO, true, DT)
	check(motor.is_dashing and motor.cooldown_remaining == tuning.dash_cooldown, "dash starts with cooldown")
	check(not other.is_dashing and other.cooldown_remaining == 0.0, "shared tuning does not share runtime state")
	command.dash_pressed = false
	var velocity := motor.step(command, Vector3(0.0, 5.0, 0.0), false, DT)
	check(velocity == Vector3(tuning.dash_speed, 0.0, 0.0), "dash follows direction and freezes height velocity")
	for tick in 12:
		velocity = motor.step(command, velocity, false, DT)
	check(not motor.is_dashing, "dash ends")
	command.dash_pressed = true
	motor.step(command, velocity, true, DT)
	check(not motor.is_dashing, "cooldown rejects early re-entry")
	command.dash_pressed = false
	for tick in 60:
		motor.step(command, Vector3.ZERO, true, DT)
	command.dash_pressed = true
	motor.step(command, Vector3.ZERO, true, DT)
	check(motor.is_dashing, "dash becomes available after cooldown")

func _test_super_dash() -> void:
	var tuning := PlayerTuning.new()
	var motor := PlayerMotor.new(tuning)
	var command := PlayerCommand.new()
	command.dash_pressed = true
	command.dash_held = true
	command.dash_direction = Vector2.LEFT
	motor.step(command, Vector3.ZERO, true, DT)
	check(motor.is_charging_dash and not motor.is_dashing, "held dash begins a charge without spending cooldown")
	command.dash_pressed = false
	for tick in ceili(tuning.super_dash_charge_seconds / DT):
		motor.step(command, Vector3.ZERO, true, DT)
	check(motor.is_dashing and motor.is_super_dashing, "holding dash for 0.66 seconds starts super dash")
	check(is_equal_approx(motor.dash_remaining, tuning.dash_duration * tuning.super_dash_duration_multiplier), "super dash lasts twice as long")
	var velocity := motor.step(command, Vector3(0, 4, 0), false, DT)
	check(velocity == Vector3(-tuning.dash_speed, 0, 0), "super dash preserves dash speed and freezes height")
	motor = PlayerMotor.new(tuning)
	command.dash_pressed = true
	command.dash_held = true
	motor.step(command, Vector3.ZERO, true, DT)
	command.dash_pressed = false
	command.dash_held = false
	motor.step(command, Vector3.ZERO, true, DT)
	check(motor.is_dashing and not motor.is_super_dashing, "releasing before charge starts a normal dash")

func _test_wind_resistance() -> void:
	var wind := WindField.new()
	for tick in 120:
		wind.step(0.15, true, DT)
	check(wind.strength > 0.5, "windy weather builds a sustained gust")
	var headwind := -wind.direction
	var crosswind := Vector2(-wind.direction.y, wind.direction.x)
	check(wind.movement_multiplier(headwind) < 0.75, "walking into wind is meaningfully slower")
	check(wind.movement_multiplier(crosswind) > 0.99, "crosswind preserves ordinary walking speed")
