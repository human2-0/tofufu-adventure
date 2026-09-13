class_name PartyOpeningInput
extends PlayerCommandSource
## During the shared pod quest, any party member may contribute a push or hold.

var sources: Array[PlayerCommandSource] = []

func sample(position: Vector3) -> PlayerCommand:
	var combined := PlayerCommand.new()
	for source in sources:
		var command := source.sample(position)
		if combined.move.is_zero_approx(): combined.move = command.move
		combined.jump_held = combined.jump_held or command.jump_held
	return combined
