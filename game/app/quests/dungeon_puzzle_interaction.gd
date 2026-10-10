class_name DungeonPuzzleInteraction
extends RefCounted
## Opens views or submits the same focused intent displayed to the local player.

static func perform(dungeon: TofuDungeon, actor: Player) -> bool:
	var target: Dictionary = DungeonInteractionTargets.selected(dungeon, actor)
	if target.is_empty(): return false
	var id: String = target.id
	if actor == dungeon.game.player and dungeon.puzzle_views != null:
		var anchor: Node3D = dungeon.puzzle_flow.anchors.get_anchor(dungeon, id)
		if id == "lab_terminal": return dungeon.puzzle_views.open_terminal(anchor)
		if id == "shift_note": return dungeon.puzzle_views.open_note(anchor)
		if id in ["traditional_press", "modern_press"]: return dungeon.puzzle_views.open_press(anchor, id == "modern_press")
		if id == "cutter": return dungeon.puzzle_views.open_cutter(anchor)
	var action: TofuPuzzleCommand.Action = target.action
	var target_id: String = id
	if id.begins_with("slab_") and action in [TofuPuzzleCommand.Action.PICK_UP, TofuPuzzleCommand.Action.RETURN_PROP]: target_id = ""
	if id.begins_with("package_"): target_id = id.trim_prefix("package_")
	var command := DungeonPuzzleIntent.build(dungeon.puzzle_flow, dungeon, actor, action, target_id, target.object_id)
	var result: Dictionary = dungeon.submit_puzzle(command, actor)
	if not bool(result.get("pending", false)) and actor == dungeon.game.player: DungeonPuzzleViewFeedback.present(dungeon, command, result)
	return bool(result.get("accepted", false))
