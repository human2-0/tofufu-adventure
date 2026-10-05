class_name DungeonLocalModal
extends Node
## Keeps local controls and focus suspended while factory menus are visible.

var dungeon: TofuDungeon
var _source: LocalPlayerInput
var _enabled: bool = true
var _mouse: Input.MouseMode
var _focus: Control
var _owner: CanvasLayer

func attach(quest: TofuDungeon) -> void:
	dungeon = quest
	quest.run_menu.opened.connect(func() -> void: begin(quest.run_menu))
	quest.run_menu.closed.connect(func() -> void: finish(quest.run_menu))
	quest.journal.opened.connect(func() -> void: begin(quest.journal))
	quest.journal.closed.connect(func() -> void: finish(quest.journal))
	quest.game.health.hit.connect(func(_amount: float, _direction: Vector3) -> void: close())
	quest.game.health.depleted.connect(close)

func begin(view: CanvasLayer) -> void:
	if _owner == view: return
	close()
	dungeon.puzzle_views.close()
	_owner = view
	var source: PlayerCommandSource = dungeon.game.player.command_source
	if source is LocalPlayerInput:
		_source = source
		_enabled = _source.enabled
		_source.enabled = false
	_mouse = Input.mouse_mode
	_focus = get_viewport().gui_get_focus_owner()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	dungeon.game.combat.reset()
	dungeon.game.player.motor.cancel_jump()
	dungeon.game.player.motor.cancel_dash_charge()

func finish(view: CanvasLayer) -> void:
	if _owner != view: return
	_owner = null
	if is_instance_valid(_source): _source.enabled = _enabled
	Input.mouse_mode = _mouse
	if is_instance_valid(_focus): _focus.grab_focus()

func close() -> void:
	if _owner == dungeon.run_menu: dungeon.run_menu.close()
	elif _owner == dungeon.journal: dungeon.journal.close()

func _physics_process(_delta: float) -> void:
	if _owner != null and not dungeon.actor_in_run(dungeon.game.player): close()
	if _owner != null and is_instance_valid(_source): _source.enabled = false
