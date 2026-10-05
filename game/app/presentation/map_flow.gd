class_name MapFlow
extends Node
## Injects terrain, NPC handles and the current replicated party into map presentation.

var game: Node3D
var roster: CoopRoster
var view := MapView.new()
var expanded: bool = false
var exploration := MapExploration.new()
var _preferences: GamePreferences
var _mask: ImageTexture
var _last_reveal := Vector2.INF
const MAP_PIXELS_PER_UNIT: float = 0.75

func _ready() -> void:
	add_child(view)
	view.mini.bounds = MapExploration.BOUNDS
	view.full.bounds = view.mini.bounds
	view.full.reset_overview()
	_refresh_fog()
	var texture := _terrain_texture()
	view.mini.terrain_texture = texture
	view.full.terrain_texture = texture
	view.toggle_requested.connect(toggle)

func configure_preferences(preferences: GamePreferences) -> void:
	_preferences = preferences
	view.set_mini_zoom(preferences.minimap_zoom)
	view.mini_zoom_changed.connect(_save_zoom)

func _save_zoom(value: float) -> void:
	_preferences.minimap_zoom = value
	if _preferences.save() != OK: game.hud.announce("Map zoom changed / Could not save your preference")

func _process(_delta: float) -> void:
	view.visible = game.hud.visible
	view.expand_button.disabled = not _available()
	view.expand_button.text = "Map [%s] · Expand" % GamePreferences.binding_text("toggle_map", "keyboard")
	var at := _map_position(game.player)
	view.mini.center = at
	var source: LocalPlayerInput = game.shooting_view.local_input
	var direction: Vector2 = source.focus_direction() if is_instance_valid(source) else game.combat.equipment.facing
	if game.shooting_view.shoulder:
		var forward: Vector3 = -game.camera.global_basis.z
		direction = Vector2(forward.x, forward.z).normalized()
	view.mini.heading = direction
	view.full.heading = direction
	if game.hud.visible and at.distance_to(_last_reveal) >= 0.75:
		_last_reveal = at
		if exploration.reveal(at): _refresh_fog()
	view.present(markers())

func markers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for title: String in game.world.map_npcs:
		var npc: Node3D = game.world.map_npcs[title]
		if is_instance_valid(npc) and exploration.visited(_map_position(npc)): result.append(_marker(npc, title, "npc", Color("ffc96c")))
	if game.parrot_travel != null and game.parrot_travel.mounts.parked.has(game.player):
		result.append(_marker(game.parrot_travel.mounts.parked[game.player], "Your parrot", "npc", Color("ff8f79")))
	if is_instance_valid(roster):
		for key: String in roster.actors:
			var actor: Player = roster.actors[key]
			if not is_instance_valid(actor): continue
			var local := key == roster.room.local_key
			result.append(_marker(actor, "You" if local else str(roster.room.names.get(key, "Friend")), "player", Color("fff4d9") if local else Color("79d9ff")))
	else:
		result.append(_marker(game.player, "You", "player", Color("fff4d9")))
	return result

func _marker(actor: Node3D, title: String, kind: String, color: Color) -> Dictionary:
	var at: Vector3 = game.world.to_local(actor.global_position)
	if TofuFactory.contains(at): at = TofuFactory.EAST_ENTRANCE
	return {"point": Vector2(at.x, at.z), "label": title, "kind": kind, "color": color, "local": actor == game.player}

func _map_position(actor: Node3D) -> Vector2:
	var at: Vector3 = game.world.to_local(actor.global_position)
	if TofuFactory.contains(at): at = TofuFactory.EAST_ENTRANCE
	return Vector2(at.x, at.z)

func _refresh_fog() -> void:
	var image := exploration.mask_image()
	if _mask == null: _mask = ImageTexture.create_from_image(image)
	else: _mask.update(image)
	view.mini.fog_texture = _mask
	view.full.fog_texture = _mask

func restore_exploration(value: Variant) -> void:
	exploration.restore(value)
	_last_reveal = Vector2.INF
	_refresh_fog()

func _available() -> bool:
	var source: LocalPlayerInput = game.shooting_view.local_input
	return source != null and source.enabled and not source.chat_blocked and game.hud.visible and not get_tree().paused

func toggle() -> void:
	if expanded:
		close()
	elif _available():
		expanded = true
		view.set_expanded(true)
		game.shooting_view.local_input.enabled = false
		game.chat.set_menu_open(true)
		game.player.motor.cancel_jump()
		game.combat.reset()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close() -> void:
	if not expanded: return
	expanded = false
	view.set_expanded(false)
	game.shooting_view.local_input.enabled = true
	game.chat.set_menu_open(false)

func _input(event: InputEvent) -> void:
	if not expanded: return
	if event.is_action_pressed("toggle_map") or event.is_action_pressed("ui_cancel"):
		if not event.is_echo(): close()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed("toggle_map") or not _available(): return
	toggle()
	get_viewport().set_input_as_handled()

func _terrain_texture() -> Texture2D:
	return MapTerrainImage.build(game.world, MapExploration.BOUNDS, MAP_PIXELS_PER_UNIT)
