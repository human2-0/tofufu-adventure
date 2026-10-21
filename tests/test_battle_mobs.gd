extends SceneTree
## Real adventure mobs, finite rewards, authority gates and recovery in Royale.
var failures: int = 0
var game: BattleRoyaleGame

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: return
	failures += 1
	printerr("FAIL: ", label)

func _run() -> void:
	var room := BattleRoom.new()
	room.options = [3, 1]
	root.add_child(room)
	room.practice()
	room.epoch = "f".repeat(24)
	game = BattleRoyaleGame.new()
	game.room = room
	root.add_child(game)
	while not game.composed: await physics_frame
	game.set_physics_process(false)
	_layout()
	if game.mobs.actors.size() < 7:
		quit(1)
		return
	check(not _attack(0, 10), "deployment prevents hunting before emergence")
	BattleTestDeployment.finish(game)
	game.match_state.time = 13
	for slot in range(1, game.bodies.size()):
		game.bodies[slot].position += Vector3.UP * 30
	await _ranged_attacks()
	await _projectile()
	_rewards()
	_shell()
	await _attacks()
	_pending_and_recovery()
	_storm_and_cpu()
	_wire()
	game.queue_free()
	room.queue_free()
	await process_frame
	await process_frame
	print("Battle Royale adventure hunts: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _attack(id: int, amount: float, point: Vector3 = Vector3.INF) -> bool:
	return game.mobs.actors[id].target.receive_attack(amount, Vector3.BACK, Damageable.HitKind.SOY, point, game.combat.fighters[0].health)

func _layout() -> void:
	var rows: Array = game.match_state.mobs[0]
	print("Spaced hunt population: ", rows.size())
	check(rows.size() >= 15 and rows.size() <= 24, "bounded, worthwhile hunt population")
	check(game.mobs.actors.size() == rows.size(), "authority composes real adventure enemies")
	check(BattleMobWire.valid(game.match_state.mobs, game.bodies.size()), "initial hunt state fits the wire")
	var quadrants: Dictionary = {}
	var kinds: Dictionary = {}
	for i in rows.size():
		var row: Array = rows[i]
		var at := Vector3(row[1], row[2], row[3])
		quadrants[Vector2(signf(at.x + 22), signf(at.z + 22))] = true
		kinds[row[0]] = true
		check(not game.world.is_water(at), "hunts start on dry, collision-cleared land")
		check(not game.mobs.actors[i].is_physics_processing(), "no independent enemy physics can bypass authority or pause")
		for j in i:
			check(Vector2(at.x - rows[j][1], at.z - rows[j][3]).length() >= 59.99, "hunt sites are evenly separated")
		for site: Array in game.match_state.deployment.sites:
			check(Vector2(at.x - site[0], at.z - site[2]).length() >= 11.99, "plants have a fair emergence buffer")
	check(kinds.size() == 3 and quadrants.size() == 4, "snails, armored snails and bees populate the map")
	for fighter in game.combat.fighters:
		check(fighter.combat.targets.has(game.mobs.actors[0].target), "all survivors can use adventure weapons against mobs")

func _projectile() -> void:
	var mob := game.mobs.actors[0]
	var at := mob.position
	game.bodies[0].position = at + Vector3(0, 0, -3)
	game.bodies[0].velocity = Vector3.ZERO
	await physics_frame
	var gun := game.combat.fighters[0].combat.gun
	gun.cooldown = 0
	gun.spread_multiplier = 0
	var command := PlayerCommand.new()
	command.attack_held = true
	command.aim = Vector2.DOWN
	command.aim_point = at + Vector3.UP * 0.55
	game.combat.fighters[0].step(command, 1.0 / 60)
	for frame in 12: await physics_frame
	check(mob.target.current < BattleMobWire.HEALTH[0] and gun.magazine == 8, "real adventure projectile damages a real roaming mob and spends ammo")

func _rewards() -> void:
	var before := game.match_state.drops.size()
	check(_attack(0, 1000), "survivor finishes a hunt")
	check(game.match_state.mobs[0][0][9] == 2 and game.match_state.drops.size() == before + 2, "snail grants two finite drops once")
	check(game.match_state.mobs[1][0] == 1 and game.match_state.rows[0][12] == 0 and game.match_state.stats[0][0] == 0, "PvE counts stay separate from PvP KOs and damage goals")
	check(not _attack(0, 1000), "dead hunt cannot be harvested twice")
	game.mobs.step(30)
	check(not game.mobs.actors[0].visible and game.mobs.actors[0].target.current == 0, "adventure respawns remain disabled throughout the round")
	var first: Array = game.match_state.drops[before]
	check(first[4] == 27 and first[5] == 2, "snail guarantees two healing apples")
	game.bodies[0].position = Vector3(first[1], first[2], first[3])
	check(game.pack.transactions.take(0, int(first[0])), "hunt loot enters the normal temporary backpack")
	for kind in 3:
		for id in 100:
			var contents := BattleHuntLoot.contents("stable", id, kind)
			check(contents == BattleHuntLoot.contents("stable", id, kind), "hunt rewards cannot reroll")
			check(contents[0] == (27 if kind == 0 else 28), "every successful hunt guarantees food")
			check(not contents.has(24), "hunt backpacks are upgrades over the common starter bag")
			for item in contents: check(item >= 1 and item <= 32, "only existing match gear can drop")

func _shell() -> void:
	var mob := game.mobs.actors[1] as ArmoredSnail
	check(_attack(1, 20, mob.position + Vector3.UP * 0.8) == false, "armored shell absorbs incoming fire")
	check(mob.shell_health == 45 and mob.target.current == BattleMobWire.HEALTH[1], "adventure shell has independent HP")
	check(_attack(1, 10, mob.position + Vector3.UP * 0.2), "exposed snail foot remains vulnerable")
	check(mob.target.current == BattleMobWire.HEALTH[1] - 10, "weak points preserve adventure combat rules")
	var before := _active_drops()
	var first_id := game.pack.next_drop
	mob.position.y += 8 # A melee launch must not leave the bounty floating overhead.
	_attack(1, 1000, mob.position + Vector3.UP * 0.2)
	check(_active_drops() == before + 3 and BattleHuntLoot.contents(game.room.epoch, 1, 1)[0] == 28, "armored hunt guarantees milk, armor and a stronger weapon")
	for drop: Array in game.match_state.drops:
		if drop[0] >= first_id: check(drop[2] < mob.position.y - 5, "airborne hunt rewards land on the actual floor")

func _active_drops() -> int:
	var count := 0
	for drop: Array in game.match_state.drops:
		if drop[5] > 0: count += 1
	return count

func _attacks() -> void:
	var mob := game.mobs.actors[3]
	game.bodies[0].position = mob.position + Vector3.BACK
	game.match_state.rows[0][9] = 0
	game.match_state.rows[0][8] = 100
	mob.quarry = game.bodies[0]
	mob._rest = 0
	await physics_frame
	check(mob._choose_direction(0.01) == Vector3.ZERO and mob._windup > 0, "snail attack has the original readable warning")
	mob._choose_direction(0.7)
	_flush()
	check(game.match_state.rows[0][8] == 88, "mob melee applies authoritative survivor damage")
	game.bodies[0].motor.is_dashing = true
	game.mobs._melee(12, mob.position, 3)
	_flush()
	check(game.match_state.rows[0][8] == 88, "normal dash immunity protects against PvE")
	game.bodies[0].motor.is_dashing = false
	var bee := game.mobs.actors[2] as WildBee
	game.bodies[0].position = bee.position + Vector3(0, 0, 1.1)
	await physics_frame
	bee.quarry = game.bodies[0]
	bee.sting.launch(bee.position + Vector3.UP * 0.7, Vector3.BACK)
	for frame in 30:
		bee.sting.step(1.0 / 60, Rect2(), bee.get_rid())
		_flush()
	check(game.match_state.rows[0][8] == 72, "swept adventure bee sting hurts the actual victim once")
	game.playing = false
	check(not _attack(2, 10), "paused match rejects PvE damage")
	game.mobs._sting(game.bodies[0], 16, bee.position, 2)
	_flush()
	check(game.match_state.rows[0][8] == 72, "pause cannot leak enemy outcomes")
	game.playing = true
	var host := game.room.host_key
	game.room.host_key = "f".repeat(64)
	check(not _attack(2, 10), "guest presentation cannot award damage or loot")
	game.room.host_key = host

func _flush() -> void:
	var commands: Array[PlayerCommand] = []
	commands.resize(game.bodies.size())
	game.combat.step(commands, 0, 0)

func _pending_and_recovery() -> void:
	var original := game.match_state.drops.duplicate(true)
	game.match_state.drops.clear()
	for id in BattlePackWire.DROPS: game.match_state.drops.append([id, 0, 0, 0, 27, 1, 0])
	_attack(2, 1000)
	check(game.match_state.mobs[0][2][9] == 1, "full drop ledger retains an atomic pending reward")
	game.recovery.publish()
	var saved := BattleCheckpoint.decode(game.room.migration.checkpoint, game.room.members)
	check(not saved.is_empty(), "live, slain, shelled and pending hunts fit recovery")
	if saved.is_empty(): return
	game.mobs.actors[4].target.current = 1
	game.recovery.pause()
	game.recovery.restore(saved)
	game.recovery.resume()
	check(game.mobs.actors[4].target.current == saved.mobs[0][4][4][6], "migration restores exact living mob health")
	check(game.match_state.mobs[1][0] == 3 and not game.mobs.actors[0].visible, "migration retains hunt credits and permanent corpses")
	for id in 2: game.match_state.drops[id][5] = 0
	BattleHuntLoot.release(game, 2)
	check(game.match_state.mobs[0][2][9] == 2 and game.match_state.drops.size() == BattlePackWire.DROPS, "pending rewards safely reuse freed slots after recovery")
	var paid := game.match_state.drops.duplicate(true)
	BattleHuntLoot.release(game, 2)
	check(game.match_state.drops == paid, "recovered hunt rewards cannot duplicate")
	game.match_state.drops = original
	game.pack.restore(game.match_state.pack)

func _storm_and_cpu() -> void:
	var row: Array = game.match_state.mobs[0][6]
	game.match_state.rows[0][0] = row[4][0]
	game.match_state.rows[0][1] = row[4][1]
	game.match_state.rows[0][2] = row[4][2] - 9
	var command := BattleBotHunts.command(0, game.match_state, [0, 0, 1, 0, 32, 0, 0, 38], INF)
	check(command[3] > 0.9, "CPUs can choose nearby hunts through bounded snapshot values")
	var original := [1, 0, 1, 0, 1, 0, 0, 10]
	check(BattleBotHunts.command(0, game.match_state, original, 25) == original, "nearby survivor combat takes priority over optional hunting")
	var before := game.match_state.drops.size()
	var hunts: Array = game.match_state.mobs[1].duplicate()
	game.match_state.time = 432
	game.mobs.step(100)
	check(game.match_state.mobs[0][3][9] == 3 and game.match_state.drops.size() == before and game.match_state.mobs[1] == hunts, "storm clears mobs without loot or hunt credit")
	check(game.match_state.alive == 4 and game.match_state.winner == -2, "hunts never decide survivor victory")
	game.match_state.time = 13

func _wire() -> void:
	game.mobs.capture()
	check(BattleMobWire.valid(game.match_state.mobs, game.bodies.size()), "late hunt state remains bounded")
	check(BattleMobWire.valid(JSON.parse_string(JSON.stringify(game.match_state.mobs)), game.bodies.size()), "JSON floating-point tags retain exact finite hunt credits")
	var baseline := game.match_state.mobs.duplicate(true)
	var packet := {"mobs": baseline.duplicate(true)}
	var cached := BattleMobDelta.compact(packet, baseline, 42, false)
	check(packet.mob_delta[0].is_empty() and packet.mob_delta[1].is_empty(), "sleeping enemies and static homes consume no repeated delta payload")
	check(cached == baseline and BattleMobDelta.expand(packet, baseline) and packet.mobs == baseline, "ordered enemy deltas reconstruct exact state")
	var invalid := {"mob_delta": [[[0, []], [0, []]], []]}
	check(not BattleMobDelta.expand(invalid, baseline), "duplicate or truncated enemy delta rejected")
	var data := game.match_state.mobs.duplicate(true)
	data[0][0][0] = 3
	check(not BattleMobWire.valid(data, 4), "unknown enemy kind rejected")
	data = game.match_state.mobs.duplicate(true)
	data[0][0][4][0] = INF
	check(not BattleMobWire.valid(data, 4), "non-finite world state rejected")
	data = game.match_state.mobs.duplicate(true)
	data[0][0][13] = "99999999999999999999"
	check(not BattleMobWire.valid(data, 4), "overflowed RNG state rejected")
	data = game.match_state.mobs.duplicate(true)
	data[0][0][14][8] = INF
	check(not BattleMobWire.valid(data, 4), "nonfinite NPC projectile velocity rejected")
	data = game.match_state.mobs.duplicate(true)
	data[0][0][14][12] = 1000001
	check(not BattleMobWire.valid(data, 4), "unbounded NPC shot sequence rejected")
	data = game.match_state.mobs.duplicate(true)
	data[0][0][14][1] = 4
	check(not BattleMobWire.valid(data, 4), "oversized NPC windup rejected")
	var changed := {"mobs": baseline.duplicate(true)}
	changed.mobs[0][0][14] = [1, 0, 0, 0, 1, 3, 1, 5, 0, 0, 32, 2, 1]
	BattleMobDelta.compact(changed, baseline, 45, false)
	check(changed.mob_delta[0].size() == 1 and BattleMobDelta.expand(changed, baseline) and changed.mobs[0][0][14][11] == 2, "one live NPC shot crosses a bounded delta without resending all hunts")
	data = game.match_state.mobs.duplicate(true)
	data[0].append_array(data[0].duplicate(true))
	check(not BattleMobWire.valid(data, 4), "unbounded enemy population rejected")

func _ranged_attacks() -> void:
	# Isolate real collision at gun range from the authored map's trees/buildings.
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(250, 1, 250)
	floor_shape.shape = floor_box
	floor_shape.position.y = -0.5
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(650, 0, 650)
	game.add_child(floor_body)
	var base := floor_body.position
	for id in 3:
		var mob := game.mobs.actors[id]
		var previous := mob.position
		mob.position = base
		mob.quarry = game.bodies[0]
		mob._windup = 0
		game.bodies[0].position = base + Vector3.BACK * 90
		game.bodies[0].velocity = Vector3.ZERO
		game.match_state.rows[0][8] = 100
		game.match_state.rows[0][9] = 0
		var shot := game.mobs.ranged[id]
		shot.rest = 0
		await physics_frame
		shot.step(0, true)
		check(shot.windup > 0 and shot.warning.visible, "every mob telegraphs shots across the common gun's entire range")
		shot.step(shot.profile.windup + 0.01, true)
		check(shot._flying() and not shot.projectile.is_physics_processing(), "one real authority-stepped projectile per mob")
		check(BattleMobShotWire.valid(JSON.parse_string(JSON.stringify(shot.capture()))), "active ranged attack survives bounded JSON wire")
		var hp := mob.target.current
		mob.target.current = 0 # Fired threats must survive a fast ranged kill.
		for frame in 210:
			await physics_frame
			shot.step(1.0 / 60, false)
			_flush()
		check(is_equal_approx(game.match_state.rows[0][8], 100 - shot.profile.damage), "each mob can hurt a gunner at 90m, even after its own death")
		mob.target.current = hp
		shot.rest = 0
		game.bodies[0].velocity = Vector3.RIGHT * 8
		shot.step(0, true)
		check(shot.aim.x > 0.1, "shots lead a steadily moving target instead of always missing behind it")
		var locked := shot.aim
		game.bodies[0].velocity = Vector3.LEFT * 8
		shot.step(0.01, true)
		check(shot.aim == locked, "warning commits aim so changing direction can dodge")
		shot.restore(shot.capture())
		check(shot.windup == 0 and not shot._flying() and shot.rest >= 0.75, "migration cancels transient mob fire and provides a recovery grace")
		mob.position = previous
		mob.quarry = null
	# Solid cover rejects a new ranged attack before spending a projectile.
	var mob := game.mobs.actors[0]
	var previous := mob.position
	mob.position = base
	mob.quarry = game.bodies[0]
	game.bodies[0].position = base + Vector3.BACK * 8
	game.bodies[0].velocity = Vector3.ZERO
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(5, 4, 0.5)
	shape.shape = box
	wall.add_child(shape)
	wall.position = base + Vector3(0, 1, 4)
	game.add_child(wall)
	await physics_frame
	game.mobs.ranged[0].rest = 0
	game.mobs.ranged[0].step(0, true)
	check(game.mobs.ranged[0].windup == 0, "world cover blocks hunt acquisition")
	wall.queue_free()
	await physics_frame
	# Actual guard reflection sends the NPC shot back into its owner's hit adapter.
	var fighter := game.combat.fighters[0]
	game.match_state.rows[0][10] = 1
	fighter.equip(game.match_state.rows[0])
	fighter.combat.equipment.step(Vector2.UP, true, false, false, false, 0, 0.02)
	fighter.combat.vitals.current = 100
	game.mobs.ranged[0].rest = 0
	game.mobs.ranged[0].step(0, true)
	game.mobs.ranged[0].step(0.56, true)
	var before := mob.target.current
	for frame in 60:
		await physics_frame
		game.mobs.ranged[0].step(1.0 / 60, false)
		_flush()
	check(mob.target.current < before, "normal guard reflects a real NPC projectile back for player-attributed damage")
	fighter.combat.equipment.step(Vector2.UP, false, false, false, false, 0, 0.02)
	mob.position = previous
	mob.quarry = null
	game.match_state.rows[0][10] = 2
	fighter.equip(game.match_state.rows[0])
	floor_body.queue_free()
	await physics_frame
