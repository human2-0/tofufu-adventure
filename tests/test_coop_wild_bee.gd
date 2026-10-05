extends SceneTree
## Two real local worlds: intercepted stings hurt the actual host-side victim only.

var failures: int = 0
var sessions: Array[CoopSession] = []
var host_key := "a".repeat(64)
var guest_key := "b".repeat(64)

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for index in count:
		await physics_frame
		await process_frame

func _run() -> void:
	var host := PlaytestRoom.new()
	var guest := PlaytestRoom.new()
	root.add_child(host)
	root.add_child(guest)
	host.local_key = host_key
	guest.local_key = guest_key
	host.peers[guest_key] = {"name": "Guest", "hosting": false, "busy": false}
	guest.peers[host_key] = {"name": "Host", "hosting": true, "busy": false}
	host.send_packet = func(_key: String, data: Dictionary) -> void: guest.receive({"type": "packet", "key": host_key, "data": data})
	guest.send_packet = func(_key: String, data: Dictionary) -> void: host.receive({"type": "packet", "key": guest_key, "data": data})
	host.create_room()
	guest.join_room(host_key)
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
	await ticks(15)
	check(sessions[1]._synchronized, "guest synchronizes expanded bee roster")
	var authority := sessions[0]
	var game: AdventureGame = authority.game
	for session in sessions:
		for mob: TrainingMob in session.game.encounters.mob_nodes: mob.set_physics_process(false)
		for member: CoopActor in session.roster.party.values():
			member.actor.set_physics_process(false)
			member.set_physics_process(false)
	var owner: CoopActor = authority.roster.party[host_key]
	var victim: CoopActor = authority.roster.party[guest_key]
	var bee := game.encounters.mob_nodes[39] as WildBee
	var origin := Vector3(200, 20, 100)
	bee.position = origin
	bee._home = origin
	bee.quarry = owner.actor
	owner.actor.position = origin + Vector3.BACK * 7
	victim.actor.position = origin + Vector3.BACK * 3
	victim.health.invulnerability = 0.0
	victim.combat.incoming_damage_multiplier = 0.5
	var before := victim.health.current
	await ticks(2)
	bee.sting.launch(origin + Vector3.UP * 0.7, Vector3.BACK)
	bee.sting.step(0.7, bee.protected_area, bee.get_rid())
	check(victim.health.current == before - 8, "intercepting guest takes sting with armor applied exactly once")
	check(owner.health.current == owner.health.maximum, "original quarry is untouched when another actor intercepts")
	var mirror := sessions[1].game.encounters.mob_nodes[39] as WildBee
	bee.sting.launch(origin + Vector3.UP * 0.7, Vector3.BACK)
	await ticks(12)
	check(mirror.sting.active and not mirror.is_physics_processing(), "guest receives active sting presentation without authority")
	check(mirror.sting.global_position.distance_to(bee.sting.global_position) < 0.01, "replica sting uses host position")
	victim.health.invulnerability = 0.0
	victim.combat.equipment.guarding = true
	victim.combat.equipment.facing = Vector2.UP
	before = victim.health.current
	game.encounters._bee_stung(victim.actor, 16, origin, bee)
	check(victim.health.current == before and victim.block_count > 0, "guest directional guard blocks sting once")
	victim.combat.equipment.guarding = false
	victim.spectating = true
	game.encounters._bee_stung(victim.actor, 16, origin, bee)
	check(victim.health.current == before, "spectators are immune to stings")
	bee.target.damage(999)
	await ticks(12)
	check(not mirror.visible and not mirror.sting.active, "host death removes guest bee and projectile")
	host.leave()
	for child in root.get_children(): child.queue_free()
	await process_frame
	print("Co-op wild bees: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
