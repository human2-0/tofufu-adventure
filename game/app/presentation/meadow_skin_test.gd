class_name MeadowSkinTest
extends Node
## Local testing interaction at the meadow study; no save or network schema.

var game: AdventureGame
var display: Fufu3DDisplay
var window := SkinTestWindow.new()
var prompt := Label3D.new()

func _ready() -> void:
	display = game.world.get_node_or_null("Fufu3DDisplay") as Fufu3DDisplay
	game.hud.add_child(window)
	window.skin_selected.connect(select_skin)
	window.closed.connect(_closed)
	game.combat.equipment.child_entered_tree.connect(func(child: Node) -> void:
		if child is PunchImpact and game.player.visuals.test_skin.active(): child.hide())
	if display == null: return
	prompt.position.y = 2.2
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.font_size = 28
	prompt.outline_size = 6
	prompt.pixel_size = 0.008
	prompt.modulate = Color("ffdc79")
	prompt.visibility_range_end = 24.0
	prompt.hide()
	display.add_child(prompt)

func nearby() -> bool:
	if display == null or not is_instance_valid(game.player): return false
	var target := focus_position()
	if game.player.global_position.distance_to(target) > 3.0: return false
	var base := display.get_node("DisplayBody") as StaticBody3D
	var ray := PhysicsRayQueryParameters3D.create(game.player.global_position + Vector3.UP * 0.6, target, 1, [base.get_rid(), game.player.get_rid()])
	return game.player.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func focus_position() -> Vector3:
	return display.global_position + Vector3.UP * 0.8

func available() -> bool:
	var source := game.shooting_view.local_input
	return source != null and source.enabled and not source.chat_blocked and game.hud.visible and not get_tree().paused and not game.inventory_window.visible and not game.map.expanded and (game.solo_arena == null or not game.solo_arena.active()) and nearby()

func _process(_delta: float) -> void:
	if display == null: return
	prompt.visible = available() and game.world_items.focused_kind == "skin_test"
	if prompt.visible:
		prompt.text = tr("[%s] Fufu display · Test character skins") % GamePreferences.binding_text("pickup_weapon", "keyboard")
	if window.visible and (not nearby() or not game.hud.visible or get_tree().paused): window.close()

func _input(event: InputEvent) -> void:
	if not window.visible: return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pickup_weapon") or event.is_action_pressed("toggle_inventory") or event.is_action_pressed("toggle_character"):
		if not event.is_echo(): window.close()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed("pickup_weapon"): return
	if not available() or game.world_items.focused_kind != "skin_test": return
	open()
	get_viewport().set_input_as_handled()

func open() -> void:
	if not available(): return
	if window.buttons.is_empty():
		var choices: Array[Dictionary] = [{"id": "", "name": "Fufu · Original appearance", "icon": null}]
		for index in TofufuTestArt.IDS.size():
			var id: String = TofufuTestArt.IDS[index]
			choices.append({"id": id, "name": TofufuTestArt.NAMES[index], "icon": TofufuTestArt.thumbnail(id)})
		window.configure(choices)
	window.open(game.player.visuals.test_skin.selected)
	game.shooting_view.local_input.enabled = false
	game.chat.set_menu_open(true)
	game.player.motor.cancel_jump()
	game.combat.reset()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func select_skin(id: String) -> void:
	if not window.visible or not nearby(): return
	if game.player.visuals.set_test_skin(id): window.close()

func _closed() -> void:
	game.shooting_view.local_input.enabled = true
	game.chat.set_menu_open(false)
