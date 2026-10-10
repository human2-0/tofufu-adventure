class_name Player
extends CharacterBody3D

signal threatened
signal relocated
## Actor composition: intent -> movement rules -> physics -> presentation.

signal dash_cooldown_updated(current: float, total: float)
signal command_sampled(command: PlayerCommand, delta: float)
signal dashed
signal super_dashed(at: Vector3)
signal jump_charge_updated(value: float)

@export var tuning: PlayerTuning = PlayerTuning.new()
@export var command_source: PlayerCommandSource
@onready var visuals: FufuVisuals = $Sprite3D

var transport_active: bool = false
var transport_step: Callable
var parrot_rest := Vector3.INF
var transport_origin := Vector3.ZERO
var surface_speed: float = 1.0
var movement_modifier: Callable
var ability_velocity: Callable
var presentation: ActorPresentation
var motor: PlayerMotor
var placement_peers: Array[CharacterBody3D] = []

func _ready() -> void:
	assert(command_source != null, "Player requires a command source")
	motor = PlayerMotor.new(tuning)
	add_child(PlayerFootsteps.new())
	presentation = ActorPresentation.new()
	presentation.actor = self
	add_child(presentation)
	motor.jumped.connect(visuals.show_jump)
	motor.dashed.connect(_on_dashed)
	motor.super_dashed.connect(_on_super_dashed)

func _physics_process(delta: float) -> void:
	var command := command_source.sample(global_position)
	if transport_active:
		if transport_step.is_valid(): transport_step.call(command, delta)
		command = PlayerCommand.new()
		command.cancel_actions = true
		command_sampled.emit(command, delta)
		visuals.present(command, Vector3.ZERO, true, false, delta, 0.0, 0.0)
		return
	if command.cancel_actions:
		motor.cancel_jump()
		motor.cancel_dash_charge()
	command.move *= surface_speed
	if movement_modifier.is_valid(): command.move *= float(movement_modifier.call(command.move))
	velocity = motor.step(command, velocity, is_on_floor(), delta)
	if ability_velocity.is_valid(): velocity = ability_velocity.call(velocity, is_on_floor(), delta)
	# Super dash remains solid against terrain, but passes through actor bodies.
	collision_mask = 1 if motor.is_super_dashing else 3
	move_and_slide()
	command_sampled.emit(command, delta)
	visuals.present(command, velocity, is_on_floor(), motor.is_dashing, delta, motor.jump_charge, _ground_clearance())
	jump_charge_updated.emit(motor.jump_charge)
	dash_cooldown_updated.emit(motor.cooldown_remaining, tuning.dash_cooldown)

func _on_dashed() -> void:
	visuals.show_dash()
	dashed.emit()

func _on_super_dashed() -> void:
	super_dashed.emit(global_position)

func relocate(desired: Vector3, preserve_transport: bool = false) -> bool:
	var placed := PlayerPlacement.relocate(self, $CollisionShape3D, desired, placement_peers)
	if placed: motor.impact.clear()
	if placed and not preserve_transport: relocated.emit()
	return placed

func _ground_clearance() -> float:
	if is_on_floor():
		return 0.0
	if velocity.y >= 0.0:
		return INF
	var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.1, global_position + Vector3.DOWN * 3.0, 3, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return maxf(0.0, global_position.y - hit.position.y) if not hit.is_empty() else INF

func apply_push(impulse: Vector3) -> void:
	# Replace planar velocity so sustained streams cannot stack without a bound.
	velocity.x = impulse.x
	velocity.z = impulse.z

func apply_melee_hit(impulse: Vector3) -> void:
	motor.impact.receive(impulse)
	motor.cancel_jump()
	motor.cancel_dash_charge()
	velocity.x = motor.impact.push.x
	velocity.z = motor.impact.push.y
	if impulse.y > 0.0: velocity.y = maxf(velocity.y, minf(impulse.y, 8.0))
	elif impulse.y < 0.0: velocity.y = minf(velocity.y, maxf(impulse.y, -8.0))
