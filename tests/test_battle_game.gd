extends SceneTree
## Real map, twenty actors, combat collision, CPU movement and isolated teardown.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", label)

func _run() -> void:
	var room := BattleRoom.new()
	root.add_child(room)
	room.practice()
	room.epoch = "0".repeat(24)
	var game := BattleRoyaleGame.new()
	game.room = room
	root.add_child(game)
	while not game.composed: await physics_frame
	BattleTestDeployment.finish(game)
	game.set_physics_process(false)
	check(game.bodies.size() == 20 and game.playing, "offline practice creates twenty ready actors")
	check(game.local_input.get_parent() == game.bodies[0], "local aim source excludes its own capsule")
	check(room.offline and room.phase == "playing", "offline practice needs no networking runtime")
	check(game.world is Meadow and game.world.jungle != null and game.world.dofufu_highlands != null, "existing authored map and biomes are reused")
	check(game.hud.radar.terrain_map != null, "battle radar uses the actual seeded terrain atlas")
	check(game.match_state.chests.size() >= 40 and game.match_state.loot.is_empty(), "spaced random chests replace fixed instant loot")
	var used: Dictionary = {}
	for body: Player in game.bodies: used[body.visuals.test_skin.selected] = true
	check(used.size() == 8, "Fufu and all seven Tofufu variations are represented")
	for slot in 20:
		check(game.match_state.rows[slot][8] == 100 and game.match_state.rows[slot][10] == 2 and game.match_state.rows[slot][22] == 1, "equal match health, gun and knife")
	game.match_state.time = 13
	for slot in 20:
		for other in 20:
			if slot != other: game.bodies[slot].add_collision_exception_with(game.bodies[other])
	var start := game.world.ground_point(-22, -22, 0.1)
	game.bodies[0].position = start
	game.bodies[1].position = start + Vector3(0, 0, 3)
	for slot in range(2, 20): game.bodies[slot].position += Vector3.UP * 30
	await physics_frame
	game.match_state.rows[1][9] = 0
	await _fire(game, 0, game.bodies[1].position + Vector3.UP * 0.65)
	check(game.match_state.rows[1][8] == 82 and game.combat.fighters[0].combat.gun.magazine == 8, "adventure projectile hits real opposing capsule and spends ammo")
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3, 3, 0.4)
	shape.shape = box
	wall.add_child(shape)
	wall.position = start + Vector3(0, 1, 1.5)
	game.add_child(wall)
	await physics_frame
	await _fire(game, 0, game.bodies[1].position + Vector3.UP * 0.65)
	check(game.match_state.rows[1][8] == 82, "world geometry blocks actual battle projectiles")
	wall.queue_free()
	await physics_frame
	game.bodies[1].position.y += 2
	await physics_frame
	await _fire(game, 0, game.bodies[1].position + Vector3.UP * 0.65)
	check(game.match_state.rows[1][8] == 64, "physical shots aim at capsules above the shooter")
	game.bodies[1].position.y -= 2
	for slot in 2:
		game.match_state.rows[slot][8] = 10
		game.match_state.rows[slot][9] = 0
		game.combat.fighters[slot].health.receive_attack(18, Vector3.ZERO, Damageable.HitKind.SOY, Vector3.ZERO, game.combat.fighters[1 - slot].health)
	var commands: Array[PlayerCommand] = []
	commands.resize(20)
	game.combat.step(commands, 1.0 / 60, 0)
	check(game.match_state.rows[0][8] == 0 and game.match_state.rows[1][8] == 0, "same-tick lethal hits resolve together regardless of host order")
	for slot in 2:
		game.match_state.rows[slot][8] = 100
		game.match_state.rows[slot][12] = 0
		game.match_state.rows[slot][13] = 0
	game.match_state.alive = 20
	var before := game.bodies[2].position
	for frame in 60:
		for slot in 20:
			game.simulation.buffer.accept(slot, BattleBot.command(slot, game.match_state), game.simulation.clock)
		game.simulation.step(1.0 / 60)
		await physics_frame
	check(game.bodies[2].position.distance_to(before) > 1, "CPUs drive real movement")
	var packet := game.match_state.capture()
	check(BattleProtocol.snapshot(JSON.parse_string(JSON.stringify(packet))), "real match serializes within bounded wire schema")
	check(JSON.stringify(packet).to_utf8_buffer().size() < 32000, "full twenty-player keyframe fits well below transport limit")
	game.match_state.hit(0, 100, 1, true)
	game.next_survivor()
	check(game.watch_slot != 0 and game.camera.target == game.bodies[game.watch_slot], "eliminated player can spectate a living survivor")
	await _peer_match(game, room)
	game.queue_free()
	room.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.25).timeout # Let asynchronous audio playback retire after freeing actors.
	print("Battle Royale map/gameplay: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _peer_match(host: BattleRoyaleGame, room: BattleRoom) -> void:
	var host_key := "a".repeat(64)
	var guest_key := "b".repeat(64)
	room.options = [18, 1]
	host.match_state.options = room.options.duplicate()
	room.offline = false
	room.local_key = host_key
	room.host_key = host_key
	room.phase = "loading"
	room.members = [{"key": host_key, "name": "Host", "skin": 0}, {"key": guest_key, "name": "Guest", "skin": 3}]
	room.connected = {host_key: true, guest_key: true}
	room.ready_members = {host_key: true}
	room.peers[guest_key] = "Guest"
	host.match_state.rows[1][17] = 0
	var guest_room := BattleRoom.new()
	guest_room.options = room.options.duplicate()
	guest_room.local_key = guest_key
	guest_room.host_key = host_key
	guest_room.target_host = host_key
	guest_room.epoch = room.epoch
	guest_room.members = room.members.duplicate(true)
	guest_room.connected = room.connected.duplicate()
	guest_room.phase = "loading"
	guest_room.deadline = 120
	guest_room.peers[host_key] = "Host"
	root.add_child(guest_room)
	room.send_packet = func(_key: String, packet: Dictionary) -> void:
		guest_room.receive({"type": "packet", "key": host_key, "data": JSON.parse_string(JSON.stringify(packet))})
	guest_room.send_packet = func(_key: String, packet: Dictionary) -> void:
		room.receive({"type": "packet", "key": guest_key, "data": JSON.parse_string(JSON.stringify(packet))})
	var guest := BattleRoyaleGame.new()
	guest.room = guest_room
	var guest_viewport := SubViewport.new()
	guest_viewport.own_world_3d = true
	guest_viewport.size = Vector2i(640, 360)
	root.add_child(guest_viewport)
	guest_viewport.add_child(guest)
	while not guest.composed: await physics_frame
	guest.set_physics_process(false)
	check(room.phase == "playing" and guest.playing, "two actual worlds synchronize readiness")
	check(guest.get_world_3d() != host.get_world_3d(), "peer fixtures use independent collision worlds")
	check(guest.bodies[0].collision_layer == 2 and guest.bodies[0].collision_mask == 0, "guest can aim at replica capsules without running collision outcomes")
	await _guest_shoots_host(host, guest, guest_room, host_key)
	await _guest_inventory(host, guest)
	host.match_state.rows[1][10] = 2
	host.combat.fighters[1].combat.gun.magazine = 3
	host.combat.fighters[1].combat.vitals.current = 37
	host.combat.fighters[1].combat.gun.reload_remaining = 0.9
	host.match_state.cooldowns[1] = 0.27
	host.bodies[1].motor.endurance.current = 37
	host.bodies[1].motor.endurance.rest_remaining = 0.6
	host.bodies[1].motor.cooldown_remaining = 0.45
	host.combat.capture()
	host.replication._publish()
	host.recovery.publish() # Include the deliberately nonzero clocks after the shooting exercise.
	check(guest.replication.snapshot_sequence > 0, "guest accepts first authority keyframe")
	check(_equal_rows(guest.match_state.rows, host.match_state.rows) and _equal_rows(guest.match_state.loot, host.match_state.loot), "twenty actor outcomes and loot cross JSON to guest")
	guest._replicas(1.0 / 60)
	await physics_frame
	var aim_ray := PhysicsRayQueryParameters3D.create(guest.bodies[1].position + Vector3.UP * 0.65, guest.bodies[2].position + Vector3.UP * 0.65, 2, [guest.bodies[1].get_rid()])
	var aimed := guest.get_world_3d().direct_space_state.intersect_ray(aim_ray)
	check(not aimed.is_empty() and aimed.collider is Player and aimed.collider != guest.bodies[1], "guest aim rays hit replica bodies with self excluded")
	var saved_row: Array = guest.match_state.rows[2].duplicate()
	guest.match_state.rows[2][3] = 3.0 # Residual rightward velocity while choosing left.
	guest.match_state.rows[2][5] = 0.0
	guest.match_state.rows[2][20] = -1.0
	guest.match_state.rows[2][21] = 0.0
	guest.presentation.poses[2] = 0
	guest.bodies[2].visuals.attack_facing = Vector2.ZERO # Clear a previous CPU shot while testing travel facing.
	guest._replicas(1.0 / 60)
	var back := Vector3(guest.camera.global_basis.z.x, 0, guest.camera.global_basis.z.z).normalized()
	var screen := Vector2(Vector3.LEFT.dot(guest.camera.global_basis.x), Vector3.LEFT.dot(back))
	check(int(guest.bodies[2].visuals.current_facing) == posmod(roundi(screen.angle() / (PI / 4)), 8), "guest facing follows chosen movement even while momentum or walls change velocity")
	guest.match_state.rows[2] = saved_row
	var first := guest.replication.snapshot_sequence
	host.replication._publish()
	check(guest.replication.snapshot_sequence > first, "actor-only update preserves guest loot baseline")
	var honio_id := BattleHonioSpawn.site(room.epoch, host.mobs.actors.size())
	var honio := host.mobs.actors[honio_id] as HonioMeniono
	honio.target.current = 123
	honio.melee.interrupt_rest = 1.75
	honio.melee.begin(HonioMelee.Skill.PROTEIN_EXPRESS, Vector3.BACK)
	honio.melee.phase = HonioMelee.Phase.RUSH
	honio.melee.remaining = 0.4
	honio._windup = 0
	host.replication._publish()
	var replica_honio := guest.mobs.actors[honio_id] as HonioMeniono
	check(replica_honio != null and guest.mobs.ranged[honio_id] == null, "independent guest composes melee-only Honio from the accepted hunt catalog")
	check(replica_honio.target.current == 123 and replica_honio.melee.phase == HonioMelee.Phase.RUSH and replica_honio.melee.aim == Vector3.BACK, "Honio health and committed rush cross real compressed replication")
	check(not replica_honio.is_physics_processing(), "guest Honio remains cosmetic during an active attack")
	var hunt_shot := host.mobs.ranged[1]
	hunt_shot.aim = Vector3.BACK
	hunt_shot._fire()
	host.replication._publish()
	guest._replicas(0)
	var cosmetic := guest.mobs.ranged[1]
	check(cosmetic._flying() and not cosmetic.projectile.authoritative and not cosmetic.projectile.is_physics_processing(), "NPC fire crosses the real guest world as a cosmetic, manually positioned projectile")
	check(cosmetic.projectile.global_position.distance_to(hunt_shot.projectile.global_position) < 0.002, "guest hunt bolt matches the accepted snapshot position")
	host.mobs.actors[0].target.receive_attack(1000, Vector3.BACK, Damageable.HitKind.SOY, Vector3.INF, host.combat.fighters[0].health)
	host.replication._publish()
	host.recovery.publish() # Pin this committed kill in the migration fixture's checkpoint.
	check(guest.mobs.actors.size() == host.mobs.actors.size() and guest.mobs.actors[0].target.current == 0, "hunt death crosses an ordered compressed delta into the independent guest world")
	check(not guest.mobs.actors[2].target.receive_attack(10, Vector3.ZERO, Damageable.HitKind.SOY, Vector3.INF, guest.combat.fighters[1].health), "guest enemy views reject authoritative damage")
	var next_input := int(host.replication.last_sequences.get(guest_key, 0)) + 1
	var packet := {"kind": "br_input", "epoch": room.epoch, "term": room.term, "seq": next_input, "inputs": [[1, [1.0, 0.0, 0.0, 1.0, 16]]]}
	guest_room.send(host_key, packet)
	check(host.replication.last_sequences.get(guest_key) == next_input, "guest input reaches authenticated authority seat")
	guest_room.receive({"type": "left", "key": host_key})
	check(guest_room.phase == "recovering" and not guest.playing, "actual guest world freezes after authority loss")
	check(guest.hud.radar.gunfire.is_empty(), "host migration immediately clears old gunfire markers")
	var recovery_time := guest.match_state.time
	guest._physics_process(1)
	check(guest.match_state.time == recovery_time and guest.hud.recovery_panel.visible, "storm and input stay frozen under recovery overlay")
	var saved := BattleCheckpoint.decode(guest_room.migration.checkpoint, guest_room.members)
	check(not saved.is_empty(), "real capsules and timers fit resumable checkpoint schema")
	room.set_process(false)
	for i in 100: guest_room._process(0.05)
	check(guest_room.phase == "playing" and guest_room.authority() and guest.playing, "loaded guest world promotes and resumes without rebuilding")
	check(is_equal_approx(guest.match_state.time, float(saved.time)), "promotion restores exact checkpoint storm time")
	check(replica_honio.target.current == 123 and replica_honio.melee.interrupt_rest == 1.75, "real promotion retains Honio health and interrupt cooldown")
	check(replica_honio.melee.phase == HonioMelee.Phase.RECOVERY and replica_honio.melee.remaining >= 1.25 and replica_honio.melee.special_rest == 4.5, "real host migration cancels Honio's rush with vulnerable grace and retained cooldown")
	check(not guest.mobs.ranged[1]._flying() and guest.mobs.ranged[1].rest >= 0.75, "real guest promotion cancels NPC flights and gives attack recovery grace")
	check(guest.mobs.actors[0].target.current == 0 and guest.match_state.mobs[0][0][9] == saved.mobs[0][0][9] and guest.match_state.mobs[1] == saved.mobs[1], "promotion preserves hunt deaths and credits without respawning or rerolling")
	check(is_equal_approx(guest.match_state.reloads[1], float(saved.reloads[1])), "promotion preserves reload progress")
	check(is_equal_approx(guest.bodies[1].motor.endurance.current, float(saved.motors[1][15])), "promotion preserves running reserve")
	check(is_equal_approx(guest.bodies[1].motor.cooldown_remaining, 0.45), "promotion preserves a nonzero dash cooldown")
	check(guest.combat.fighters[1].loadout.inventory.count_item("apple") == 2 and guest.pack.healing[1].apple_duration_remaining > 0, "promotion preserves guest backpack consumption and ongoing healing")
	check(guest.bodies[1].collision_mask == 3 and guest.simulation.buffer.queues.is_empty(), "promotion enables collisions and clears old input edges")
	guest.simulation.step(1.0 / 60)
	guest.replication._fallback_bots()
	check(guest.match_state.rows[0][17] == 1 and guest.match_state.time > float(saved.time), "replacement simulates forward and assigns departed host to CPU")
	guest.match_state.winner = 1
	guest.replication.step(1.0 / 60, PlayerCommand.new())
	check(BattleCheckpoint.decode(guest_room.migration.checkpoint, guest_room.members).get("winner") == 1, "victory immediately publishes a terminal recovery checkpoint")
	guest_viewport.queue_free()
	guest_room.queue_free()
	await process_frame

func _equal_rows(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size(): return false
	for i in actual.size():
		if actual[i].size() != expected[i].size(): return false
		for j in actual[i].size():
			if absf(float(actual[i][j]) - float(expected[i][j])) > 0.00001: return false
	return true

func _fire(game: BattleRoyaleGame, slot: int, point: Vector3) -> void:
	var fighter := game.combat.fighters[slot]
	fighter.combat.gun.cooldown = 0
	fighter.combat.gun.spread_multiplier = 0
	var command := PlayerCommand.new()
	command.attack_held = true
	command.aim = Vector2(point.x - game.bodies[slot].position.x, point.z - game.bodies[slot].position.z).normalized()
	command.aim_point = point
	fighter.step(command, 1.0 / 60)
	for frame in 8:
		await physics_frame
		var commands: Array[PlayerCommand] = []
		commands.resize(20)
		game.combat.step(commands, 1.0 / 60, 0)
	game.combat.capture()

func _guest_shoots_host(host: BattleRoyaleGame, guest: BattleRoyaleGame, guest_room: BattleRoom, host_key: String) -> void:
	for healing in host.pack.healing:
		healing.active_heal_remaining = 0
		healing.apple_duration_remaining = 0
		healing.cooldown_remaining = 0
	for other in host.combat.fighters: other.clear_flights()
	host.combat.pending.clear()
	host.combat.pending_pushes.clear()
	var start := host.world.ground_point(-22, -22, 0.1)
	for slot in 2:
		host.bodies[slot].position = start + Vector3(0, 0, slot * 4)
		host.bodies[slot].velocity = Vector3.ZERO
		host.bodies[slot].collision_layer = 2
		host.bodies[slot].motor.is_dashing = false
		host.bodies[slot].motor.impact.clear()
		host.match_state.rows[slot][8] = 100
		host.match_state.rows[slot][9] = 0
		host.match_state.rows[slot][13] = 0
		host.match_state.rows[slot][10] = 2
		host.match_state.rows[slot][22] = 1
		host.match_state.rows[slot][23] = 2
		host.combat.fighters[slot].equip(host.match_state.rows[slot])
	host.match_state.alive = 20
	host.simulation.buffer = BattleInputBuffer.new()

	var fighter := host.combat.fighters[1]
	fighter.combat.gun.reset()
	fighter.combat.gun.magazine = 9
	fighter.combat.gun.reload_remaining = 0
	fighter.combat.gun.cooldown = 0
	fighter.combat.gun.spread_multiplier = 0
	var command := PlayerCommand.new()
	command.attack_held = true
	command.aim_point = host.bodies[0].position + Vector3.UP * 0.65
	var encoded := BattleInputBuffer.encode(command, host.bodies[1].position)
	guest_room.send(host_key, {"kind": "br_input", "epoch": guest_room.epoch, "term": guest_room.term, "seq": int(host.replication.last_sequences.get(guest_room.local_key, 0)) + 1, "inputs": [[1, encoded]]})
	for frame in 18:
		host.simulation.step(1.0 / 60)
		host.replication._publish()
		guest._replicas(1.0 / 60)
		await physics_frame
	check(host.match_state.rows[0][8] == 82 and fighter.combat.gun.magazine == 8, "guest intent over JSON fires an actual projectile into the host with normal ammo cost")
	check(guest.match_state.rows[0][8] == host.match_state.rows[0][8] and guest.match_state.rows[1][11] == 8, "guest receives authoritative damage and ammunition through compact combat deltas")
	host.simulation.buffer = BattleInputBuffer.new()
	# A new host shot crosses the same accepted combat delta used for guest effects.
	host.watch_slot = host.local_slot # This fixture revived the host after exercising spectating.
	host.presentation.gunfire.reset()
	guest.presentation.gunfire.reset()
	var gun := host.combat.fighters[0].combat.gun
	gun.cooldown = 0
	gun.reload_remaining = 0
	gun.step(true, false, Vector2.UP, start + Vector3(0, 1, -20), 1.0 / 60)
	host.presentation.gunfire.update(0)
	host.replication._publish()
	guest.presentation.gunfire.update(0)
	check(host.hud.radar.gunfire.is_empty(), "host never reveals its own shot")
	check(guest.hud.radar.gunfire.size() == 1, "nearby enemy fire crosses a real accepted JSON delta to the guest radar")
	var origin := gun.shot_origin
	if not guest.hud.radar.gunfire.is_empty():
		var marker: Vector3 = guest.hud.radar.gunfire[0]
		check(Vector2(marker.x, marker.y).distance_to(Vector2(origin.x, origin.z)) < 0.002, "guest marker keeps the authoritative muzzle position")

func _guest_inventory(host: BattleRoyaleGame, guest: BattleRoyaleGame) -> void:
	var bag := host.combat.fighters[1].loadout.inventory
	bag.set_slot(0, ItemStack.new(BattleItems.make(27), 3))
	host.pack.refresh(1)
	host.replication._publish()
	check(guest.combat.fighters[1].loadout.inventory.count_item("apple") == 3, "guest receives temporary bag through indexed world changes")
	guest.pack.requests.request(3, [0, 0])
	check(bag.count_item("apple") == 3, "guest inventory action waits for equal host delay")
	host.pack.requests.flush(host.simulation.clock + 0.101, 0)
	host.replication._publish()
	check(bag.count_item("apple") == 2 and guest.combat.fighters[1].loadout.inventory.count_item("apple") == 2, "authenticated guest consumes exactly one real backpack item")
	check(guest.pack.healing[1].apple_duration_remaining == 25, "guest receives authoritative ongoing food effect")
	for i in 4:
		bag.set_slot(i + 1, ItemStack.new(BattleItems.make(20 + i), 1))
		check(host.pack.transactions.transfer(1, 0, i + 1, 1, i), "guest fixture can equip found Celestial pieces")
	host.replication._publish()
	check(guest.combat.fighters[1].loadout.equipment.complete_set() == "celestial" and is_equal_approx(guest.combat.fighters[1].health.armor_multiplier, 0.75), "guest receives worn sets and capped protection")
	check(guest.bodies[1].visuals.test_skin.active() and guest.bodies[1].visuals.celestial_aura.visible, "replica refresh retains embedded Tofufu art and its match set aura")
