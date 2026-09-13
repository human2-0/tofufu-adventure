extends SceneTree
## A guest completes the host's shared quest; mid-quest checkpoints retain progress.

var host := PlaytestRoom.new()
var guest := PlaytestRoom.new()
var sessions: Array[CoopSession] = []
var source := CoopTestInput.new()
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	root.add_child(host)
	root.add_child(guest)
	root.add_child(source)
	host.local_key = "a".repeat(64)
	guest.local_key = "b".repeat(64)
	host.peers[guest.local_key] = {"name": "Guest", "hosting": false, "busy": false}
	guest.peers[host.local_key] = {"name": "Host", "hosting": true, "busy": false}
	host.send_packet = func(_key: String, data: Dictionary) -> void: guest.receive({"type": "packet", "key": host.local_key, "data": JSON.parse_string(JSON.stringify(data))})
	guest.send_packet = func(_key: String, data: Dictionary) -> void: host.receive({"type": "packet", "key": guest.local_key, "data": JSON.parse_string(JSON.stringify(data))})
	host.create_room()
	guest.join_room(host.local_key)
	host.begin()
	for room in [host, guest]:
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		root.add_child(viewport)
		var game: Node3D = load("res://game/app/main.tscn").instantiate()
		viewport.add_child(game)
		var session := CoopSession.new()
		session.game = game
		session.room = room
		game.add_child(session)
		sessions.append(session)
	(sessions[0].roster.local_input as LocalPlayerInput).enabled = false
	sessions[1].roster.local_input = source
	var rules: PodEscapeRules = sessions[0].game.opening.rules
	await ticks(15)
	var budget := 700
	while rules.stage == PodEscapeRules.Stage.ROCK and budget > 0:
		budget -= 1
		if rules.cue_value() >= 0.40 and rules.cue_value() < 0.53:
			source.move = Vector2(rules.direction, 0)
			await ticks(4)
			source.move = Vector2.ZERO
			await ticks(4)
		else: await ticks(1)
	check(rules.pushes == 4, "guest contributes all four shared pushes")
	await ticks(8)
	check(sessions[1].game.opening.rules.pushes == 4, "guest quest HUD receives host progress")
	var checkpoint := CoopCheckpoint.capture(sessions[0])
	check(CoopCheckpoint.valid(checkpoint), "mid-pod checkpoint valid")
	rules.pushes = 0
	rules.stage = PodEscapeRules.Stage.ROCK
	sessions[0].opening.apply(checkpoint.opening)
	check(rules.pushes == 4 and rules.stage == PodEscapeRules.Stage.SNAP, "mid-pod state restores without restarting")
	source.jump = true
	await ticks(40)
	source.jump = false
	await ticks(65)
	check(rules.stage == PodEscapeRules.Stage.SPLIT, "guest snaps stem and host simulates fall")
	source.jump = true
	await ticks(40)
	source.jump = false
	await ticks(200)
	check(not sessions[0].opening.active() and not sessions[1].opening.active(), "shared quest completes on both peers")
	check(sessions[0].roster.actors[guest.local_key].is_physics_processing(), "host enables guest simulation after quest")
	check(not sessions[1].game.player.is_physics_processing(), "guest remains non-authoritative after reveal")
	check(sessions[0].game.hud.visible and sessions[1].game.hud.visible, "both combat HUDs return")
	check(sessions[0].game.player.command_source == sessions[0].roster.local_input, "ordinary controls restored")
	for child in root.get_children(): child.queue_free()
	await process_frame
	print("Co-op opening: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

func ticks(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame
