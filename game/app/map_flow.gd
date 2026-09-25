class_name MapFlow
extends Node
## Injects terrain, NPC handles and the current replicated party into map presentation.

var game: Node3D
var roster: CoopRoster
var view := MapView.new()
var expanded: bool = false
const MAP_PIXELS_PER_UNIT: float = 1.5

func _ready() -> void:
	add_child(view)
	view.mini.bounds = Rect2(-142, -369, 342, 709)
	view.full.bounds = view.mini.bounds
	var texture := _terrain_texture()
	view.mini.terrain_texture = texture
	view.full.terrain_texture = texture
	view.toggle_requested.connect(toggle)

func _process(_delta: float) -> void:
	view.visible = game.hud.visible
	view.expand_button.disabled = not _available()
	view.expand_button.text = "Map [%s] · Expand" % GamePreferences.binding_text("toggle_map", "keyboard")
	view.present(markers())

func markers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for title: String in game.world.map_npcs:
		var npc: Node3D = game.world.map_npcs[title]
		if is_instance_valid(npc): result.append(_marker(npc, title, "npc", Color("ffc96c")))
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
	return {"point": Vector2(at.x, at.z), "label": title, "kind": kind, "color": color}

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
	var image := Image.create(513, 1064, false, Image.FORMAT_RGB8)
	var terrain: FarmTerrain = game.world.terrain
	for y in 1064:
		for x in 513:
			var at := Vector2(x, y) / MAP_PIXELS_PER_UNIT - Vector2(142, 369)
			var color := Color("8faa78").lerp(Color("c6ca98"), clampf(terrain.height_at(at.x, at.y) / 5.0, 0, 1))
			if terrain.is_field(at.x, at.y): color = Color("b6bd75") if y % 5 < 3 else Color("929d60")
			if terrain.path_distance(at.x, at.y) < 1.1: color = Color("dfcb9b")
			if at.y <= OceanTerrain.NORTH_START:
				if at.y >= FrostTerrain.NORTH_START:
					color = Color("256f86") if absf(at.x) <= OceanTerrain.HALF_WIDTH and at.y >= OceanTerrain.NORTH_END else Color("183e58")
					if OceanTerrain.trail_distance(at.x, at.y) < 1.8: color = Color("6baaa6")
				else:
					color = Color("d9f2f2") if absf(at.x) <= FrostTerrain.HALF_WIDTH and at.y >= FrostTerrain.NORTH_END else Color("7898a7")
					if FrostTerrain.trail_distance(at.x, at.y) < 1.8: color = Color("9cd1dc")
			elif at.y >= DesertTerrain.SOUTH_START:
				if at.y < JungleTerrain.SOUTH_START:
					color = Color("dfad62") if absf(at.x) <= DesertTerrain.HALF_WIDTH and at.y <= DesertTerrain.SOUTH_END else Color("6d533c")
					if DesertTerrain.trail_distance(at.x, at.y) < 1.8: color = Color("f0d18a")
				else:
					color = Color("447851") if absf(at.x) <= JungleTerrain.HALF_WIDTH and at.y <= JungleTerrain.SOUTH_END else Color("294f46")
					if JungleTerrain.trail_distance(at.x, at.y) < 1.8: color = Color("bdac72")
			if at.x > 84 and at.x < 184 and at.y > -44 and at.y < 56:
				color = Color("899b92") if absf(at.y - 6) > 4 else Color("dfcb9b")
			if RiverCourse.bank_distance(at.x, at.y) < 0.0: color = Color("6faab5")
			if at.x > 7 and at.x < 15.4 and absf(at.y - 4) < 1.4: color = Color("b38c62")
			image.set_pixel(x, y, color)
	for building: Node in game.world.get_children():
		if not building.has_meta("map_footprint"): continue
		var footprint: Vector2 = building.get_meta("map_footprint")
		var at: Vector3 = building.position
		var corner := (Vector2(at.x, at.z) - footprint * 0.5 + Vector2(142, 369)) * MAP_PIXELS_PER_UNIT
		image.fill_rect(Rect2i(Vector2i(corner), Vector2i(footprint * 3)), Color("916d60"))
	return ImageTexture.create_from_image(image)
