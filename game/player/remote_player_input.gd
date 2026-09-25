class_name RemotePlayerInput
extends PlayerCommandSource
## Receives prevalidated intent. Edges are consumed once; stale held input stops.

var consumed_sequence: int = 0
var pending: Array[PlayerCommand] = []
var _held := PlayerCommand.new()
var _last_received: int = 0
var _overflowed: bool = false
const EDGES: Array[StringName] = [&"jump_pressed", &"dash_pressed", &"drop_pressed", &"pickup_pressed", &"camp_pressed", &"time_pressed", &"use_healing_1", &"use_healing_2", &"use_healing_3", &"use_healing_4"]

func accept(command: PlayerCommand, sequence: int = 0) -> bool:
	if pending.size() >= 12:
		pending.clear()
		_overflowed = true
	command.set_meta("sequence", sequence)
	pending.append(command)
	_last_received = Time.get_ticks_msec()
	return true

func sample(_position: Vector3) -> PlayerCommand:
	if Time.get_ticks_msec() - _last_received > 250:
		pending.clear()
		_overflowed = false
		_held = PlayerCommand.new()
		_held.cancel_actions = true
	if not pending.is_empty():
		var next := _consume_pending()
		_held.move = next.move
		_held.face_aim = next.face_aim
		_held.aim = next.aim
		_held.aim_point = next.aim_point
		_held.dash_direction = next.dash_direction
		_held.dash_held = next.dash_held
		_held.jump_held = next.jump_held
		_held.attack_held = next.attack_held
		_held.guard_held = next.guard_held
		_held.punch_held = next.punch_held
		_held.cancel_actions = next.cancel_actions
		return next
	var command := PlayerCommand.new()
	command.move = _held.move
	command.face_aim = _held.face_aim
	command.aim = _held.aim
	command.aim_point = _held.aim_point
	command.dash_direction = _held.dash_direction
	command.dash_held = _held.dash_held
	command.jump_held = _held.jump_held
	command.attack_held = _held.attack_held
	command.guard_held = _held.guard_held
	command.punch_held = _held.punch_held
	command.cancel_actions = _held.cancel_actions
	return command

func _consume_pending() -> PlayerCommand:
	var next: PlayerCommand = pending.pop_back()
	consumed_sequence = int(next.get_meta("sequence", 0))
	# Commands describe intent, not simulation work to replay on later ticks.
	# Keep the newest held state and deliver queued one-shot actions once.
	for earlier: PlayerCommand in pending:
		if earlier.pickup_pressed and not next.pickup_pressed: next.pickup_id = earlier.pickup_id
		for edge: StringName in EDGES:
			next.set(edge, next.get(edge) or earlier.get(edge))
		if earlier.cancel_actions: next.cancel_actions = true
	if next.weapon_slot == 0:
		for index in range(pending.size() - 1, -1, -1):
			if pending[index].weapon_slot != 0:
				next.weapon_slot = pending[index].weapon_slot
				break
	pending.clear()
	if _overflowed:
		next.cancel_actions = true
		next.weapon_slot = 0
		for edge: StringName in EDGES: next.set(edge, false)
		_overflowed = false
	return next
