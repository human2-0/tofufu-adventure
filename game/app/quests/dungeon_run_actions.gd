class_name DungeonRunActions
extends RefCounted
## Builds the local run-menu intent; the host still validates membership.

static func attach(dungeon: TofuDungeon) -> void:
	dungeon.run_menu = DungeonRunMenu.new()
	dungeon.add_child(dungeon.run_menu)
	dungeon.run_menu.action_requested.connect(func(action: int) -> void: dispatch(dungeon, action))
	dungeon.journal = DungeonRecipeJournal.new()
	dungeon.add_child(dungeon.journal)
	dungeon.journal.binding_text = GamePreferences.binding_text("toggle_inventory", "keyboard") + " / " + GamePreferences.binding_text("toggle_inventory", "controller")
	var modal := DungeonLocalModal.new()
	dungeon.add_child(modal)
	modal.attach(dungeon)
	dungeon.journal.return_requested.connect(func() -> void: return_prop(dungeon))
	var focus := DungeonFocusPresentation.new()
	focus.dungeon = dungeon
	dungeon.add_child(focus)

static func open_menu(dungeon: TofuDungeon) -> void:
	if dungeon.puzzle_enabled and dungeon.actor_in_run(dungeon.game.player):
		dungeon.puzzle_views.close()
		dungeon.run_menu.open(dungeon.puzzle.phase == TofuPuzzleContract.Phase.LOCKED)

static func toggle_journal(dungeon: TofuDungeon) -> void:
	dungeon.puzzle_views.close()
	var text: String = TofuPuzzleClues.BRIEFING
	if dungeon.puzzle.lab.note_found: text += "\n\nShift note: " + TofuPuzzleClues.NOTE
	if dungeon.puzzle.lab.formula_unlocked: text += "\n\nBatch formula: " + TofuPuzzleClues.CHEMICAL_NOTE
	var unlocked: bool = dungeon.rewards.refinery_unlocked(DungeonMembership.key_for(dungeon, dungeon.game.player))
	dungeon.journal.hint_text = hint(dungeon)
	var seen: Array[String] = []
	for identity: Variant in dungeon.puzzle_flow.observed.values():
		if str(identity) in seen: continue
		seen.append(str(identity))
		text += "\n\nInspection: " + TofuPuzzleClues.describe(str(identity), dungeon.puzzle)
	dungeon.journal.toggle(text, unlocked)

static func dispatch(dungeon: TofuDungeon, action: int) -> void:
	if dungeon == null or not dungeon.actor_in_run(dungeon.game.player): return
	if action not in [DungeonRunMenu.ABANDON, DungeonRunMenu.RESTART]: return
	var command := TofuPuzzleCommand.new()
	command.action = TofuPuzzleCommand.Action.ABANDON if action == DungeonRunMenu.ABANDON else TofuPuzzleCommand.Action.RESTART
	command.run_id = dungeon.puzzle.run_id
	command.attempt_id = dungeon.puzzle.attempt_id
	command.sequence = Time.get_ticks_msec() % 2147483000 + 1
	dungeon._puzzle_view_command(command)

static func hint(dungeon: TofuDungeon) -> String:
	match dungeon.puzzle.stage:
		TofuPuzzleContract.Stage.SORT: return "Trace the cold trays, curd filter and wax moulds; compare them with each harvest tag."
		TofuPuzzleContract.Stage.LAB: return "You may try bottles now; wrong ingredients release a penalty wave. Log in for the recipe clue. " + TofuPuzzleClues.TERMINAL_HINT if not dungeon.puzzle.lab.formula_unlocked else "Compare the batch formula with the sealed bottle labels. Other recipes may use different coagulants."
		TofuPuzzleContract.Stage.PRESS: return "Choose a sample, start the station, place keyed stones, then explicitly lift. The modern press uses separate Start and Stop levers. Inspect the texture and calibration cards."
		TofuPuzzleContract.Stage.CUT: return "Move each guide; preview the five cuts. Compare all six widths, including the two end pieces, before committing."
		TofuPuzzleContract.Stage.PACK: return "Carry one slab to an empty dock; place it, then seal that dock."
	return "Watch each attack's windup and use its recovery to approach."

static func return_prop(dungeon: TofuDungeon) -> void:
	var actor_id: int = DungeonMembership.actor_id(dungeon, dungeon.game.player)
	var id: String = ""
	if dungeon.puzzle.stage == TofuPuzzleContract.Stage.SORT:
		for sack: String in dungeon.puzzle.sorting.carried_by:
			if dungeon.puzzle.sorting.carried_by[sack] == actor_id: id = sack
	elif dungeon.puzzle.stage == TofuPuzzleContract.Stage.LAB and dungeon.puzzle.lab.carrier_id == actor_id:
		id = dungeon.puzzle.lab.carried_bottle
	if id.is_empty(): return
	var command: TofuPuzzleCommand = dungeon.puzzle_flow._command(dungeon, dungeon.game.player, TofuPuzzleCommand.Action.RETURN_PROP, id)
	dungeon._puzzle_view_command(command)
	dungeon.journal.close()
