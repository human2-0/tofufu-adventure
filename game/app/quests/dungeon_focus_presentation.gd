class_name DungeonFocusPresentation
extends Node
## Describes nearby explicit interactions consistently across input devices.

var dungeon: TofuDungeon
var _view: DungeonInteractionPrompt

func _ready() -> void:
	_view = DungeonInteractionPrompt.new()
	add_child(_view)

func _process(_delta: float) -> void:
	if not dungeon.puzzle_enabled or not dungeon.actor_in_run(dungeon.game.player) or dungeon.game.health.current <= 0.0:
		_view.present("")
		return
	if dungeon.journal.visible or dungeon.run_menu.visible or not dungeon.puzzle_views._active_view.is_empty() or dungeon.puzzle.phase == TofuPuzzleContract.Phase.COMBAT:
		_view.present("")
		return
	var closest: String = ""
	var distance: float = 2.8
	for id: String in _ids():
		var at: Vector3 = TofuFactory.object_position(id)
		var range: float = dungeon.game.player.global_position.distance_to(at)
		if range < distance and dungeon.puzzle_runtime._visible(dungeon.game.player, at):
			closest = id
			distance = range
	var binding: String = GamePreferences.binding_text("pickup_weapon", "controller" if not Input.get_connected_joypads().is_empty() else "keyboard")
	_view.present("%s · %s" % [binding, _caption(closest)] if not closest.is_empty() else "")

func _ids() -> Array[String]:
	var ids: Array[String] = []
	match dungeon.puzzle.stage:
		TofuPuzzleContract.Stage.SORT:
			ids.append_array(TofuPuzzleContract.SACK_IDS)
			ids.append_array(TofuPuzzleContract.INTAKE_IDS)
		TofuPuzzleContract.Stage.LAB:
			ids.assign(["shift_note", "lab_terminal", "coagulation_tank"])
			for index in 20: ids.append("container_%02d" % index)
		TofuPuzzleContract.Stage.PRESS: ids.assign(["traditional_press", "modern_press"])
		TofuPuzzleContract.Stage.CUT: ids.assign(["cutter"])
		TofuPuzzleContract.Stage.PACK:
			for index in 6:
				ids.append("slab_%d" % index)
				ids.append("package_%d" % index)
	return ids

func _caption(id: String) -> String:
	if id == "shift_note": return "Inspect folded paper"
	if id == "lab_terminal": return "Use batch terminal"
	if id == "coagulation_tank": return "Pour into batch" if dungeon.puzzle.lab.carrier_id == DungeonMembership.actor_id(dungeon, dungeon.game.player) else "Inspect tank"
	if id.begins_with("intake_"): return "Inspect / Load intake"
	if id.begins_with("container_"): return "Inspect / Pick up sealed bottle"
	if id.begins_with("sack_"): return "Inspect / Carry sack"
	if id.begins_with("package_"): return "Place slab / Seal package"
	if id.begins_with("slab_"): return "Carry slab"
	return "Use " + id.replace("_", " ")
