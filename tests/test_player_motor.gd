extends SceneTree

var failures: int = 0
const DT: float = 1.0 / 60.0

func _initialize() -> void:
	_test_walk_and_fall()
	_test_acceleration_consistency()
	_test_firm_ground_response()
	_test_curved_release()
	_test_jump_windows()
	_test_dash_and_isolation()
	_test_super_dash()
	_test_equipment_mobility()
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

func _test_acceleration_consistency() -> void:
	var tuning := PlayerTuning.new()
	var cardinal := PlayerMotor.new(tuning)
	var diagonal := PlayerMotor.new(tuning)
	var command := PlayerCommand.new()
	command.move = Vector2.RIGHT
	var straight := cardinal.step(command, Vector3.ZERO, true, DT)
	command.move = Vector2.ONE.normalized()
	var angled := diagonal.step(command, Vector3.ZERO, true, DT)
	check(is_equal_approx(straight.length(), angled.length()), "acceleration is consistent in every direction")
	command.move = Vector2.ZERO
	var stopped := diagonal.step(command, Vector3(4, 7, 4), false, DT)
	check(is_equal_approx(Vector2(4, 4).length() - Vector2(stopped.x, stopped.z).length(), tuning.friction * tuning.air_control * DT), "planar braking has a single bounded friction rate")
	check(stopped.y < 7 and stopped.y > 0, "planar acceleration preserves the jump arc")

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

func _test_firm_ground_response() -> void:
	var tuning := PlayerTuning.new()
	for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP, Vector2.ONE.normalized()]:
		var velocity := Vector3.ZERO
		for tick in 6: velocity = PlanarMovement.step(direction, velocity, tuning.walk_speed, true, 1, tuning, DT)
		check(is_equal_approx(Vector2(velocity.x, velocity.z).length(), tuning.walk_speed), "all directions reach walking speed within 100 ms")
	var velocity := Vector3(tuning.walk_speed, 0, 0)
	for tick in 5: velocity = PlanarMovement.step(Vector2.DOWN, velocity, tuning.walk_speed, true, 1, tuning, DT)
	check(absf(velocity.x) < 0.3 and velocity.z > tuning.walk_speed * 0.9, "right-angle turn removes sideways drift within five ticks")
	velocity = Vector3(tuning.walk_speed, 0, 0)
	for tick in 10: velocity = PlanarMovement.step(Vector2.LEFT, velocity, tuning.walk_speed, true, 1, tuning, DT)
	check(is_equal_approx(velocity.x, -tuning.walk_speed), "reversal remains finite and completes promptly")
	var air := PlanarMovement.step(Vector2.RIGHT, Vector3.ZERO, tuning.walk_speed, false, 1, tuning, DT)
	check(is_equal_approx(air.x, tuning.acceleration * tuning.air_control * DT), "ground response does not strengthen airborne steering")

func _test_curved_release() -> void:
	var tuning := PlayerTuning.new()
	var velocity := Vector3(tuning.walk_speed, 7, 0)
	var speeds: Array[float] = [velocity.x]
	var distance := 0.0
	for tick in 12:
		velocity = PlanarMovement.step(Vector2.ZERO, velocity, tuning.walk_speed, true, 1, tuning, DT)
		speeds.append(velocity.x)
		distance += velocity.x * DT
	check(speeds[1] > 0 and speeds[1] < speeds[0], "release retains a short fade instead of an abrupt snap")
	check(speeds[0] - speeds[1] > speeds[3] - speeds[4], "braking eases down toward rest along a curve")
	check(speeds[10] == 0 and distance < 0.25, "ordinary ground walking stops within 167 ms and a quarter metre")
	check(velocity.y == 7, "ground release never rewrites vertical movement")
	var one := PlanarMovement.step(Vector2.ZERO, Vector3(4, 2, 4), tuning.walk_speed, true, 1, tuning, DT)
	var half := PlanarMovement.step(Vector2.ZERO, Vector3(4, 2, 4), tuning.walk_speed, true, 1, tuning, DT * 0.5)
	half = PlanarMovement.step(Vector2.ZERO, half, tuning.walk_speed, true, 1, tuning, DT * 0.5)
	check(one.distance_to(half) < 0.00001, "curved braking is stable across timestep subdivision")
	var restored := PlayerMotor.new(tuning)
	var original := PlayerMotor.new(tuning)
	var walking := PlayerCommand.new()
	walking.move = Vector2.RIGHT
	var midway := Vector3.ZERO
	for tick in 12: midway = original.step(walking, midway, true, DT)
	midway = original.step(PlayerCommand.new(), midway, true, DT)
	check(restored.step(PlayerCommand.new(), midway, true, DT).distance_to(original.step(PlayerCommand.new(), midway, true, DT)) < 0.00001, "mid-release recovery resumes the same curve from stored velocity")
	velocity = PlanarMovement.step(Vector2(0.02, 0), Vector3.ZERO, tuning.walk_speed, true, 1, tuning, DT)
	check(velocity.is_zero_approx(), "sub-deadzone movement cannot create idle drift")

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

func _test_equipment_mobility() -> void:
	var tuning := PlayerTuning.new()
	var motor := PlayerMotor.new(tuning)
	var other := PlayerMotor.new(tuning)
	motor.equipment_walk_multiplier = 1.15
	motor.dash_cooldown_multiplier = 0.75
	motor.dash_cost_multiplier = 0.75
	var costs: Array[float] = []
	motor.spend_stamina = func(cost: float) -> bool: costs.append(cost); return true
	var command := PlayerCommand.new()
	command.move = Vector2.RIGHT
	var velocity := Vector3.ZERO
	for tick in 120: velocity = motor.step(command, velocity, true, DT)
	check(is_equal_approx(velocity.x, tuning.walk_speed * 1.15), "equipment boosts walking speed")
	command.run_held = true
	for tick in 120: velocity = motor.step(command, velocity, true, DT)
	check(is_equal_approx(velocity.x, tuning.run_speed * 1.15), "same equipment bonus boosts running")
	command.dash_pressed = true
	command.dash_direction = Vector2.RIGHT
	motor.step(command, velocity, true, DT)
	check(costs == [11.25] and is_equal_approx(motor.cooldown_remaining, tuning.dash_cooldown * 0.75), "paws reduce dash cost and recovery by one quarter")
	motor.is_dashing = false
	motor._start_dash(Vector2.RIGHT, true)
	check(costs == [11.25, 18.75], "charged movement dash also receives cheaper SP cost")
	check(other.equipment_walk_multiplier == 1.0 and other.dash_cost_multiplier == 1.0 and tuning.dash_cooldown == 0.7, "mobility bonuses cannot mutate shared tuning or another actor")
