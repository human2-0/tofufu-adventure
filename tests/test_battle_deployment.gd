extends SceneTree
## Real plant choice, exclusive claims, duo combat/victory and selection-time migration.
var failures: int = 0
var rooms: Array[BattleRoom] = []
var games: Array[BattleRoyaleGame] = []
var host_lost: bool = false

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func _run() -> void:
	_rules()
	await _worlds()
	for game in games: game.get_parent().queue_free()
	for room in rooms: room.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.25).timeout # Retire asynchronous audio playback before engine shutdown.
	print("Battle plant deployment and duos: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _rules() -> void:
	for humans in range(1, 21):
		for cpus in 51:
			var options: Array = [cpus, 1, 1]
			var total := BattleOptions.seats(options, humans)
			check(total % 2 == 0 and total <= 70 and BattleOptions.cpu_count(options, humans) <= 50, "duos have even bounded teams")
	check(not BattleOptions.playable([0, 1, 1], 2), "a single duo cannot start without enemies")
	check(BattleOptions.playable([2, 1, 1], 2), "friends can fight one bot duo")
	for invalid in [[1, 1, 2], [1, 1, true], [1, 1, 1, 1]]: check(not BattleOptions.valid(invalid), "invalid team mode rejected")
	var sites: Array = []
	var positions: Array[Vector3] = []
	for i in 8:
		sites.append([i * 25.0 - 100, 0.08, 0.0])
		positions.append(Vector3(i * 25, 0, 0))
	var solo := BattleDeploymentState.create(sites, 8)
	check(BattleDeploymentState.choose(solo, [6, 1], 0, 3, true), "solo can reserve a plant")
	check(not BattleDeploymentState.choose(solo, [6, 1], 1, 3, false), "another solo cannot share that plant")
	var duo := BattleDeploymentState.create(sites, 8)
	check(BattleDeploymentState.choose(duo, [6, 1, 1], 0, 3, true) and BattleDeploymentState.choose(duo, [6, 1, 1], 1, 3, true), "friends can share a plant")
	check(not BattleDeploymentState.choose(duo, [6, 1, 1], 2, 3, true), "an enemy duo cannot share the plant")
	check(not BattleDeploymentState.choose(duo, [6, 1, 1], 0, 4, true), "confirmed plant cannot be changed")
	BattleDeploymentState.complete(duo, [6, 1, 1])
	check(BattleDeploymentState.valid(duo, 8, [6, 1, 1]), "automatic choices preserve all reservation invariants")
	var wire := {"deployment": duo.duplicate(true)}
	BattleDeploymentWire.compact(wire, false)
	check(not wire.has("deployment") and wire.has("deployment_delta"), "static plant positions are omitted between keyframes")
	check(BattleDeploymentWire.expand(wire, duo) and BattleDeploymentState.valid(wire.deployment, 8, [6, 1, 1]), "plant delta reconstructs reservations and countdown")
	check(not BattleDeploymentWire.expand({"deployment_delta": [[], [], 0, 1]}, duo), "malformed plant delta rejected")
	var bad := duo.duplicate(true)
	bad.choices[2] = 3
	check(not BattleDeploymentState.valid(bad, 8, [6, 1, 1]), "forged enemy duplicate rejected on snapshot/recovery")
	bad = duo.duplicate(true)
	bad.stage = 2
	check(not BattleDeploymentState.valid(bad, 8, [6, 1, 1]), "completed deployment cannot retain a countdown")
	bad = duo.duplicate(true)
	bad.choices[7] = {}
	check(not BattleDeploymentState.valid(bad, 8, [6, 1, 1]), "nested non-numeric choices are rejected before reservation scans")
	var state := BattleMatch.new()
	state.initialize(positions, 2, [6, 1, 1])
	state.time = 13
	state.hit(1, 200, 0)
	check(state.rows[1][8] == 100 and state.rows[1][9] == 50, "friendly damage cannot consume HP or shield")
	state.hit(0, 200, 2, true)
	state.step(0.01)
	check(state.winner == -2 and state.rows[0][13] == 0, "a duo remains in contention after one elimination")
	for i in range(2, 8): state.hit(i, 200, 1, true)
	state.step(0.01)
	check(state.winner == 1 and state.rows[0][13] == 1 and state.rows[1][13] == 1, "surviving partner wins for the whole duo")

func _worlds() -> void:
	for i in 2:
		var room := BattleRoom.new()
		room.local_key = ("a" if i == 0 else "b").repeat(64)
		room.nickname = "Fufu" if i == 0 else "Friend"
		room.send_packet = func(to: String, packet: Dictionary) -> void: _deliver(room.local_key, to, packet)
		rooms.append(room)
		root.add_child(room)
		room.set_process(false)
	for i in 2: rooms[i].receive({"type": "peer", "key": rooms[1-i].local_key, "name": "Friend"})
	rooms[0].host()
	rooms[0].configure([4, 1, 1])
	rooms[1].join(rooms[0].local_key)
	check(rooms[1].options == [4, 1, 1], "guest adopts the authoritative duo option")
	rooms[0].begin()
	for room in rooms:
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		viewport.size = Vector2i(640, 360)
		root.add_child(viewport)
		var game := BattleRoyaleGame.new()
		game.room = room
		viewport.add_child(game)
		games.append(game)
		while not game.composed: await physics_frame
		game.set_physics_process(false)
	var host := games[0]
	var guest := games[1]
	check(host.match_state.deployment.sites.size() >= 70, "map provides enough dry clearings for a maximum roster")
	var original_epoch := host.room.epoch
	var original_deployment := host.match_state.deployment.duplicate(true)
	var minimum_plants := BattleDeploymentState.LIMIT
	for seed in 12:
		host.room.epoch = "%024x" % (seed * 31337 + 7)
		var placed := BattlePlantLayout.populate(host)
		minimum_plants = mini(minimum_plants, host.match_state.deployment.sites.size())
		check(placed and host.match_state.deployment.sites.size() >= 70, "different match seeds retain enough supported plant clearings for seventy actors")
	host.room.epoch = original_epoch
	host.match_state.deployment = original_deployment
	print("Minimum plant sites across twelve seeds: ", minimum_plants)
	var first_site: Array = host.match_state.deployment.sites[0]
	var at := Vector3(first_site[0], first_site[1], first_site[2])
	for view in host.get_children():
		if view is BattlePlantView:
			view._spawn(0, at)
	await physics_frame
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3(-1, 0.15, 0), at + Vector3(1, 0.15, 0), 1)
	check(host.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "streamed plant scenery never adds camera-dependent world collisions")
	await _ticks(0.15)
	check(guest.deployment.panel.visible and guest.deployment.panel.picker.item_count >= 70, "guest receives the actual selectable plants")
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	guest.get_viewport().push_input(escape)
	await process_frame
	guest.deployment.update()
	check(guest.hud.exit_panel.visible and not guest.deployment.panel.visible, "Escape exposes the leave panel above plant selection")
	guest.get_viewport().push_input(escape)
	await process_frame
	guest.deployment.update()
	check(not guest.hud.exit_panel.visible and guest.deployment.panel.visible, "Escape returns to plant selection")
	check(host.match_state.time == 0 and guest.match_state.time == 0, "selection freezes combat and storm clocks")
	host.pack.requests.receive(rooms[1].local_key, {"kind": "br_pack", "epoch": rooms[0].epoch, "term": 0, "seq": 1, "action": 4, "args": [1, 9], "revision": 0})
	check(host.pack.requests.queue.is_empty(), "deployment rejects queued item actions before combat starts")
	for chest: Array in host.match_state.chests:
		for site: Array in host.match_state.deployment.sites:
			check(Vector2(chest[1] - site[0], chest[3] - site[2]).length_squared() >= 25, "chests leave plant exits clear")
	host.deployment.request(0, false)
	guest.deployment.request(0, false)
	await _ticks(0.3)
	check(host.match_state.deployment.choices[0] == 0 and host.match_state.deployment.choices[1] == 0, "both authenticated friends reserve the same plant")
	var before: Array = host.match_state.deployment.choices.duplicate()
	var replay := {"kind": "br_plant", "epoch": rooms[0].epoch, "term": 0, "seq": 1, "plant": 1, "confirm": true}
	host.deployment.receive(rooms[1].local_key, replay)
	replay.seq = 2
	replay.term = 9
	host.deployment.receive(rooms[1].local_key, replay)
	await _ticks(0.2)
	check(host.match_state.deployment.choices == before and host.match_state.deployment.locked[1] == 0, "replayed and old-term plant intents cannot alter claims")
	host.recovery.publish()
	check(not rooms[1].migration.checkpoint.is_empty(), "selection reservations enter a bounded recovery checkpoint")
	TranslationServer.set_locale("pl")
	guest.deployment.update()
	check(guest.deployment.panel.hint.text.contains("Wybierz") and guest.deployment.panel.picker.get_item_text(0).contains("soi"), "live Polish deployment UI")
	TranslationServer.set_locale("en")
	host_lost = true
	rooms[1].receive({"type": "left", "key": rooms[0].local_key})
	check(rooms[1].phase == "recovering" and not guest.playing, "host loss pauses selection")
	var remaining: float = guest.match_state.deployment.remaining
	await _ticks(4.0)
	check(rooms[1].authority() and rooms[1].term == 1 and guest.playing, "friend becomes authority during deployment")
	check(guest.match_state.deployment.choices[0] == 0 and guest.match_state.deployment.choices[1] == 0, "migration retains plant choices and team membership")
	check(guest.match_state.deployment.remaining >= remaining - 2.0 and guest.match_state.time == 0, "recovery does not advance the storm or selection timeout")
	guest.deployment.request(0, true)
	await _ticks(0.2)
	check(guest.match_state.deployment.stage == 1 and guest.match_state.time == 0, "last confirmation begins emergence before combat")
	check(guest.bodies[0].position.distance_to(guest.bodies[1].position) >= 1.0 and guest.bodies[0].position.distance_to(guest.bodies[1].position) < 4.0, "duo emerges at separate collision-safe exits of the shared plant")
	for view in guest.get_children():
		if view is BattlePlantView: view._process(0)
	var skin := guest.bodies[2].visuals.test_skin.selected
	var art := guest.bodies[2].visuals.texture as AtlasTexture
	check(art != null and art.atlas.resource_path.contains("/" + skin + "/"), "emergence applies the selected Tofufu skin before the first movement tick")
	check(guest.camera.global_position.distance_to(guest.bodies[1].global_position + guest.camera.overhead_offset()) < 0.1, "guest camera snaps to the chosen plant before emergence is drawn")
	check(not guest.combat.fighters[0].combat.targets.has(guest.combat.fighters[1].health), "shared adventure weapons omit friendly targets")
	var sp := guest.combat.fighters[1].combat.vitals.current
	check(not guest.combat.receive(80, Vector3.ZERO, Damageable.HitKind.SOY, Vector3.ZERO, guest.combat.fighters[0].health, 1), "emergence blocks damage")
	await _ticks(3.1)
	check(not guest.deployment.active() and guest.match_state.time >= BattleRing.GRACE, "all players enter active combat together after emergence")
	check(not guest.combat.receive(80, Vector3.ZERO, Damageable.HitKind.SOY, Vector3.ZERO, guest.combat.fighters[0].health, 1) and guest.combat.fighters[1].combat.vitals.current == sp, "friendly shots cannot drain guard stamina")
	guest.match_state.rows[1][8] = 0
	guest.presentation.update(0)
	check(guest.presentation.feed.has(1), "fallen partner appears in the feed before the duo is eliminated")
	guest.next_survivor()
	check(guest.watch_slot == 0, "eliminated duo partner spectates their living ally")
	guest.next_survivor()
	check(guest.watch_slot == 0, "spectating cannot scout enemies while your duo is alive")
	guest.match_state.rows[1][8] = 100
	guest.recovery.publish()
	var saved := BattleCheckpoint.decode(rooms[1].migration.checkpoint, rooms[1].members)
	check(not saved.is_empty() and saved.deployment.stage == 2 and saved.options == [4, 1, 1], "completed deployment and duos remain recoverable")
	guest.match_state.deployment = BattleDeploymentState.create(guest.match_state.deployment.sites, guest.bodies.size())
	guest.match_state.deployment.remaining = 0.01
	guest.deployment.step(0.02)
	check(guest.match_state.deployment.stage == 1 and BattleDeploymentState.valid(guest.match_state.deployment, 6, guest.room.options), "timeout assigns safe distinct team plants to unconfirmed players")

func _ticks(seconds: float) -> void:
	for tick in ceili(seconds / 0.05):
		for i in rooms.size():
			if host_lost and i == 0: continue
			rooms[i]._process(0.05)
			games[i]._physics_process(0.05)
		await physics_frame

func _deliver(from: String, to: String, packet: Dictionary) -> void:
	if host_lost and (from == rooms[0].local_key or to == rooms[0].local_key): return
	for room in rooms:
		if room.local_key == to:
			room.receive({"type": "packet", "key": from, "data": JSON.parse_string(JSON.stringify(packet))})
			return
