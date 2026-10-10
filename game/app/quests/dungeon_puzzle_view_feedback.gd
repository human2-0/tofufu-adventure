class_name DungeonPuzzleViewFeedback
extends RefCounted
## Presents host decisions without deriving puzzle success in UI.

static func present(dungeon: TofuDungeon, command: TofuPuzzleCommand, result: Dictionary) -> void:
	if dungeon.puzzle_views == null: return
	var accepted: bool = bool(result.get("accepted", false))
	match command.action:
		TofuPuzzleCommand.Action.OPEN_STASH:
			dungeon.game.hud.announce("Crispy tofu stash opened · 1 Toasted Tofu Chunk" if accepted else "Chest unavailable · Clear the room and check your reach")
		TofuPuzzleCommand.Action.INSPECT:
			if accepted and command.target_id != "shift_note":
				var owner: int = DungeonMembership.actor_id(dungeon, dungeon.game.player)
				dungeon.puzzle_flow.observed["%d:%s" % [owner, command.target_id]] = command.target_id
				dungeon.journal.set_cargo(DungeonInteractionTargets.cargo_name(dungeon, dungeon.game.player))
				dungeon.journal.hint_text = DungeonRunActions.hint(dungeon)
				dungeon.journal.open(TofuPuzzleClues.describe(command.target_id, dungeon.puzzle), false)
		TofuPuzzleCommand.Action.PICK_UP, TofuPuzzleCommand.Action.RETURN_PROP, TofuPuzzleCommand.Action.LOAD_INTAKE, TofuPuzzleCommand.Action.POUR, TofuPuzzleCommand.Action.PLACE_SLAB, TofuPuzzleCommand.Action.SEAL_SLOT:
			if not accepted: dungeon.game.hud.announce("That prop or station is unavailable. Check your carried item and try again.")
			elif dungeon.puzzle.phase == TofuPuzzleContract.Phase.COMBAT: dungeon.game.hud.announce("Batch rejected — item returned to its dock. Clear the defenders before retrying.")
		TofuPuzzleCommand.Action.SUBMIT_PASSWORD:
			if dungeon.puzzle.lab.formula_unlocked:
				dungeon.puzzle_views.show_terminal_feedback("", "Coagulant: Nigari · Use the dosing spout.")
			else:
				dungeon.puzzle_views.show_terminal_feedback("Access not granted. Inspect the shift note.")
		TofuPuzzleCommand.Action.COMMIT_CUTS:
			if accepted and dungeon.puzzle.cut.completed:
				dungeon.puzzle_views.close()
				dungeon.game.hud.announce("Six equal slabs are ready to pack.")
			else:
				dungeon.puzzle_views.show_cutter_feedback("Batch rejected; clear the penalty wave." if accepted else "Invalid guide plan.")
		TofuPuzzleCommand.Action.START_PRESS, TofuPuzzleCommand.Action.PLACE_STONE, TofuPuzzleCommand.Action.RELEASE_PRESS, TofuPuzzleCommand.Action.STOP_PRESS:
			if not accepted:
				dungeon.puzzle_views.show_press_feedback("Action unavailable; check sample, timing and station.")
			elif dungeon.puzzle.stage == TofuPuzzleContract.Stage.CUT:
				dungeon.puzzle_views.close()
			else:
				dungeon.puzzle_views.show_press_feedback("Trial recorded. Watch the vessel or gauge.")
