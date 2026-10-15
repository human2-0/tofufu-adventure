extends SceneTree
## Ordered, bandwidth-limited JSON link. Same fixture supports before/after runs.

const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
const EXTRA := ["cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc", "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"]
var sessions: Array[CoopSession] = []
var host_room := PlaytestRoom.new()
var guest_room := PlaytestRoom.new()
var bytes: int = 0
var packets: int = 0
var worlds: int = 0
var queue_until: float = 0.0
var rtts: Array[int] = []
var last_rtt: int = -1
var measuring: bool = false
var failures: int = 0
var unlimited: bool = false
var last_packet: Dictionary = {}
var raw_bytes: int = 0
var compressed: bool = false
var wire_samples: Array[Dictionary] = []

func _initialize() -> void: call_deferred("run")

func deliver(data: Dictionary) -> void:
	var json := JSON.stringify(data)
	var copy: Dictionary = JSON.parse_string(json)
	var network := JSON.stringify({"type": "packet", "data": data}).to_utf8_buffer()
	var size := network.size() + 4
	if compressed and network.size() >= 256:
		# Godot's DEFLATE includes a six-byte zlib wrapper; peers use raw DEFLATE.
		var packed := network.compress(FileAccess.COMPRESSION_DEFLATE)
		var packed_size := JSON.stringify({"type": "__deflate", "payload": Marshalls.raw_to_base64(packed)}).length() + 4
		size = mini(size, packed_size)
	if measuring:
		last_packet = copy
		wire_samples.append(copy)
		raw_bytes += network.size() + 4
		bytes += size
		if data.type in ["snapshot", "snapshot_delta"]:
			packets += 1
			if data.has("world") or data.get("world_tick", false): worlds += 1
	var now := Time.get_ticks_usec() / 1000000.0
	# 1 Mbit/s host upload shared by three recipients, plus 20 ms wire RTT.
	queue_until = maxf(now, queue_until) + (0.0 if unlimited else size * 8.0 * 3.0 / 1000000.0)
	create_timer(queue_until - now + 0.01).timeout.connect(func() -> void:
		if is_instance_valid(guest_room): guest_room.receive({"type": "packet", "key": HOST, "data": copy}))

func run() -> void:
	unlimited = "--unlimited" in OS.get_cmdline_user_args()
	compressed = "--compressed" in OS.get_cmdline_user_args()
	root.add_child(host_room)
	root.add_child(guest_room)
	host_room.local_key = HOST
	guest_room.local_key = GUEST
	host_room.peers[GUEST] = {"name": "Guest", "hosting": false, "busy": false}
	guest_room.peers[HOST] = {"name": "Host", "hosting": true, "busy": false}
	host_room.send_packet = func(key: String, data: Dictionary) -> void:
		if key == GUEST: deliver(data)
	guest_room.send_packet = func(_key: String, data: Dictionary) -> void:
		var copy: Dictionary = JSON.parse_string(JSON.stringify(data))
		create_timer(0.01).timeout.connect(func() -> void:
			if is_instance_valid(host_room): host_room.receive({"type": "packet", "key": GUEST, "data": copy}))
	host_room.create_room()
	for frame in 5: await process_frame
	guest_room.join_room(HOST)
	for frame in 20: await process_frame
	for key: String in EXTRA:
		host_room.peers[key] = {"name": "Extra", "hosting": false, "busy": false}
		host_room.receive({"type": "packet", "key": key, "data": {"type": "join", "version": PlaytestRoom.GAME_VERSION}})
	host_room.begin()
	for frame in 20: await process_frame
	for room in [host_room, guest_room]:
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		viewport.size = Vector2i(1280, 720)
		root.add_child(viewport)
		var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
		game.play_opening = false
		viewport.add_child(game)
		var session := CoopSession.new()
		session.game = game
		session.room = room
		game.add_child(session)
		sessions.append(session)
		if DisplayServer.get_name() != "headless" and room == guest_room:
			var container := SubViewportContainer.new()
			container.size = Vector2(1280, 720)
			root.add_child(container)
			viewport.reparent(container)
		var input := CoopTestInput.new()
		root.add_child(input)
		session.roster.local_input = input
		if room == host_room: game.player.command_source = input
	for key: String in EXTRA:
		host_room.receive({"type": "packet", "key": key, "data": {"type": "ready", "epoch": host_room.epoch}})
	# Many persistent, stationary item stacks amplify repeated-state overhead.
	for index in 80:
		sessions[0].game.world_items.pool.spawn_at("edamame", 10, 100.0, Vector3(20 + index % 10, 0.4, 20 + index / 10))
	for tick in 180:
		await physics_frame
		await process_frame
	measuring = true
	var started := Time.get_ticks_usec()
	for tick in 360:
		await physics_frame
		await process_frame
		var rtt := sessions[1].latency_ms
		if rtt != last_rtt and rtt > 0:
			rtts.append(rtt)
			last_rtt = rtt
	var seconds := (Time.get_ticks_usec() - started) / 1000000.0
	rtts.sort()
	var result := {"seconds": seconds, "unlimited": unlimited, "compressed": compressed, "actors": sessions[0].roster.party.size(), "drops": sessions[0].game.world_items.pool.drops.size(), "actor_hz": packets / seconds, "world_hz": worlds / seconds, "upload_kbit_s": bytes * 8.0 * 3.0 / seconds / 1000.0, "raw_upload_kbit_s": raw_bytes * 8.0 * 3.0 / seconds / 1000.0, "rtt_samples": rtts, "queued_ms": maxf(0, queue_until - Time.get_ticks_usec() / 1000000.0) * 1000, "synchronized": sessions[1]._synchronized}
	print("COOP LATENCY BENCH ", JSON.stringify(result))
	FileAccess.open("/tmp/tofufu-coop-latency.json", FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	FileAccess.open("/tmp/tofufu-coop-latency-packet.json", FileAccess.WRITE).store_string(JSON.stringify(last_packet, "\t"))
	FileAccess.open("/tmp/tofufu-coop-latency-wire.json", FileAccess.WRITE).store_string(JSON.stringify(wire_samples))
	if "--assert" in OS.get_cmdline_user_args():
		if not sessions[1]._synchronized or packets / seconds < 50 or worlds / seconds < 9 or result.queued_ms > 100:
			printerr("FAIL: replication keeps cadence without a growing queue")
			failures += 1
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		sessions[1].game.get_viewport().get_texture().get_image().save_png("/tmp/tofufu-coop-latency.png")
	for child in root.get_children(): child.queue_free()
	await process_frame
	quit(failures)
