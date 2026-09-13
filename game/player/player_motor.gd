class_name PlayerMotor
extends RefCounted
## Movement rules only. Caller owns collisions, clock, input, and presentation.

signal jumped
signal dashed

var walk_multiplier: float = 1.0
var is_dashing: bool = false
var dash_remaining: float = 0.0
var cooldown_remaining: float = 0.0
var jump_charge: float = 0.0
var is_charging_jump: bool = false
var _buffered_charge: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _coyote_remaining: float = 0.0
var _jump_buffer_remaining: float = 0.0
var _tuning: PlayerTuning

func _init(tuning: PlayerTuning) -> void:
	_tuning = tuning

func step(command: PlayerCommand, velocity: Vector3, grounded: bool, delta: float) -> Vector3:
	_coyote_remaining = _tuning.coyote_time if grounded else maxf(0.0, _coyote_remaining - delta)
	_jump_buffer_remaining = maxf(0.0, _jump_buffer_remaining - delta)
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	if is_dashing:
		return _step_dash(delta)
	velocity = _step_jump(command, velocity, grounded, delta)
	velocity = _step_walk(command.move, velocity, delta)
	if command.dash_pressed and cooldown_remaining <= 0.0:
		_start_dash(command.dash_direction)
	return velocity

func _step_jump(command: PlayerCommand, velocity: Vector3, grounded: bool, delta: float) -> Vector3:
	if not grounded:
		var gravity := _tuning.gravity * (_tuning.fall_gravity_multiplier if velocity.y < 0.0 else 1.0)
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	if command.jump_pressed:
		_jump_buffer_remaining = _tuning.jump_buffer_time
		_buffered_charge = 0.0
	var eligible := _coyote_remaining > 0.0
	if command.jump_held:
		if eligible and _jump_buffer_remaining > 0.0:
			is_charging_jump = true
			_jump_buffer_remaining = 0.0
		if is_charging_jump:
			jump_charge = minf(1.0, jump_charge + delta / _tuning.jump_charge_seconds)
			if not eligible:
				cancel_jump()
	else:
		if is_charging_jump:
			_buffered_charge = jump_charge
			_jump_buffer_remaining = _tuning.jump_buffer_time
			is_charging_jump = false
			jump_charge = 0.0
		if _jump_buffer_remaining > 0.0 and eligible:
			var height_multiplier := lerpf(1.0, _tuning.super_jump_height_multiplier, _buffered_charge)
			velocity.y = _tuning.jump_velocity * sqrt(height_multiplier)
			cancel_jump()
			_coyote_remaining = 0.0
			jumped.emit()
	return velocity

func cancel_jump() -> void:
	jump_charge = 0.0
	is_charging_jump = false
	_jump_buffer_remaining = 0.0
	_buffered_charge = 0.0

func _step_walk(direction: Vector2, velocity: Vector3, delta: float) -> Vector3:
	var bounded := direction.limit_length()
	var target := Vector3(bounded.x, 0.0, bounded.y) * _tuning.walk_speed * walk_multiplier
	var rate := _tuning.acceleration if bounded.length_squared() > 0.01 else _tuning.friction
	velocity.x = move_toward(velocity.x, target.x, rate * delta)
	velocity.z = move_toward(velocity.z, target.z, rate * delta)
	return velocity

func _start_dash(direction: Vector2) -> void:
	cancel_jump()
	var bounded := direction.normalized() if not direction.is_zero_approx() else Vector2.DOWN
	_dash_direction = Vector3(bounded.x, 0.0, bounded.y)
	is_dashing = true
	dash_remaining = _tuning.dash_duration
	cooldown_remaining = _tuning.dash_cooldown
	dashed.emit()

func _step_dash(delta: float) -> Vector3:
	dash_remaining = maxf(0.0, dash_remaining - delta)
	if dash_remaining <= 0.0:
		is_dashing = false
		return _dash_direction * _tuning.walk_speed * 1.25
	return _dash_direction * _tuning.dash_speed
