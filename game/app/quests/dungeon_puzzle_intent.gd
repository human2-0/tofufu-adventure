class_name DungeonPuzzleIntent
extends RefCounted
## Assigns monotonically increasing local intent and current station revision.

static func build(flow: DungeonPuzzleFlow, dungeon: TofuDungeon, actor: Player, action: TofuPuzzleCommand.Action, target: String, object_id: String = "") -> TofuPuzzleCommand:
	var actor_id: int = DungeonMembership.actor_id(dungeon, actor)
	var previous: int = maxi(int(dungeon.puzzle.sorting.last_sequence.get(str(actor_id), 0)), int(dungeon.puzzle.lab.last_sequence.get(str(actor_id), 0)))
	var sequence: int = maxi(int(flow.sequences.get(actor_id, 0)), previous) + 1
	flow.sequences[actor_id] = sequence
	var command := TofuPuzzleCommand.new()
	command.action = action
	command.target_id = target
	command.object_id = object_id
	command.run_id = dungeon.puzzle.run_id
	command.attempt_id = dungeon.puzzle.attempt_id
	command.sequence = sequence
	match dungeon.puzzle.stage:
		TofuPuzzleContract.Stage.SORT: command.expected_revision = dungeon.puzzle.sorting.revision
		TofuPuzzleContract.Stage.LAB: command.expected_revision = dungeon.puzzle.lab.revision
		TofuPuzzleContract.Stage.PACK: command.expected_revision = dungeon.puzzle.pack.revision
	if actor == dungeon.game.player and dungeon.puzzle_views != null:
		dungeon.puzzle_views.set_sequence_floor(sequence)
	return command
