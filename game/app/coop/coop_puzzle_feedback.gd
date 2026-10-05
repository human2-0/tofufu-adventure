class_name CoopPuzzleFeedback
extends RefCounted
## Response feedback restores submission controls; snapshots reveal host outcomes.

static func receive(session: CoopSession, data: Dictionary) -> void:
	var sequence: int = int(data.sequence)
	var command: TofuPuzzleCommand = session._pending_puzzle.get(sequence)
	session._pending_puzzle.erase(sequence)
	if command != null:
		DungeonPuzzleViewFeedback.present(session.game.factory_dungeon, command, {"accepted": data.accepted})
	if not data.accepted: session.game.hud.announce("Factory action refused · Check the station and try again")
