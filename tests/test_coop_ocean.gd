extends SceneTree
## Host seabed recovery and guest prediction share the same depth-based motor.

var failures: int = 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void: call_deferred("_run")

func ticks(count: int) -> void:
	for i in count: await physics_frame

func _run() -> void:
	var host := PlaytestRoom.new()
	var guest := PlaytestRoom.new()
	root.add_child(host)
	root.add_child(guest)
	var host_key := "a".repeat(64)
	var guest_key := "b".repeat(64)
	host.local_key = host_key
	guest.local_key = guest_key
	host.peers[guest_key] = {"name": "Guest", "hosting": false, "busy": false}
	guest.peers[host_key] = {"name": "Host", "hosting": true, "busy": false}
	host.send_packet = func(_key: String, data: Dictionary) -> void: guest.receive({"type": "packet", "key": host_key, "data": JSON.parse_string(JSON.stringify(data))})
	guest.send_packet = func(_key: String, data: Dictionary) -> void: host.receive({"type": "packet", "key": guest_key, "data": JSON.parse_string(JSON.stringify(data))})
	host.create_room()
	guest.join_room(host_key)
	host.begin()
	var sessions: Array[CoopSession] = []
	for room in [host, guest]:
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		root.add_child(viewport)
		var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
		game.play_opening = false
		viewport.add_child(game)
		game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
		var session := CoopSession.new()
		session.game = game
		session.room = room
		game.add_child(session)
		sessions.append(session)
	var input := CoopTestInput.new()
	root.add_child(input)
	sessions[1].roster.local_input = input
	(sessions[0].roster.local_input as LocalPlayerInput).enabled = false
	await ticks(15)
	var remote: CoopActor = sessions[0].roster.party[guest_key]
	var local: CoopActor = sessions[1].roster.party[guest_key]
	var world: Meadow = sessions[0].game.world
	check(remote.actor.relocate(world.ground_point(0, -145, 0.1)), "host places guest on the reef floor")
	await ticks(15)
	input.move = Vector2.UP
	await ticks(100)
	input.move = Vector2.ZERO
	await ticks(30)
	check(remote.actor.position.z < -147 and remote.actor.position.y < -3.0, "host simulates guest walking below sea level")
	check(remote.actor.motor.immersion == 1 and local.actor.motor.immersion == 1, "guest prediction and authority derive the same immersion")
	check(local.actor.position.distance_to(remote.actor.position) < 0.25, "guest prediction converges underwater")
	var respawns := remote.respawn_count
	var deep := Vector3.ZERO
	for x in range(60, 120):
		var at := world.ground_point(x, -160, 0.1)
		if at.y < -5.3:
			deep = at
			break
	check(deep.y < -5.0 and remote.actor.relocate(deep), "guest reaches a legal seabed below the previous death threshold")
	await ticks(90)
	check(remote.respawn_count == respawns and remote.actor.position.y < -5.0, "host never kills a guest for standing on a deep ocean floor")
	remote.actor.position.y = world.ground_point(remote.actor.position.x, remote.actor.position.z).y - 9.0
	await ticks(10)
	check(remote.respawn_count > respawns and remote.actor.position.z > -84, "genuine fall-through still triggers authoritative recovery")
	var saved := remote.capture()
	saved.position = [0, -4.8, -94]
	remote.restore(saved)
	check(remote.actor.position.y > OceanTerrain.WATER_LEVEL and absf(remote.actor.position.z + 94) < 1.0, "party checkpoints recover old ocean positions onto the new beach")
	host.leave()
	for child in root.get_children(): child.queue_free()
	await process_frame
	print("Co-op ocean: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
