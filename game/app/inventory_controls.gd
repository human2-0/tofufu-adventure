class_name InventoryControls
extends Node
## Local modal input remains active when co-op replaces solo command handling.

var game: Node3D

func _ready() -> void:
	game.inventory_window.opened.connect(_opened)
	game.inventory_window.closed.connect(_closed)

func _input(event: InputEvent) -> void:
	if not game.inventory_window.visible: return
	if event.is_action_pressed("toggle_inventory") or event.is_action_pressed("ui_cancel"):
		if not event.is_echo(): game.inventory_window.close()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed("toggle_inventory"): return
	var source: LocalPlayerInput = game.shooting_view.local_input
	if source == null or not source.enabled or source.chat_blocked or not game.hud.visible: return
	game.inventory_window.open()
	get_viewport().set_input_as_handled()

func _opened() -> void:
	game.shooting_view.local_input.enabled = false
	game.chat.set_menu_open(true)
	game.player.motor.cancel_jump()
	game.combat.reset()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _closed() -> void:
	game.shooting_view.local_input.enabled = true
	game.chat.set_menu_open(false)
