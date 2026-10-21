class_name BattleCommandSource
extends PlayerCommandSource
## App-owned battle intent, supplied once on each authoritative physics tick.

var command := PlayerCommand.new()

func sample(_position: Vector3) -> PlayerCommand:
	return command
