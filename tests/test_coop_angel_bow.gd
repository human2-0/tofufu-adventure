extends SceneTree
## Real local host/guest sessions with JSON messages and authority-only outcomes.

const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
var failures: int = 0
var sessions: Array[CoopSession] = []

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for index in count:
		await physics_frame
		await process_frame

func _run() -> void:
	Engine.max_physics_steps_per_frame = 1
	var host := PlaytestRoom.new()
	var guest := PlaytestRoom.new()
	root.add_child(host)
	root.add_child(guest)
	host.local_key = HOST
	guest.local_key = GUEST
	host.peers[GUEST] = {"name": "Guest", "hosting": false, "busy": false}
	guest.peers[HOST] = {"name": "Host", "hosting": true, "busy": false}
	host.send_packet = func(_key: String, data: Dictionary) -> void: guest.receive({"type": "packet", "key": HOST, "data": JSON.parse_string(JSON.stringify(data))})
	guest.send_packet = func(_key: String, data: Dictionary) -> void: host.receive({"type": "packet", "key": GUEST, "data": JSON.parse_string(JSON.stringify(data))})
	host.create_room()
	guest.join_room(HOST)
	host.begin()
	for room in [host, guest]:
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		root.add_child(viewport)
		var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
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
	await ticks(15)
	check(sessions[1]._synchronized, "guest accepts version-62 snapshots")
	for session in sessions:
		for mob in session.game.encounters.mob_nodes: mob.set_physics_process(false)
	var game := sessions[0].game
	var remote: CoopActor = sessions[0].roster.party[GUEST]
	var owner: CoopActor = sessions[0].roster.party[HOST]
	var replica: CoopActor = sessions[1].roster.party[GUEST]
	check(AngelBowItem.ID in MerchantLocations.stock(game.world, game.world.weapon_merchant) and AngelBowItem.ID in MerchantLocations.stock(game.world, game.world.cloud_realm.court.merchant), "both merchants stock the testing bow")
	check(WeaponTrade.purchase(remote.inventory, AngelBowItem.ID).begins_with("Bought") and remote.inventory.count_item(AngelBowItem.ID) == 1, "bow purchases for zero currency")
	var stack := ItemStack.new(AngelBowItem.create(), 1)
	stack.enhanced = true
	remote.character_equipment.set_slot("combat_2", stack)
	remote.loadout.select(2)
	owner.progression.progress.award_experience(CharacterProgress.threshold(20, true))
	owner.health.current = owner.health.maximum
	owner.actor.position = Vector3(0, 0.1, 2)
	remote.actor.position = Vector3(0, 0.1, -2)
	owner.actor.velocity = Vector3.ZERO
	remote.actor.velocity = Vector3.ZERO
	owner.health.invulnerability = 0
	await ticks(15)
	check(replica.combat.bow.selected and replica.character_equipment.get_slot("combat_2").enhanced, "guest receives equipped enhanced bow")
	input.aim = Vector2.DOWN
	input.aim_point = owner.actor.position + Vector3.UP * 0.6
	input.attack = true
	var hp := owner.health.current
	await ticks(16)
	input.attack = false
	check(owner.health.current < hp and remote.combat.bow.sequence == 1, "authenticated guest arrow damages host exactly once before reload")
	check(remote.combat.bow.reload_remaining > 1.5 and remote.combat.gun.magazine_capacity == 9, "enhanced bow retains one-arrow reload instead of gun magazine bonuses")
	await ticks(10)
	check(is_equal_approx(sessions[1].roster.party[HOST].health.current, owner.health.current), "host arrow damage replicates without extra client damage")
	check(replica.combat.bow.sequence == 1 and replica.combat.replica_view, "guest sees sequenced cosmetic flight")
	await ticks(110)
	owner.health.current = owner.health.maximum
	owner.health.invulnerability = 0
	owner.actor.velocity = Vector3.ZERO
	owner.actor.position = Vector3(0, 0.1, 2)
	var nearby := PracticeDummy.new()
	nearby.maximum_health = 1000
	game.add_child(nearby)
	nearby.position = Vector3(2, 0.1, 2)
	remote.combat.targets.append(nearby.target)
	remote.combat.vitals.current = 100
	input.guard = true
	hp = owner.health.current
	for index in 72:
		input.aim_point = owner.actor.position + Vector3.UP * 0.6
		await ticks(1)
	check(remote.combat.bow.sequence == 1 and owner.health.current == hp, "guest partial charge cannot deal early damage")
	for index in 24:
		input.aim_point = owner.actor.position + Vector3.UP * 0.6
		await ticks(1)
	input.guard = false
	await ticks(8)
	check(remote.combat.bow.sequence == 2 and remote.combat.bow.burst_sequence == 1, "guest skill produces one host arrow and one host flame sphere")
	check(owner.health.current < hp and is_equal_approx(nearby.target.current, 940), "enhanced charged arrow and nearby 60-damage pulse are host-owned")
	check(replica.combat.bow.burst_sequence == 1 and replica.combat.bow.cooldown > 5, "flame impact and cooldown replicate to guest")
	check(remote.combat.vitals.current < 90 and absf(replica.combat.vitals.current - remote.combat.vitals.current) < 1.0, "stamina payment is authoritative and replicated")
	var before := owner.health.current
	replica.combat.bow.fire(Vector2.DOWN, input.aim_point, true)
	check(owner.health.current == before and replica.combat.bow.sequence == 2, "replica cannot launch a damaging skill")
	var checkpoint := CoopCheckpoint.capture(sessions[0])
	check(CoopCheckpoint.valid(JSON.parse_string(JSON.stringify(checkpoint))), "bow cooldown, enhancement and equipment survive checkpoint validation")
	var saved := remote.capture()
	remote.restore(JSON.parse_string(JSON.stringify(saved)))
	check(remote.combat.bow.selected and is_equal_approx(remote.combat.bow.cooldown, saved.combat.bow_cooldown), "co-op restore retains bow reload/cooldown and clears partial charges")
	check(BarnSaveValidation.enhancement(AngelBowItem.ID, true) and BarnProtocol.enhancement(AngelBowItem.ID, true), "enhanced bows are valid in personal deposits")
	check(game.world_items.drop_stack(remote.combat, remote.inventory, remote.character_equipment, "equipment", "combat_2"), "equipped bow drops with enhancement intact")
	await ticks(8)
	var found := false
	for drop: WorldItemDrop in sessions[1].game.world_items.pool.drops.values():
		if drop.item_id == AngelBowItem.ID and drop.enhanced: found = true
	check(found, "enhanced 3D bow world drop replicates")
	owner.character_equipment.set_slot("combat_1", ItemStack.new(AngelBowItem.create(), 1))
	owner.loadout.select(1)
	owner.combat.bow.reload_remaining = 1.4
	owner.combat.bow.cooldown = 4.5
	var solo := AdventureSnapshot.capture(game, "Bow save", 5)
	check(SaveStore.valid(JSON.parse_string(JSON.stringify(solo))), "solo save accepts bow equipment and bounded clocks")
	owner.combat.bow.reload_remaining = 0
	owner.combat.bow.cooldown = 0
	AdventureSnapshot.restore(game, JSON.parse_string(JSON.stringify(solo)))
	check(game.combat.bow.selected and game.combat.bow.reload_remaining == 1.4 and game.combat.bow.cooldown == 4.5, "solo restore keeps bow selected and preserves reload and skill cooldown")
	solo.bow_reload = INF
	check(not SaveStore.valid(solo), "solo save rejects nonfinite bow clocks")
	host.leave()
	for child in root.get_children(): child.queue_free()
	await process_frame
	print("Angel bow co-op: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
