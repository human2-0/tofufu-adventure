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
var suspended: bool = false
var command := PlayerCommand.new()
var claw_dash: bool = false
var claw_velocity := Vector3.ZERO

func accept(state: Dictionary) -> void:
	var claw_transition: bool = claw_dash != state.combat.get("claw_dashing", false)
	claw_dash = state.combat.get("claw_dashing", false)
	claw_velocity = CoopValues.vector3(state.velocity)
	if claw_dash:
		actor.motor.is_dashing = false
		actor.motor.is_super_dashing = false
	ActorCombatMotion.equipment(actor, state.combat.get("paws", false))
	var riding := bool(state.get("transport", false))
	var landed := actor.transport_active and not riding
	var boarding := riding and not actor.transport_active
	actor.transport_active = riding
	suspended = riding or float(state.health) <= 0.0 or bool(state.get("spectating", false))
	silence = 0.0
	actor.motor.impact.restore(state.get("impact", {}))
	if actor.motor.impact.remaining > 0.0:
		actor.velocity = CoopValues.vector3(state.velocity)
		actor.motor.cancel_jump()
		actor.motor.cancel_dash_charge()
	var at := CoopValues.vector3(state.position)
	var ack := int(state.get("input_ack", -1))
	var teleported := respawns != int(state.get("respawns", 0))
	respawns = int(state.get("respawns", 0))
	if not initialized or teleported or boarding or landed or claw_transition or actor.position.distance_to(at) > 5.0:
		actor.position = at
		actor.velocity = CoopValues.vector3(state.velocity)
		actor.motor.is_dashing = false
		actor.motor.is_super_dashing = false
		actor.motor.cancel_jump()
		actor.motor.cancel_dash_charge()
		if teleported: actor.motor.impact.clear()
		actor.motor.cooldown_remaining = state.cooldown
		history.clear()
		correction = Vector3.ZERO
		initialized = true
		actor.relocated.emit()
	elif riding:
		actor.velocity = CoopValues.vector3(state.velocity)
		history.clear()
		correction = Vector3.ZERO
	elif history.has(ack):
		correction = at - history[ack]
	elif history.is_empty():
		correction = at - actor.position
	for sequence: int in history.keys():
		if sequence <= ack: history.erase(sequence)

func step(next: PlayerCommand, sequence: int, delta: float) -> void:
	if not initialized or suspended: return
	command = next
	silence += delta
	# A stalled stream must not let an unacknowledged guest roam indefinitely.
	if silence > 0.25 or history.size() >= 120: return
	var adjustment := correction * (1.0 - exp(-18.0 * delta))
	actor.position += adjustment
	for tick: int in history: history[tick] += adjustment
	correction -= adjustment
	var motion := CoopValues.command(CoopValues.input(next, sequence, 0))
	if actor.ability_command.is_valid(): actor.ability_command.call(motion)
	motion.move *= actor.surface_speed
	if actor.movement_modifier.is_valid(): motion.move *= float(actor.movement_modifier.call(motion.move))
	if motion.cancel_actions:
		actor.motor.cancel_jump()
		actor.motor.cancel_dash_charge()
	actor.velocity = actor.motor.step(motion, actor.velocity, actor.is_on_floor(), delta)
	if claw_dash: actor.velocity = claw_velocity
	actor.collision_mask = 1 if actor.motor.is_super_dashing or claw_dash else 3
	actor.move_and_slide()
	history[sequence] = actor.position
