class_name DungeonPressAdapter
extends RefCounted
## Converts press view controls to bounded command intent.

static func command(view: DungeonPuzzleViews, action_name: String, object_id: String) -> TofuPuzzleCommand:
	if view.attempt == null: return null
	var target: String = "modern_press" if view.press_view.is_modern() else "traditional_press"
	var action: TofuPuzzleCommand.Action
	match action_name:
		"preset": action = TofuPuzzleCommand.Action.SET_PRESS_PRESET
		"start": action = TofuPuzzleCommand.Action.START_PRESS
		"stone": action = TofuPuzzleCommand.Action.PLACE_STONE
		"release": action = TofuPuzzleCommand.Action.RELEASE_PRESS
		"abandon": action = TofuPuzzleCommand.Action.RETURN_PROP
		"stop": action = TofuPuzzleCommand.Action.STOP_PRESS
		_: return null
	return view._command(action, target, object_id, view.attempt.press.revision)

static func present(view: DungeonPuzzleViews) -> void:
	var press: TofuPressRules = view.attempt.press
	var sample: String = "soft" if press.active_sample == TofuPressRules.Sample.SOFT else "firm"
	var owned: bool = press.lease_actor == 0 or press.lease_actor == DungeonMembership.actor_id(view.dungeon, view.actor)
	view.press_view.present_trial(sample, press.stones, press.active_sample >= 0, press.started_at >= 0.0, press.certificates, owned)
	var now: float = view.dungeon.puzzle_clock
	var seconds: float = maxf(0.0, now - view.attempt.press.started_at) if view.attempt.press.started_at >= 0.0 else 0.0
	view.press_view.present(view.attempt.press.stones.size(), seconds, view.attempt.press.gauge(now), "", view.attempt.press.accessible)
