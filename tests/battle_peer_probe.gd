extends SceneTree
## Optional real-process Holepunch acceptance; never uses the public DHT by default.
var transport: HolepunchTransport
var room: BattleRoom
var game: BattleRoyaleGame
var directory: String
var label: String
var failed: bool = false
var loot_prepared: bool = false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	directory = OS.get_environment("TOFUFU_BATTLE_PROBE_DIRECTORY")
	label = OS.get_environment("TOFUFU_BATTLE_PROBE_ROLE")
	room = BattleRoom.new()
	if label == "p0" and OS.has_environment("TOFUFU_BATTLE_PROBE_CPUS"):
		room.options = [int(OS.get_environment("TOFUFU_BATTLE_PROBE_CPUS")), int(OS.get_environment("TOFUFU_BATTLE_PROBE_SKILL"))]
	if label == "p0" and OS.get_environment("TOFUFU_BATTLE_PROBE_DUOS") == "1": room.options.append(1)
	room.nickname = label
	room.skin = int(label.substr(1))
	room.target_host = OS.get_environment("TOFUFU_BATTLE_PROBE_HOST")
	room.phase = "connecting"
	room.deadline = 30
	transport = HolepunchTransport.new()
	transport.identity_path = directory.path_join(label + "-identity.key")
	transport.discovery_channel = "tofufu-battle-v1/" + "a".repeat(24)
	room.send_packet = transport.send_packet
	room.send_batch = transport.send_packets
	root.add_child(room)
	root.add_child(transport)
	transport.event_received.connect(func(event: Dictionary) -> void:
		room.receive(event)
		if event.get("type") == "ready" and label == "p0": room.host())
	room.started.connect(func() -> void:
		game = BattleRoyaleGame.new()
		game.room = room
		root.add_child(game))
	room.ended.connect(func(reason: String) -> void:
		failed = true
		printerr("FAIL: real battle peer ended: ", reason))
	transport.start(label)
	while not failed:
		if room.authority() and room.phase == "waiting" and room.members.size() == 3: room.begin()
		var data := {"key": room.local_key, "host": room.host_key, "term": room.term, "phase": room.phase,
			"options": room.options, "checkpoint": room.migration.checkpoint_seq, "time": 0.0, "bodies": 0, "cpus": 0}
		if is_instance_valid(game) and game.composed:
			var deployment := game.match_state.deployment
			if not deployment.is_empty() and int(deployment.stage) == 0 and int(deployment.locked[game.local_slot]) == 0:
				game.deployment.request(floori(game.local_slot / 2.0) if BattleOptions.duos(room.options) else game.local_slot, true)
			if label == "p0" and room.authority() and room.phase == "playing" and not game.deployment.active() and not loot_prepared:
				loot_prepared = true
				_seed_loot()
			data.deployment_stage = int(deployment.get("stage", -1))
			data.plants = deployment.get("choices", [])
			data.time = game.match_state.time
			data.bodies = game.bodies.size()
			data.apples = game.combat.fighters[1].loadout.inventory.count_item("apple")
			data.apple_seconds = game.pack.healing[1].apple_duration_remaining
			data.opened_chests = 0
			data.drop_slots = game.match_state.drops.size()
			if not game.match_state.mobs.is_empty():
				data.mob_count = game.match_state.mobs[0].size()
				data.first_mob_dead = game.match_state.mobs[0][0][9] == 2
				data.hunt_claims = game.match_state.mobs[1][0]
			for chest: Array in game.match_state.chests:
				if chest[4] == 1: data.opened_chests += 1
			for row: Array in game.match_state.rows:
				if row[17] == 1: data.cpus += 1
		var file := FileAccess.open(directory.path_join(label + ".json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(data))
		file.close()
		if FileAccess.file_exists(directory.path_join("finish")): break
		await create_timer(0.1).timeout
	await transport.shutdown()
	quit(1 if failed else 0)

func _seed_loot() -> void:
	# Controlled fixture; guests must receive these items solely through the real wire.
	game.match_state.time = 13
	var fighter := game.combat.fighters[1]
	fighter.loadout.inventory.set_slot(0, ItemStack.new(BattleItems.make(27), 7))
	game.pack.refresh(1)
	game.pack.transactions.consume(1, 0, 0)
	var chest: Array = game.match_state.chests[0]
	game.bodies[0].position = Vector3(chest[1], chest[2], chest[3]) + Vector3(0, 0, 2.4)
	BattleChestLoot.open(game.pack, 0, 0)
	game.mobs.actors[0].target.receive_attack(1000, Vector3.BACK, Damageable.HitKind.SOY, Vector3.INF, game.combat.fighters[0].health)
	game.replication._publish()
	game.recovery.publish()
