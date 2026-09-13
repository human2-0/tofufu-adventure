class_name PlayerCommandSource
extends Node
## Replace through Player.command_source; no transport belongs in the player.

func sample(_world_position: Vector3) -> PlayerCommand:
	return PlayerCommand.new()
