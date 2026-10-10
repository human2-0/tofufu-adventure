extends SceneTree
## Real four-actor host or a rendered guest plus co-resident hidden host, JSON wire.
const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
const EXTRA := ["cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc", "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"]

class BenchInput extends PlayerCommandSource:
	var phase: float = 0.0
	var clock: float = 0.0
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		clock += 1.0 / Engine.physics_ticks_per_second
		command.move = Vector2(cos((clock + phase) * 0.8), sin((clock + phase) * 0.8))
		command.aim = command.move
		command.aim_point = _at + Vector3(command.aim.x, 0, command.aim.y) * 20.0
		command.run_held = true
		command.attack_held = sin(clock * 1.6) > 0.6
		return command

class IntentPump extends Node:
	var step: Callable
	func _physics_process(delta: float) -> void: step.call(delta)

var host_room: PlaytestRoom
var guest_room: PlaytestRoom
var host: CoopSession
var guest: CoopSession
var viewport: SubViewport
var view: AdventureGame
var _intent_tick: int = 0
var _sources: Dictionary[String, BenchInput] = {}
var _bytes: int = 0
var _guest_mode: bool = false
var _adaptive: bool = false
var _case_point := Vector2.ZERO
var results: Array[Dictionary] = []

func _initialize() -> void: call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Co-op benchmark requires a rendered window.")
		quit(1)
		return
	_guest_mode = "--guest" in OS.get_cmdline_user_args()
	_adaptive = "--adaptive" in OS.get_cmdline_user_args()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = Vector2i(2560, 1440)
	viewport = preload("res://tests/rendering_viewport.gd").create(root)
	root.gui_disable_input = true
	Engine.max_fps = 0
	RenderingServer.viewport_set_measure_render_time(viewport.get_viewport_rid(), true)
	_rooms()
	var host_parent: Node = viewport
	if _guest_mode:
		var hidden := SubViewport.new()
		hidden.own_world_3d = true
		hidden.render_target_update_mode = SubViewport.UPDATE_DISABLED
		root.add_child(hidden)
		host_parent = hidden
	host = _session(host_parent, host_room)
	if _guest_mode: guest = _session(viewport, guest_room)
	view = guest.game if _guest_mode else host.game
	for key: String in host.roster.party:
		var source := BenchInput.new()
		source.phase = _sources.size() * 1.7
		_sources[key] = source
		host.roster.party[key].loadout.select(2)
		if key == HOST:
			host.game.player.add_child(source)
			host.game.player.command_source = source
	if _guest_mode:
		guest.game.player.add_child(_sources[GUEST])
		guest.roster.local_input = _sources[GUEST]
	var pump := IntentPump.new()
	pump.process_physics_priority = -20
	pump.step = _inputs
	root.add_child(pump)
	for key: String in host_room.members:
		if key != HOST: host_room.receive({"type": "packet", "key": key, "data": {"type": "ready", "epoch": host_room.epoch}})
	if _adaptive:
		var prefs := GamePreferences.new()
		RenderBudget.install(viewport, prefs, func() -> bool: return true)
	print("COOP BENCH device=", RenderingServer.get_video_adapter_name(), " mode=", "guest + hidden host" if _guest_mode else "four-player host", " adaptive=", _adaptive)
	for case in _cases():
		var place: String = case.place
		var at := Vector2(33, -22)
		if place == "grass": at = Vector2(-40, 18)
		if place == "rain_camp": at = FarmCombatGrounds.CAMPS[0]
		if place == "reef": at = Vector2(0, -145)
		if place == "castle": at = Vector2(316, 355)
		_case_point = at
		host.game.weather.set_phase(0.55 if place == "rain_camp" else 0.05)
		host.game.cycle.phase = 0.43
		var index := 0
		for member: CoopActor in host.roster.party.values():
			member.health.restore()
			member.health.invulnerability = 300.0 # Keep the fixture here while enemies still attack.
			member.combat.reset()
			if not member.actor.relocate(host.game.world.ground_point(at.x + (index % 2) * 3, at.y + (index / 2) * 3, 0.1)):
				printerr("FAIL: benchmark relocation failed at ", place, " for ", index)
				quit(1)
				return
			index += 1
		for source in _sources.values(): source.clock = 0.0
		var mode: int = case.camera
		while (2 if view.shooting_view.first_person else (1 if view.shooting_view.shoulder else 0)) != mode:
			view.shooting_view.cycle_mode()
		view.camera.yaw = 0.0
		view.camera.pitch = 0.12
		view.camera.reset_follow()
		await sample(place)
	var path := "/tmp/tofufu-coop-%s-%s.json" % ["guest" if _guest_mode else "host", "adaptive" if _adaptive else "native"]
	if "--perspectives" in OS.get_cmdline_user_args(): path = path.replace(".json", "-perspectives.json")
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(results, "\t"))
	for source: BenchInput in _sources.values():
		if not source.is_inside_tree(): source.free()
	_sources.clear()
	for child in root.get_children(): child.queue_free()
	await process_frame
	await process_frame
	quit()

func _cases() -> Array[Dictionary]:
	var cases: Array[Dictionary] = []
	for place in ["village", "grass", "rain_camp", "reef", "castle"]:
		if "--perspectives" in OS.get_cmdline_user_args():
			for mode in [1, 2]: cases.append({"place": place, "camera": mode})
		else:
			cases.append({"place": place, "camera": 2 if place == "reef" else (1 if place == "grass" else 0)})
	return cases

func _rooms() -> void:
	host_room = PlaytestRoom.new()
	guest_room = PlaytestRoom.new()
	host_room.local_key = HOST
	guest_room.local_key = GUEST
	root.add_child(host_room)
	root.add_child(guest_room)
	host_room.peers[GUEST] = {"name": "Guest", "hosting": false, "busy": false}
	guest_room.peers[HOST] = {"name": "Host", "hosting": true, "busy": false}
	for key: String in EXTRA: host_room.peers[key] = {"name": "Extra " + key.left(1), "hosting": false, "busy": false}
	host_room.send_packet = func(key: String, data: Dictionary) -> void:
		var json := JSON.stringify(data)
		_bytes += json.length()
		if key == GUEST: guest_room.receive({"type": "packet", "key": HOST, "data": JSON.parse_string(json)})
	guest_room.send_packet = func(_key: String, data: Dictionary) -> void:
		host_room.receive({"type": "packet", "key": GUEST, "data": JSON.parse_string(JSON.stringify(data))})
	host_room.create_room()
	guest_room.join_room(HOST)
	for key: String in EXTRA:
		host_room.receive({"type": "packet", "key": key, "data": {"type": "join", "version": PlaytestRoom.GAME_VERSION}})
	host_room.begin()

func _session(parent: Node, room: PlaytestRoom) -> CoopSession:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	parent.add_child(game)
	_block_input(game)
	var session := CoopSession.new()
	session.game = game
	session.room = room
	game.add_child(session)
	return session

func _block_input(node: Node) -> void:
	node.set_process_input(false)
	node.set_process_unhandled_input(false)
	node.set_process_unhandled_key_input(false)
	for child in node.get_children(): _block_input(child)

func _inputs(_delta: float) -> void:
	_intent_tick += 1
	for key: String in _sources:
		if key == HOST or (key == GUEST and _guest_mode): continue
		var command := _sources[key].sample(host.roster.actors[key].position)
		host_room.receive({"type": "packet", "key": key, "data": CoopValues.input(command, _intent_tick, host._sequence).merged({"epoch": host_room.epoch})})

func sample(place: String) -> void:
	for frame in 240: await process_frame
	if not _fixture_valid(place): return
	var times: Array[float] = []
	var last := Time.get_ticks_usec()
	var last_tick := Engine.get_physics_frames()
	var last_camera := view.camera.position
	var last_sprite := view.player.visuals.global_position
	var subtick_changes := 0
	var subtick_sprite_changes := 0
	var scale_min := viewport.scaling_3d_scale
	var bytes_before := _bytes
	var scripts_ms := 0.0
	var physics_ms := 0.0
	var render_ms := 0.0
	for frame in 600:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
		if last_tick == Engine.get_physics_frames() and last_camera.distance_squared_to(view.camera.position) > 0.00000001: subtick_changes += 1
		if last_tick == Engine.get_physics_frames() and last_sprite.distance_squared_to(view.player.visuals.global_position) > 0.00000001: subtick_sprite_changes += 1
		last_tick = Engine.get_physics_frames()
		last_camera = view.camera.position
		last_sprite = view.player.visuals.global_position
		scale_min = minf(scale_min, viewport.scaling_3d_scale)
		scripts_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		render_ms += RenderingServer.viewport_get_measured_render_time_cpu(viewport.get_viewport_rid())
	times.sort()
	if not _fixture_valid(place): return
	var result := {"place": place, "mode": "guest_with_hidden_host" if _guest_mode else "host_four", "adaptive": _adaptive, "median_ms": times[300], "p95_ms": times[570], "p99_ms": times[594], "scale_min": scale_min, "draws": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "triangles": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), "subtick_camera_changes": subtick_changes, "serialized_bytes": _bytes - bytes_before, "frames": 600, "actors": host.roster.party.size(), "guest_ready": guest._synchronized if _guest_mode else true, "skipped_world_views": guest._world_changes.skipped if _guest_mode else 0}
	result.merge(preload("res://tests/rendering_viewport.gd").dimensions(viewport))
	result.merge({"actor_end": CoopValues.array3(view.player.position), "protected_actors": true})
	results.append(result)
	result.merge({"scripts_ms": scripts_ms / 600, "physics_ms": physics_ms / 600, "render_cpu_ms": render_ms / 600, "subtick_sprite_changes": subtick_sprite_changes, "camera_mode": "first_person" if view.camera.first_person else ("shoulder" if view.camera.shoulder else "overhead")})
	print("COOP BENCH ", JSON.stringify(result))
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("/tmp/tofufu-coop-%s-%s-%s.png" % ["guest" if _guest_mode else "host", place, result.camera_mode])

func _fixture_valid(place: String) -> bool:
	for member: CoopActor in host.roster.party.values():
		var at := Vector2(member.actor.position.x, member.actor.position.z)
		if at.distance_to(_case_point) > 35.0:
			printerr("FAIL: benchmark actor left ", place, " at ", member.actor.position)
			quit(1)
			return false
	return true
