class_name InventoryControls
extends Node
## Local modal input remains active when co-op replaces solo command handling.

signal page_requested(character: bool)
var character_open: bool = false
var game: Node3D

func _ready() -> void:
	game.inventory_window.opened.connect(_opened)
	game.inventory_window.closed.connect(_closed)

func _input(event: InputEvent) -> void:
	if not game.inventory_window.visible: return
	var bag := event.is_action_pressed("toggle_inventory")
	var character := event.is_action_pressed("toggle_character")
	if not bag and not character and not event.is_action_pressed("ui_cancel"): return
	if not event.is_echo():
		if event.is_action_pressed("ui_cancel") or character == character_open:
			game.inventory_window.close()
		else:
			page_requested.emit(character)
	get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	var character := event.is_action_pressed("toggle_character")
	if event.is_echo() or not (character or event.is_action_pressed("toggle_inventory")): return
	if game.solo_arena != null and game.solo_arena.active(): return
	var source: LocalPlayerInput = game.shooting_view.local_input
	if source == null or not source.enabled or source.chat_blocked or not game.hud.visible: return
	game.inventory_window.open()
	page_requested.emit(character)
	get_viewport().set_input_as_handled()

func _opened() -> void:
	game.shooting_view.set_inventory_inspection(true)
	game.hud.set_inventory_open(true)
	game.shooting_view.local_input.enabled = false
	game.chat.set_menu_open(true)
	game.player.motor.cancel_jump()
	game.combat.reset()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _closed() -> void:
	game.shooting_view.set_inventory_inspection(false)
	game.hud.set_inventory_open(false)
	game.shooting_view.local_input.enabled = true
	game.chat.set_menu_open(false)
