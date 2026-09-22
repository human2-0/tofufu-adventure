class_name CoopValues
extends RefCounted
## Composition between primitive protocol values and typed feature commands.

static func vector3(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])

static func array3(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

static func input(command: PlayerCommand, sequence: int, ack: int) -> Dictionary:
	var data := {"type": "input", "sequence": sequence, "ack": ack, "pickup_id": command.pickup_id,
		"move": [command.move.x, command.move.y], "aim": [command.aim.x, command.aim.y],
		"aim_point": array3(command.aim_point), "dash": [command.dash_direction.x, command.dash_direction.y], "weapon_slot": command.weapon_slot}
	for field in ExplorationProtocol.INPUT_FLAGS: data[field] = command.get(field)
	return data

static func command(data: Dictionary) -> PlayerCommand:
	var result := PlayerCommand.new()
	result.move = Vector2(data.move[0], data.move[1])
	result.aim = Vector2(data.aim[0], data.aim[1])
	result.dash_direction = Vector2(data.dash[0], data.dash[1])
	result.aim_point = vector3(data.get("aim_point", [0, 0, 0]))
	result.weapon_slot = int(data.weapon_slot)
	result.pickup_id = int(data.get("pickup_id", -1))
	for field in ExplorationProtocol.INPUT_FLAGS: result.set(field, data[field])
	return result
