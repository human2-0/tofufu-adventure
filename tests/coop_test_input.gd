class_name CoopTestInput
extends PlayerCommandSource

var move: Vector2 = Vector2.ZERO
var aim_point := Vector3.ZERO
var aim: Vector2 = Vector2.UP
var jump: bool = false
var attack: bool = false
var guard: bool = false
var punch: bool = false
var drop: bool = false
var pickup: bool = false
var pickup_id: int = -1
var slot: int = 0

func sample(_position: Vector3) -> PlayerCommand:
	var command := PlayerCommand.new()
	command.move = move
	command.aim = aim
	command.aim_point = aim_point
	command.dash_direction = aim
	command.jump_held = jump
	command.attack_held = attack
	command.guard_held = guard
	command.punch_held = punch
	command.drop_pressed = drop
	command.pickup_pressed = pickup
	command.pickup_id = pickup_id
	command.weapon_slot = slot
	drop = false
	pickup = false
	slot = 0
	return command
