extends SceneTree
## Sotjet intent and damage across two separate worlds through JSON room messages.

var failures: int = 0
const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func _game(room: PlaytestRoom) -> CoopSession:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	root.add_child(viewport)
	var game: Node3D = load("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	viewport.add_child(game)
	var session := CoopSession.new()
	session.game = game
	session.room = room
	game.add_child(session)
	return session

func _run() -> void:
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
	var h := _game(host)
	var g := _game(guest)
	var guest_input := CoopTestInput.new()
	var host_input := CoopTestInput.new()
	root.add_child(guest_input)
	root.add_child(host_input)
	g.roster.local_input = guest_input
	h.roster.local_input = host_input
	h.game.player.command_source = host_input
	var host_actor := h.roster.party[HOST]
	var guest_actor := h.roster.party[GUEST]
	host_actor.actor.position = Vector3(0, 0.1, 2)
	guest_actor.actor.position = Vector3(0, 0.1, -2)
	await ticks(20)
	guest_actor.character_equipment.set_slot("combat_2", ItemStack.new(InventoryItem.weapon("sotjet"), 1))
	guest_input.slot = 2
	guest_input.aim = Vector2.DOWN
	guest_input.aim_point = host_actor.actor.position + Vector3.UP * 0.8
	guest_input.attack = true
	await ticks(35)
	check(guest_actor.combat.sotjet.selected and g.game.combat.sotjet.selected, "guest slot 4 is authoritative and replicated")
	check(host_actor.health.current < 100 and host_actor.health.current > 60, "guest stream hits host with bounded friendly damage")
	check(absf(g.roster.party[HOST].health.current - host_actor.health.current) <= 5.0, "authoritative health replicates without extra guest damage")
	check(host_actor.actor.position.z > 2.2, "guest milk pushes host away on authority")
	check(guest_actor.health.current == 100, "guest stream excludes its owner")
	check(not g.game.combat.sotjet.flow.authoritative, "guest presentation has no damage authority")
	check(g.game.combat.sotjet.flow.parcels.size() > 0, "guest sees continuous replicated milk")
	guest_input.attack = false
	await ticks(20)
	check(not g.game.combat.sotjet.firing, "release stops replicated emission")
	host_actor.character_equipment.set_slot("combat_2", ItemStack.new(InventoryItem.weapon("sotjet"), 1))
	host_input.slot = 2
	host_input.aim = Vector2.UP
	host_input.aim_point = guest_actor.actor.position + Vector3.UP * 0.8
	host_input.attack = true
	await ticks(30)
	check(guest_actor.health.current < 100, "host stream hits guest")
	check(g.game.hud._soy_hit.remaining > 0 and g.game.hud._smear.remaining == 0, "milk uses soy impact feedback without slime smear")
	host_input.attack = false
	await ticks(15)
	check(is_equal_approx(g.roster.party[GUEST].health.current, guest_actor.health.current), "guest receives host milk damage")
	# Both weapons return to the caster when the other player faces the shot.
	for slot in [3, 4]:
		host_actor.actor.position = Vector3(0, 0.1, 1.4)
		guest_actor.actor.position = Vector3(0, 0.1, -1.4)
		host_actor.actor.velocity = Vector3.ZERO
		guest_actor.actor.velocity = Vector3.ZERO
		host_actor.health.current = 100
		guest_actor.health.current = 100
		host_actor.health.invulnerability = 0
		guest_actor.health.invulnerability = 0
		host_actor.actor.position = Vector3(0, 0.1, 1.4)
		guest_actor.actor.position = Vector3(0, 0.1, -1.4)
		guest_input.slot = 1
		guest_input.guard = true
		guest_input.aim = Vector2.DOWN
		host_actor.character_equipment.set_slot("combat_2", ItemStack.new(InventoryItem.weapon("soy_gun" if slot == 3 else "sotjet"), 1))
		host_input.slot = 2
		host_input.aim = Vector2.UP
		host_input.aim_point = Vector3(host_actor.combat.tuning.muzzle_side, 0.8, -1.4)
		host_actor.combat.gun.spread_multiplier = 0
		await ticks(20)
		host_input.attack = true
		await ticks(8 if slot == 3 else 35)
		host_input.attack = false
		await ticks(15)
		check(guest_actor.health.current == 100, "front sword protects guest from slot %d" % slot)
		check(host_actor.health.current < 100, "slot %d reflection damages original host shooter" % slot)
		check(is_equal_approx(g.roster.party[HOST].health.current, host_actor.health.current), "reflected slot %d damage replicates once" % slot)
		guest_input.aim = Vector2.UP
		await ticks(10)
		host_input.attack = true
		await ticks(8 if slot == 3 else 30)
		host_input.attack = false
		await ticks(15)
		check(guest_actor.health.current < 100, "rear guard cannot reflect slot %d" % slot)
	# Reverse the roles: the guest shoots and the host reflects.
	guest_input.guard = false
	host_input.guard = true
	host_input.slot = 1
	host_input.aim = Vector2.UP
	guest_input.aim = Vector2.DOWN
	guest_input.aim_point = Vector3(-0.32, 0.8, 1.4)
	guest_actor.combat.gun.spread_multiplier = 0
	await ticks(15)
	for slot in [3, 4]:
		host_actor.actor.position = Vector3(0, 0.1, 1.4)
		guest_actor.actor.position = Vector3(0, 0.1, -1.4)
		host_actor.actor.velocity = Vector3.ZERO
		guest_actor.actor.velocity = Vector3.ZERO
		host_actor.health.current = 100
		guest_actor.health.current = 100
		host_actor.health.invulnerability = 0
		guest_actor.health.invulnerability = 0
		guest_actor.character_equipment.set_slot("combat_2", ItemStack.new(InventoryItem.weapon("soy_gun" if slot == 3 else "sotjet"), 1))
		guest_input.slot = 2
		await ticks(10)
		guest_input.attack = true
		await ticks(8 if slot == 3 else 30)
		guest_input.attack = false
		await ticks(20)
		check(host_actor.health.current == 100, "host guard reflects guest slot %d" % slot)
		check(guest_actor.health.current < 100, "guest receives its returned slot %d" % slot)
		check(is_equal_approx(g.game.health.current, guest_actor.health.current), "guest reflected damage matches authority")
	host_input.guard = false
	guest_actor.character_equipment.set_slot("combat_2", ItemStack.new(InventoryItem.weapon("sotjet"), 1))
	guest_input.slot = 2
	await ticks(10)
	var save := CoopCheckpoint.capture(h)
	check(CoopCheckpoint.valid(save), "full party checkpoint accepts Sotjet state")
	check(save.party[GUEST].combat.jet and save.party[GUEST].combat.milk >= 0, "checkpoint records selected Sotjet and reservoir")
	var mob: TrainingMob = h.game.encounters.mob_nodes[0]
	mob.target.invulnerability = 0
	mob.target.damage(5)
	await ticks(10)
	check(g.game.encounters.get_children().any(func(child: Node) -> bool: return child is Label3D and child.text == "-5.0"), "guest sees authoritative enemy damage numbers")
	host.leave()
	for child in root.get_children(): child.queue_free()
	await process_frame
	print("Sotjet co-op: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
