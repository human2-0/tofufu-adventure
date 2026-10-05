class_name DungeonPuzzleViewLifecycle
extends RefCounted
## Shared-clock state decides when a local screen must relinquish controls.

static func step(view: DungeonPuzzleViews) -> void:
	if view._active_view.is_empty(): return
	if is_instance_valid(view.actor) and view.actor.command_source is LocalPlayerInput: view.actor.command_source.enabled = false
	if not is_instance_valid(view.actor) or not is_instance_valid(view._anchor) or not is_instance_valid(view.dungeon):
		view.close()
		return
	if view.health == null or view.health.current <= 0.0 or not view.dungeon.actor_in_run(view.actor):
		view.close()
		return
	if view.attempt.phase == TofuPuzzleContract.Phase.COMBAT or view.actor.global_position.distance_to(view._anchor.global_position) > view.INTERACTION_RANGE:
		view.close()
		return
	if view._active_view == "terminal" and view.attempt.lab.formula_unlocked:
		view.show_terminal_feedback("", "Coagulant: Nigari · Use the dosing spout.")
	if view._active_view == "cutter" and view.attempt.cut.completed:
		view.close()
		return
	if view._active_view == "press":
		if view.attempt.stage != TofuPuzzleContract.Stage.PRESS: view.close()
		else: DungeonPressAdapter.present(view)
