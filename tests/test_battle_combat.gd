extends SceneTree
## Actual adventure projectiles, equal kit, guard, specials and cosmetic replicas.
var failures: int = 0
var game: BattleRoyaleGame
var fixture: Node3D

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", label)

func _run() -> void:
	fixture = Node3D.new()
	root.add_child(fixture)
	game = BattleRoyaleGame.new()
	game.room = BattleRoom.new()
	root.add_child(game.room)
	game.room.practice()
	game.playing = true
	var spawns: Array[Vector3] = []
	for slot in 20:
		var body := (load("res://game/player/player.tscn") as PackedScene).instantiate() as Player
		body.command_source = BattleCommandSource.new()
		body.add_child(body.command_source)
		body.position = Vector3(slot * 6, 0, 0)
		fixture.add_child(body)
		body.set_physics_process(false)
		game.bodies.append(body)
		spawns.append(body.position)
	game.match_state.initialize(spawns, 2, [18, 1])
	game.match_state.time = 13
	game.combat = BattleCombat.new()
	game.combat.game = game
	fixture.add_child(game.combat)
	game.combat.build()
	for fighter in game.combat.fighters:
		check(fighter.combat is PlayerCombat and fighter.combat.gun.magazine == 9, "same adventure combat and equal gun magazine")
		check(fighter.combat.vitals.current == 100 and fighter.loadout.equipment.get_slot("combat_1").item.id == "knife", "equal SP and knife without saved progression")
	await physics_frame
	await _shooting()
	_loadouts()
	await _guard_and_replica()
	_reflected_credit()
	_recovery()
	_wire()
	_cloud_and_delta()
	fixture.queue_free()
	game.room.queue_free()
	game.free()
	await process_frame
	await process_frame
	print("Battle adventure combat: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _command(slot: int, fire: bool = false) -> PlayerCommand:
	var command := PlayerCommand.new()
	command.aim = Vector2.DOWN if slot == 0 else Vector2.UP
	command.aim_point = game.bodies[1 - slot].position + Vector3.UP * 0.65
	command.attack_held = fire
	return command

func _tick() -> void:
	var commands: Array[PlayerCommand] = []
	commands.resize(20)
	game.combat.step(commands, 1.0 / 60, 0)
	game.combat.capture()

func _shooting() -> void:
	game.bodies[1].position = Vector3(0, 0, 4)
	var gun := game.combat.fighters[0].combat.gun
	gun.spread_multiplier = 0
	game.combat.fighters[0].step(_command(0, true), 1.0 / 60)
	check(gun.shot_sequence == 1 and gun.magazine == 8, "adventure gun spawns physical shot and spends magazine")
	check(game.match_state.rows[1][9] == 50, "projectile does not hit instantly like old battle raycast")
	for frame in 10:
		await physics_frame
		_tick()
	check(game.match_state.rows[1][9] == 32 and game.match_state.rows[1][8] == 100, "physical body hit absorbs eighteen armour with shooter attribution")
	gun.reload()
	check(gun.reload_remaining == 2, "normal manual reload starts")
	game.combat.fighters[0].step(_command(0), 2)
	check(gun.magazine == 9 and gun.reload_remaining == 0, "adventure reload replenishes nine-round magazine")
	var wall := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4, 3, 0.3)
	collider.shape = shape
	wall.add_child(collider)
	wall.position = Vector3(0, 1, 2)
	fixture.add_child(wall)
	await physics_frame
	gun.cooldown = 0
	game.combat.fighters[0].step(_command(0, true), 1.0 / 60)
	for frame in 10:
		await physics_frame
		_tick()
	check(game.match_state.rows[1][9] == 32, "world cover blocks actual adventure projectile")
	wall.queue_free()
	await physics_frame

func _loadouts() -> void:
	var fighter := game.combat.fighters[0]
	for kind in range(1, BattleBalance.ITEMS.size()):
		var row: Array = game.match_state.rows[0]
		row[22 if kind in BattleGear.MELEE else 23] = kind
		row[10] = kind
		fighter.equip(row)
		check(BattleBalance.item(kind).id == BattleBalance.ITEMS[kind], "battle catalog loans actual adventure item")
		check(fighter.combat.gun.enhancement_multiplier == 1 and fighter.combat.tuning.bean_damage == 18, "rarity never imports saved enhancement or progression")
		if kind == 3: check(is_equal_approx(fighter.combat.sword_damage_multiplier * 1.2, 1.12), "pod sword does not stack its adventure base bonus above legendary power")
		if kind == 9: check(is_equal_approx(fighter.combat.sword_damage_multiplier, 1.30), "legendary sword has real match power")
		if kind == 11: check(is_equal_approx(fighter.combat.gun.damage_multiplier, 1.22) and is_equal_approx(fighter.combat.gun.attack_speed_multiplier, 0.94), "raygun earns power and range while trading some fire rate")
	fighter.combat.gun.magazine = 3
	fighter.combat.gun.reload_remaining = 0.8
	fighter.combat.gun.cooldown = 0.18
	for kind in [1, 2, 1, 2]:
		game.match_state.rows[0][10] = kind
		game.match_state.rows[0][22] = 1
		game.match_state.rows[0][23] = 2
		fighter.equip(game.match_state.rows[0])
	check(fighter.combat.gun.magazine == 3 and fighter.combat.gun.reload_remaining == 0.8 and fighter.combat.gun.cooldown == 0.18, "swapping cannot refill magazine or reset reload/cadence")

func _guard_and_replica() -> void:
	var defender := game.combat.fighters[1]
	game.match_state.rows[1][10] = 1
	defender.equip(game.match_state.rows[1])
	defender.combat.equipment.step(Vector2.UP, true, false, false, false, 0, 0.02)
	var accepted := defender.health.receive_attack(20, Vector3.BACK, Damageable.HitKind.KNIFE, Vector3.INF, game.combat.fighters[0].health)
	check(not accepted and defender.combat.vitals.current == 80, "directional adventure guard spends SP and blocks frontal melee")
	defender.authority(false)
	game.room.offline = false
	game.room.host_key = "a".repeat(64)
	game.room.local_key = "b".repeat(64)
	check(not defender.health.receive_attack(50, Vector3.BACK, Damageable.HitKind.SOY, Vector3.ZERO, game.combat.fighters[0].health), "replicas cannot apply outcomes")
	game.room.offline = true
	game.room.host_key = game.room.local_key
	defender.authority(true)
	await physics_frame

func _recovery() -> void:
	var fighter := game.combat.fighters[0]
	fighter.combat.gun.recoil.heat = 0.7
	fighter.combat.gun.recoil.quiet_time = 0.03
	fighter.combat.vitals.current = 37
	fighter.combat.bow.cooldown = 4
	fighter.combat.claws.cooldown = 6
	fighter.combat.podburst.cooldown = 2
	fighter.combat.plunge.cooldown = 1
	fighter.combat.sotjet.milk = 23
	game.combat.capture()
	var saved := game.match_state.combat.duplicate(true)
	fighter.combat.vitals.reset()
	game.combat.restore(saved, true)
	check(fighter.combat.vitals.current == 37 and fighter.combat.sotjet.milk == 23, "migration retains SP and milk")
	check(fighter.combat.bow.cooldown == 4 and fighter.combat.claws.cooldown == 6 and fighter.combat.podburst.cooldown == 2 and fighter.combat.plunge.cooldown == 1, "migration retains every adventure special cooldown")
	check(is_equal_approx(fighter.combat.gun.recoil.heat, 0.7) and is_equal_approx(fighter.combat.gun.recoil.quiet_time, 0.03), "migration retains recoil and its recovery delay")
	check(fighter.combat.gun.reload_remaining == 0.8 and fighter.combat.gun.magazine == 3, "migration retains partial reload and ammunition")
	check(not fighter.combat.active and not fighter.combat.claws.busy(), "migration cancels transient attacks")

func _wire() -> void:
	game.combat.capture()
	var packet := game.match_state.capture()
	check(BattleProtocol.snapshot(JSON.parse_string(JSON.stringify(packet))), "full adventure combat uses bounded battle wire values")
	check(JSON.stringify(packet).to_utf8_buffer().size() < 32000, "twenty complete adventure states remain below transport limit")
	var command := PlayerCommand.new()
	command.guard_held = true
	command.dash_held = true
	command.attack_pressed = true
	command.weapon_slot = 2
	command.aim_point = Vector3(0.5, 1.1, 3)
	var encoded := BattleInputBuffer.encode(command)
	var decoded := BattleInputBuffer.decode(encoded)
	check(BattleProtocol.command(encoded) and decoded.guard_held and decoded.dash_held and decoded.attack_pressed and decoded.weapon_slot == 2 and not decoded.run_held, "adventure aim, special, charged dash, click and slot controls roundtrip")
	check(decoded.aim_point.distance_to(command.aim_point) < 0.002, "close-range muzzle convergence retains the exact aimed target distance")
	packet.combat[0][0] = "bad"
	check(not BattleProtocol.snapshot(packet), "malformed combat values rejected before presentation")

func _reflected_credit() -> void:
	var victim := game.combat.fighters[0]
	var deflector := game.combat.fighters[1]
	game.match_state.rows[0][8] = 10
	game.match_state.rows[0][9] = 0
	var bean := SoyProjectile.new()
	bean.owner_health = victim.health
	bean.reflected_by = deflector.health
	bean.reflections = 1
	bean.targets = [victim.health]
	bean.velocity = Vector3.FORWARD * 60
	fixture.add_child(bean)
	bean._hit(victim.actor, victim.actor.position + Vector3.UP * 0.5)
	_tick()
	check(game.match_state.rows[0][8] == 0 and game.match_state.rows[1][12] == 1, "reflected adventure projectile credits the deflector, not original shooter")
	bean.queue_free()
	game.match_state.rows[0][8] = 100
	game.match_state.rows[0][13] = 0
	game.match_state.alive = 20

func _cloud_and_delta() -> void:
	var fighter := game.combat.fighters[0]
	fighter._cloud(fighter.actor.position)
	game.combat.capture()
	check(fighter.cloud_sequence == 1 and fighter.get_child_count() > 1, "super dash uses the normal adventure cloud")
	var before := game.match_state.combat.duplicate(true)
	fighter.combat.gun.magazine = 1
	fighter.combat.vitals.current = 22
	game.combat.capture()
	var after := game.match_state.combat.duplicate(true)
	var patch := BattleCombatWire.difference(before, after)
	var rebuilt := BattleCombatWire.apply(before, JSON.parse_string(JSON.stringify(patch)))
	check(_same_wire(rebuilt, after), "compact combat delta reconstructs complete validated state")
	check(JSON.stringify(patch).length() < JSON.stringify(after).length() / 4, "changing ammo/SP sends only changed fields")
	check(BattleCombatWire.apply(before, [[0, 999, 0]]).is_empty(), "invalid delta index rejected")
	var receiver := Damageable.new()
	fixture.add_child(receiver)
	check(receiver.receive_attack(7, Vector3.ZERO, Damageable.HitKind.SOY, Vector3.ZERO, fighter.health) and receiver.current == receiver.maximum - 7, "adventure receivers preserve their ordinary damage path")
	receiver.queue_free()

func _same_wire(left: Variant, right: Variant) -> bool:
	if left is Array and right is Array:
		if left.size() != right.size(): return false
		for i in left.size():
			if not _same_wire(left[i], right[i]): return false
		return true
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size(): return false
		for key in left:
			if not right.has(key) or not _same_wire(left[key], right[key]): return false
		return true
	if (left is float or left is int) and (right is float or right is int): return is_equal_approx(float(left), float(right))
	return left == right
