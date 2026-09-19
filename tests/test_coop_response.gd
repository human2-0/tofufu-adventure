extends SceneTree
## Delayed JSON transport, local prediction, facing and source-specific hit feedback.

var sessions: Array[CoopSession] = []
var failures: int = 0
var delay: float = 0.04
const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func deliver(room: PlaytestRoom, key: String, data: Dictionary) -> void:
	var copy: Dictionary = JSON.parse_string(JSON.stringify(data))
	if data.type in ["input", "snapshot", "ping", "pong"]:
		create_timer(delay).timeout.connect(func() -> void:
			if is_instance_valid(room): room.receive({"type": "packet", "key": key, "data": copy}))
	else: room.receive({"type": "packet", "key": key, "data": copy})

func ticks(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func _run() -> void:
	var host := PlaytestRoom.new()
	var guest := PlaytestRoom.new()
	root.add_child(host)
	root.add_child(guest)
	host.local_key = HOST
	guest.local_key = GUEST
	host.peers[GUEST] = {"name": "Guest", "hosting": false, "busy": false}
	guest.peers[HOST] = {"name": "Host", "hosting": true, "busy": false}
	host.send_packet = func(_key: String, data: Dictionary) -> void: deliver(guest, HOST, data)
	guest.send_packet = func(_key: String, data: Dictionary) -> void: deliver(host, GUEST, data)
	host.create_room()
	guest.join_room(HOST)
	host.begin()
	for room in [host, guest]:
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		viewport.size = Vector2i(1280, 720)
		root.add_child(viewport)
		var game: Node3D = load("res://game/app/main.tscn").instantiate()
		game.play_opening = false
		viewport.add_child(game)
		var session := CoopSession.new()
		session.game = game
		session.room = room
		game.add_child(session)
		sessions.append(session)
	var input := CoopTestInput.new()
	root.add_child(input)
	sessions[1].roster.local_input = input
	(sessions[0].roster.local_input as LocalPlayerInput).enabled = false
	await ticks(25)
	var remote := sessions[0].roster.party[GUEST]
	var replica := sessions[1].roster.party[GUEST]
	var before := replica.actor.position
	input.move = Vector2.RIGHT
	await ticks(2)
	check(replica.actor.position.x > before.x + 0.005, "guest moves before delayed host response")
	await ticks(25)
	input.move = Vector2.ZERO
	await ticks(35)
	check(replica.actor.position.distance_to(remote.actor.position) < 0.2, "prediction converges after stop with 80ms injected RTT")
	check(replica.prediction.history.size() < 20, "acknowledged movement history stays bounded")
	# Gun equipped without aiming must use travel-relative directional art.
	var game: Node3D = sessions[0].game
	game.camera.set_shoulder(true)
	game.camera.yaw = 0
	game.camera._physics_process(0.016)
	var command := PlayerCommand.new()
	command.aim = Vector2.UP
	command.weapon_slot = 3
	for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
		command.move = direction
		game.player.velocity = Vector3(direction.x, 0, direction.y)
		game._on_command(command, 0.016)
		game.player.visuals.present(command, game.player.velocity, true, false, 0.016)
		var expected := posmod(roundi(direction.angle() / (PI / 4.0)), 8)
		check(game.player.visuals.current_facing == expected, "equipped gun walking selects direction %d" % expected)
	command.attack_held = true
	game._on_command(command, 0.016)
	game.player.visuals.present(command, game.player.velocity, true, false, 0.016)
	check(game.player.visuals.current_facing == FufuVisuals.Facing.UP, "firing retains aim-facing priority")
	command.attack_held = false
	# Real party target lists include others and exclude self, without sharing arrays.
	check(remote.health in game.combat.targets and game.health not in game.combat.targets, "host friendly targets exclude self")
	check(game.health in remote.combat.targets and remote.health not in remote.combat.targets, "guest friendly targets exclude self")
	game.player.velocity = Vector3.ZERO
	game.player.position = Vector3(0, 0.05, 2)
	remote.actor.position = Vector3(0, 0.05, 0.8)
	remote.health.invulnerability = 0
	remote.health.current = 100
	game.combat.gun.selected = false
	game.combat.equipment.knife_selected = true
	game.combat.equipment.facing = Vector2.UP
	await ticks(2)
	game.combat.equipment.facing = Vector2.UP
	game.combat.equipment._punch()
	check(remote.health.current < 100, "fist hits teammate through range and occlusion checks")
	remote.health.invulnerability = 0
	game.combat.attack_aim = Vector2.UP
	var old_health := remote.health.current
	game.combat.reset()
	game.combat.strike(Vector2.UP, 0.0)
	game.combat._sample_sweep(1.0)
	check(remote.health.current < old_health, "knife sweep resolves on teammate")
	await ticks(10)
	var hud: HUD = sessions[1].game.hud
	hud._smear.remaining = 0
	hud._soy_hit.remaining = 0
	remote.health.invulnerability = 0
	remote.health.damage(2, Vector3.BACK, Damageable.HitKind.SOY)
	await ticks(8)
	check(hud._soy_hit.remaining > 0 and hud._smear.remaining == 0, "soybean hit replicates amber effect without slime")
	remote.health.invulnerability = 0
	remote.hurt(2, remote.actor.position + Vector3.BACK)
	await ticks(8)
	check(hud._smear.remaining > 0, "slime hit still replicates smear")
	var invalid := remote.capture()
	invalid.hits = [0, -1, 0]
	check(not ExplorationProtocol.actor(invalid), "negative hit counters are rejected")
	invalid = remote.capture()
	invalid.input_ack = 1.5
	check(not ExplorationProtocol.actor(invalid), "fractional input acknowledgements are rejected")
	# Fatal hits must survive immediate restore even when snapshot HP is unchanged.
	remote.health.invulnerability = 0
	remote.health.damage(999, Vector3.BACK, Damageable.HitKind.SOY)
	await ticks(8)
	check(hud._soy_hit.remaining > 0 and replica.health.current == 100, "fatal soybean event survives health restoration")
	check(replica.actor.position.distance_to(remote.actor.position) < 0.3, "respawn resets prediction history")
	if DisplayServer.get_name() != "headless":
		hud._smear.remaining = 0
		hud._smear._process(0)
		hud._soy_hit.set_process(false)
		hud._soy_hit.splash()
		sessions[1].game.get_viewport().render_target_update_mode = SubViewport.UPDATE_ALWAYS
		await process_frame
		await RenderingServer.frame_post_draw
		sessions[1].game.get_viewport().get_texture().get_image().save_png("/tmp/tofufu-soy-hit.png")
	host.leave()
	await ticks(8)
	for child in root.get_children(): child.queue_free()
	await process_frame
	print("Co-op response: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
