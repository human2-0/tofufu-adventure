extends SceneTree
## JSON-wire guest controls, host-only training/loot, and cosmetic Bengal replicas.

var failures: int = 0
var sessions: Array[CoopSession] = []
const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for i in count:
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
	check(sessions[1]._synchronized, "guest accepts new Bengal roster")
	for session in sessions:
		for mob in session.game.encounters.mob_nodes:
			mob.set_physics_process(false)
			mob.target.set_physics_process(false)
	var game: AdventureGame = sessions[0].game
	var remote: CoopActor = sessions[0].roster.party[GUEST]
	var replica: CoopActor = sessions[1].roster.party[GUEST]
	remote.health.current = 30
	remote.combat.vitals.current = 10
	remote.progression.progress.award_experience(CharacterProgress.threshold(15, true))
	check(remote.health.current == remote.health.maximum and remote.combat.vitals.current == remote.combat.vitals.maximum, "host fully restores a guest at an earned level-up")
	remote.character_equipment.set_slot("combat_1", ItemStack.new(BengalPawsItem.create(), 1))
	remote.loadout.select(1)
	var cat := game.encounters.mob_nodes[59] as BengalMonster
	var mirror := sessions[1].game.encounters.mob_nodes[59] as BengalMonster
	remote.actor.relocate(cat.position - Vector3.BACK * 1.2)
	remote.health.invulnerability = 0
	cat.target.invulnerability = 0
	input.aim = Vector2.DOWN
	input.aim_point = cat.target.global_position
	await ticks(8)
	check(replica.actor.has_node("LevelBlessing") and is_equal_approx(replica.health.current, remote.health.maximum), "guest presents blessing and full authoritative HP after promotion")
	var proof := remote.capture()
	check(ExplorationProtocol.actor(JSON.parse_string(JSON.stringify(proof))), "level-fifteen maximum HP survives decimal JSON rounding")
	proof.health = remote.health.maximum + 0.01
	check(not ExplorationProtocol.actor(proof), "HP beyond floating-point tolerance is rejected")
	check(replica.combat.claws.selected and replica.character_equipment.get_slot("combat_1").item.id == BengalPawsItem.ID, "host equipment arrives on guest")
	var before := cat.target.current
	input.attack = true
	await ticks(2)
	input.attack = false
	await ticks(2)
	check(cat.target.current < before and remote.progression.progress.practice.fist == 1 and remote.progression.progress.practice.attack_speed == 1, "authenticated guest LMB trains both skills once on host")
	await ticks(22)
	before = cat.target.current
	input.guard = true
	await aimed_ticks(75, remote, cat)
	check(remote.combat.claws.charging and replica.combat.claws.charging and cat.target.current == before, "guest charge replicates without premature damage")
	await aimed_ticks(75, remote, cat)
	input.guard = false
	await ticks(8)
	check(is_equal_approx(before - cat.target.current, remote.combat.claws.damage(remote.combat) * 4), "guest charged dash contact and three-times finisher resolve on host")
	check(cat.target.paralysis == 4 and mirror.target.paralysis == 4, "four-second paralysis replicates as bounded state")
	check(replica.combat.claws.sequence == 1 and replica.combat.claws.cooldown > 6.9, "guest receives cosmetic rift sequence and cooldown")
	check(remote.progression.progress.practice.attack_speed == 2 and replica.progression.progress.practice.attack_speed == 2, "guest receives authoritative speed practice")
	var health := cat.target.current
	var practice: int = replica.progression.progress.practice.attack_speed
	replica.combat.claws.strike(replica.combat, true)
	check(cat.target.current == health and replica.progression.progress.practice.attack_speed == practice, "replica rift cannot apply damage or practice")
	cat.facing = Vector3.LEFT
	cat.velocity = Vector3.ZERO
	cat.claw_time = 0.2
	await ticks(8)
	check(mirror.facing.distance_to(Vector3.LEFT) < 0.01 and mirror.claw_time == 0.2 and not mirror.is_physics_processing(), "guest receives committed facing and claw pose without AI")
	game.world_items.bengal_roll = func() -> float: return 0.0
	game.world_items.magic_roll = func() -> float: return 1.0
	cat.target.damage(9999)
	await ticks(8)
	check(not mirror.visible, "authoritative defeat removes guest Bengal")
	var paw_drops := 0
	for drop: WorldItemDrop in sessions[1].game.world_items.pool.drops.values():
		if drop.item_id == BengalPawsItem.ID: paw_drops += 1
	check(paw_drops == 1 and not BengalMobLoot.drop(sessions[1].game.world_items, mirror.position), "one host rare drop replicates and guest cannot mint another")
	var checkpoint := CoopCheckpoint.capture(sessions[0])
	check(CoopCheckpoint.valid(JSON.parse_string(JSON.stringify(checkpoint))), "co-op checkpoint retains new weapon, practice and world records")
	host.leave()
	for child in root.get_children(): child.queue_free()
	await process_frame
	print("Bengal co-op: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func aimed_ticks(count: int, remote: CoopActor, cat: BengalMonster) -> void:
	var source := sessions[1].roster.local_input as CoopTestInput
	for index in count:
		var offset := cat.position - remote.actor.position
		source.aim = Vector2(offset.x, offset.z).normalized()
		source.aim_point = cat.target.global_position
		await ticks(1)
