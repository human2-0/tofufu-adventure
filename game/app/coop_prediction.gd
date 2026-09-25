class_name CoopPrediction
extends RefCounted
## Guest-only movement prediction. Host positions correct bounded input history.
## No combat, health, loot or progression outcomes are simulated here.

var actor: Player
var history: Dictionary[int, Vector3] = {}
var correction := Vector3.ZERO
var initialized: bool = false
var silence: float = 0.0
var respawns: int = -1
var command := PlayerCommand.new()

func accept(state: Dictionary) -> void:
	silence = 0.0
	var at := CoopValues.vector3(state.position)
	var ack := int(state.get("input_ack", -1))
	var teleported := respawns != int(state.get("respawns", 0))
	respawns = int(state.get("respawns", 0))
	if not initialized or teleported or actor.position.distance_to(at) > 5.0:
		actor.position = at
		actor.velocity = CoopValues.vector3(state.velocity)
		actor.motor.is_dashing = false
		actor.motor.is_super_dashing = false
		actor.motor.cancel_jump()
		actor.motor.cancel_dash_charge()
		actor.motor.cooldown_remaining = state.cooldown
		history.clear()
		correction = Vector3.ZERO
		initialized = true
	elif history.has(ack):
		correction = at - history[ack]
	elif history.is_empty():
		correction = at - actor.position
	for sequence: int in history.keys():
		if sequence <= ack: history.erase(sequence)

func step(next: PlayerCommand, sequence: int, delta: float) -> void:
	if not initialized: return
	command = next
	silence += delta
	# A stalled stream must not let an unacknowledged guest roam indefinitely.
	if silence > 0.25 or history.size() >= 120: return
	var adjustment := correction * (1.0 - exp(-18.0 * delta))
	actor.position += adjustment
	for tick: int in history: history[tick] += adjustment
	correction -= adjustment
	var motion := CoopValues.command(CoopValues.input(next, sequence, 0))
	motion.move *= actor.surface_speed
	if actor.movement_modifier.is_valid(): motion.move *= float(actor.movement_modifier.call(motion.move))
	if motion.cancel_actions:
		actor.motor.cancel_jump()
		actor.motor.cancel_dash_charge()
	actor.velocity = actor.motor.step(motion, actor.velocity, actor.is_on_floor(), delta)
	actor.collision_mask = 1 if actor.motor.is_super_dashing else 3
	actor.move_and_slide()
	history[sequence] = actor.position
