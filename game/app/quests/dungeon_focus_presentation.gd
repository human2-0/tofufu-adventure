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
	var target: Dictionary = DungeonInteractionTargets.selected(dungeon, dungeon.game.player)
	var binding: String = GamePreferences.binding_text("pickup_weapon", "controller" if not Input.get_connected_joypads().is_empty() else "keyboard")
	var text: String = "%s · %s" % [binding, target.caption] if not target.is_empty() else ""
	var cargo: String = DungeonInteractionTargets.cargo_name(dungeon, dungeon.game.player)
	if not cargo.is_empty(): text = "Carrying: " + cargo + "\n" + text
	_view.present(text)
