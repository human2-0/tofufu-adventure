class_name BattleInputBuffer
extends RefCounted
## Equal minimum delay, bounded queues and one-shot edges for every participant.

var queues: Dictionary = {}
var held: Dictionary = {}
var received: Dictionary = {}
const EDGES: int = 250 | 2048 | 16384 | 32768 | 131072 | 262144 | 524288 | 1048576 # Press edges; remaining flags are holds.

func accept(slot: int, command: Array, now: float) -> void:
	if not queues.has(slot): queues[slot] = []
	var queue: Array = queues[slot]
	if queue.size() >= 8:
		queue.clear()
		command = [0.0, 0.0, command[2], command[3], 256]
	queue.append([now + BattleProtocol.INPUT_DELAY, command.duplicate()])
	received[slot] = now

func sample(slot: int, now: float) -> Array:
	if now - float(received.get(slot, -10.0)) > BattleProtocol.INPUT_TTL:
		queues.erase(slot)
		held.erase(slot)
		return [0.0, 0.0, 0.0, 1.0, 256]
	var queue: Array = queues.get(slot, [])
	var result: Array = held.get(slot, [0.0, 0.0, 0.0, 1.0, 0]).duplicate()
	var edges: int = 0
	while not queue.is_empty() and float(queue[0][0]) <= now:
		result = queue.pop_front()[1]
		edges |= int(result[4]) & EDGES
	result[4] = (int(result[4]) & ~EDGES) | edges
	held[slot] = result.duplicate()
	held[slot][4] = int(result[4]) & ~EDGES
	return result

static func encode(command: PlayerCommand, origin: Vector3 = Vector3.ZERO) -> Array:
	var flags: int = int(command.attack_held) | (int(command.punch_pressed) << 1) | (int(command.jump_held) << 2)
	flags |= int(command.jump_pressed) << 3 | int(command.dash_pressed) << 4 | int(command.pickup_pressed) << 5
	flags |= int(command.use_healing_1) << 6 | int(command.reload_pressed) << 7
	flags |= int(command.cancel_actions) << 8
	flags |= int(command.guard_held) << 9 | int(command.dash_held) << 10 | int(command.attack_pressed) << 11
	flags |= int(command.run_held) << 12 | int(command.reload_held) << 13
	flags |= int(command.punch_held) << 16 | int(command.drop_pressed) << 17
	if command.weapon_slot == 1: flags |= 32768
	elif command.weapon_slot == 2: flags |= 16384
	flags |= int(command.use_healing_2) << 18 | int(command.use_healing_3) << 19 | int(command.use_healing_4) << 20
	var pitch: float = 0
	var reach: float = 38
	var aim := command.aim
	if command.aim_point != Vector3.ZERO and not command.cancel_actions:
		var direction := (command.aim_point - origin - Vector3.UP * 0.65).normalized()
		reach = clampf((command.aim_point - origin - Vector3.UP * 0.65).length(), 0.1, 160)
		aim = Vector2(direction.x, direction.z).normalized()
		pitch = direction.y
	return [snappedf(command.move.x, 0.001), snappedf(command.move.y, 0.001), aim.x, aim.y, flags, pitch, command.weapon_slot, snappedf(reach, 0.001)]

static func decode(data: Array, origin: Vector3 = Vector3.ZERO) -> PlayerCommand:
	var command := PlayerCommand.new()
	command.move = Vector2(data[0], data[1]).limit_length()
	command.aim = Vector2(data[2], data[3]).normalized()
	if command.aim.is_zero_approx(): command.aim = Vector2.DOWN
	command.dash_direction = command.move.normalized() if not command.move.is_zero_approx() else command.aim
	command.run_held = data.size() < 7 or (int(data[4]) & 4096) != 0
	command.face_aim = false # Walking follows travel; held fire and strike poses still face aim.
	var flags := int(data[4])
	command.attack_held = (flags & 1) != 0
	command.punch_pressed = (flags & 2) != 0
	command.jump_held = (flags & 4) != 0
	command.jump_pressed = (flags & 8) != 0
	command.dash_pressed = (flags & 16) != 0
	command.pickup_pressed = (flags & 32) != 0
	command.use_healing_1 = (flags & 64) != 0
	command.reload_pressed = (flags & 128) != 0
	command.cancel_actions = (flags & 256) != 0
	command.guard_held = (flags & 512) != 0
	command.dash_held = (flags & 1024) != 0
	command.attack_pressed = (flags & 2048) != 0
	command.reload_held = (flags & 8192) != 0
	command.punch_held = (flags & 65536) != 0
	command.drop_pressed = (flags & 131072) != 0
	command.use_healing_2 = (flags & 262144) != 0
	command.use_healing_3 = (flags & 524288) != 0
	command.use_healing_4 = (flags & 1048576) != 0
	command.weapon_slot = 1 if flags & 32768 else (2 if flags & 16384 else 0)
	if data.size() >= 6:
		var pitch := float(data[5])
		var planar := sqrt(maxf(0, 1.0 - pitch * pitch))
		var reach := float(data[7]) if data.size() >= 8 else 38.0
		command.aim_point = origin + Vector3.UP * 0.65 + Vector3(command.aim.x * planar, pitch, command.aim.y * planar) * reach
	return command
