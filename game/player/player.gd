class_name Player
extends CharacterBody3D
## Actor composition: intent -> movement rules -> physics -> presentation.

signal dash_cooldown_updated(current: float, total: float)
signal command_sampled(command: PlayerCommand, delta: float)
signal dashed
signal jump_charge_updated(value: float)

@export var tuning: PlayerTuning = PlayerTuning.new()
@export var command_source: PlayerCommandSource
@onready var visuals: FufuVisuals = $Sprite3D

var surface_speed: float = 1.0
var motor: PlayerMotor
var placement_peers: Array[CharacterBody3D] = []

func _ready() -> void:
	assert(command_source != null, "Player requires a command source")
	motor = PlayerMotor.new(tuning)
	motor.jumped.connect(visuals.show_jump)
	motor.dashed.connect(_on_dashed)

func _physics_process(delta: float) -> void:
	var command := command_source.sample(global_position)
	if command.cancel_actions: motor.cancel_jump()
	command.move *= surface_speed
	velocity = motor.step(command, velocity, is_on_floor(), delta)
	move_and_slide()
	command_sampled.emit(command, delta)
	visuals.present(command, velocity, is_on_floor(), motor.is_dashing, delta, motor.jump_charge, _ground_clearance())
	jump_charge_updated.emit(motor.jump_charge)
	dash_cooldown_updated.emit(motor.cooldown_remaining, tuning.dash_cooldown)

func _on_dashed() -> void:
	visuals.show_dash()
	dashed.emit()

func relocate(desired: Vector3) -> bool:
	return PlayerPlacement.relocate(self, $CollisionShape3D, desired, placement_peers)

func _ground_clearance() -> float:
	if is_on_floor():
		return 0.0
	if velocity.y >= 0.0:
		return INF
	var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.1, global_position + Vector3.DOWN * 3.0, 3, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return maxf(0.0, global_position.y - hit.position.y) if not hit.is_empty() else INF
