extends SceneTree
## Actual map, atomic match bags, food, bounded wire and checkpoint restoration.
var failures: int = 0
var game: BattleRoyaleGame

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if value: return
	failures += 1
	printerr("FAIL: ", label)

func _run() -> void:
	var room := BattleRoom.new()
	root.add_child(room)
	room.practice()
	game = BattleRoyaleGame.new()
	game.room = room
	root.add_child(game)
	while not game.composed: await physics_frame
	BattleTestDeployment.finish(game)
	game.set_physics_process(false)
	game.match_state.time = 13
	_layout()
	await _chest()
	_bags_and_sets()
	_identical_weapons()
	_cpu_gear()
	_food()
	await _controls()
	await _requests()
	_checkpoint()
	_wire()
	_death()
	game.queue_free()
	room.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.25).timeout
	print("Battle temporary inventory: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _layout() -> void:
	var chests := game.match_state.chests
	print("Random chest count: ", chests.size())
	check(chests.size() >= 40 and chests.size() <= 80, "reasonable chest count")
	var quadrants: Dictionary = {}
	for i in chests.size():
		var row: Array = chests[i]
		var at := Vector3(row[1], row[2], row[3])
		check(not game.world.is_water(at), "chests spawn on dry land")
		check(absf(at.y - game.world.ground_point(at.x, at.z, 0.08).y) < 0.002, "chests use shared terrain height")
		for body: Player in game.bodies: check(body.position.distance_to(at) >= 3.99, "chests never spawn inside starting survivors")
		quadrants[Vector2(signf(at.x + 22), signf(at.z + 22))] = true
		for j in i:
			var other: Array = chests[j]
			check(Vector2(at.x - other[1], at.z - other[3]).length() >= 27.999, "chests never cluster")
	check(quadrants.size() == 4, "all map quadrants have choices")
	var totals: Dictionary = {}
	for id in 2000:
		var contents := BattleChestLoot.contents("uniform-test", id)
		check(contents == BattleChestLoot.contents("uniform-test", id), "chests cannot reroll")
		var seen: Dictionary = {}
		for kind in contents:
			check(not seen.has(kind), "four distinct chest choices")
			seen[kind] = true
			totals[kind] = int(totals.get(kind, 0)) + 1
	check(totals.size() == 32, "weapons, twelve armour pieces, backpacks and all six foods are in the common pool")
	var polish := preload("res://game/settings/localization/pl.po")
	for kind in range(1, 12):
		var item := BattleItems.make(kind)
		check(item.required_level == 1 and not item.description.contains("Lv. 15") and not item.description.contains("Rare Bengal drop"), "match loan descriptions do not claim adventure requirements or rare odds")
		check(not polish.get_message(item.description).is_empty(), "every match weapon tooltip has exact Polish copy")
	var grades := [0, 0, 0]
	for kind: int in totals: grades[BattleRarity.grade(kind)] += int(totals[kind])
	check(grades[0] > 4400 and grades[0] < 5200 and grades[1] > 2200 and grades[2] > 400 and grades[2] < 850, "same weighted pool everywhere: common plentiful, rare useful, legendary scarce")
	for slot in 20:
		var loadout := game.combat.fighters[slot].loadout
		check(loadout.inventory.capacity == 10 and loadout.equipment.get_slot("support_1").item.id == "soy_milk" and loadout.equipment.get_slot("support_2").count == 2, "all survivors have equal finite starter supplies")

func _chest() -> void:
	var row: Array = game.match_state.chests[0]
	var at := Vector3(row[1], row[2], row[3])
	game.bodies[0].position = at + Vector3(0, 0, 2.4)
	await physics_frame
	game.pack.requests.request(0, [0])
	check(row[4] == 0, "even local host chest opens wait for input delay")
	game.pack.requests.flush(game.simulation.clock + 0.099, 0)
	check(row[4] == 0, "minimum delay enforced")
	game.pack.requests.flush(game.simulation.clock + 0.101, 0)
	check(row[4] == 1 and game.match_state.drops.size() == 4, "opening spills four independent choices")
	check(not BattleChestLoot.open(game.pack, 0, 0), "opening a chest twice cannot duplicate items")
	var selected: Array = game.match_state.drops[0]
	game.bodies[0].position = Vector3(selected[1], selected[2], selected[3])
	await physics_frame
	check(game.pack.transactions.take(0, selected[0]) and selected[5] == 0, "take only selected reachable item")
	check(not game.pack.transactions.take(0, selected[0]), "taken item ID cannot be replayed")
	check(game.match_state.drops[1][5] == 1, "other choices stay for other survivors")
	var inventory := game.combat.fighters[0].loadout.inventory
	inventory.clear()
	for i in inventory.capacity: inventory.set_slot(i, ItemStack.new(BattleItems.make(1), 1))
	var other: Array = game.match_state.drops[1]
	game.bodies[0].position = Vector3(other[1], other[2], other[3])
	await physics_frame
	check(not game.pack.transactions.take(0, other[0]) and other[5] == 1, "a full backpack never consumes or partly takes a drop")
	inventory.clear()

func _bags_and_sets() -> void:
	var fighter := game.combat.fighters[0]
	var bag := fighter.loadout.inventory
	bag.set_slot(0, ItemStack.new(BattleItems.make(26), 1))
	check(game.pack.transactions.transfer(0, 0, 0, 1, 4) and bag.capacity == 20, "wearing a found backpack expands real storage")
	bag.set_slot(19, ItemStack.new(BattleItems.make(27), 1))
	check(not game.pack.transactions.transfer(0, 0, 0, 1, 4) and bag.capacity == 20 and bag.get_slot(19) != null, "smaller backpack cannot erase overflow")
	bag.clear()
	fighter.combat.gun.magazine = 3
	fighter.combat.gun.cooldown = 0.19
	fighter.combat.gun.reload_remaining = 0.8
	fighter.combat.gun.recoil.heat = 0.6
	fighter.combat.equipment._click_remaining = 0.12
	fighter.combat.vitals.current = 37
	fighter.combat.bow.cooldown = 4
	fighter.combat.claws.cooldown = 6
	fighter.combat.podburst.cooldown = 2
	fighter.combat.plunge.cooldown = 1
	fighter.combat.rules.cooldown = 3
	for i in 4:
		bag.set_slot(i, ItemStack.new(BattleItems.make(20 + i), 1))
		check(game.pack.transactions.transfer(0, 0, i, 1, i), "found Celestial piece is wearable at match level one")
	check(fighter.loadout.equipment.complete_set() == "celestial", "four found pieces activate the set")
	check(is_equal_approx(fighter.health.armor_multiplier, 0.75) and is_equal_approx(fighter.combat.gun.damage_multiplier, 1.20), "armour and set power have fair match caps")
	check(fighter.combat.gun.magazine == 3 and is_equal_approx(fighter.combat.gun.reload_remaining, 0.8) and is_equal_approx(fighter.combat.gun.cooldown, 0.19), "changing apparel cannot refill ammo, reload or cadence")
	check(is_equal_approx(fighter.combat.vitals.current, 37) and is_equal_approx(fighter.combat.gun.recoil.heat, 0.6) and is_equal_approx(fighter.combat.equipment._click_remaining, 0.12), "gear refresh preserves stamina, recoil and melee cadence")
	check(fighter.combat.bow.cooldown == 4 and fighter.combat.claws.cooldown == 6 and fighter.combat.podburst.cooldown == 2 and fighter.combat.plunge.cooldown == 1 and fighter.combat.rules.cooldown == 3, "every special cooldown survives apparel, food and bag changes")
	var celestial := game.combat.fighters[18]
	for i in 4: celestial.loadout.equipment.set_slot(CharacterEquipment.APPAREL_SLOTS[i], ItemStack.new(BattleItems.make(20 + i), 1))
	celestial.loadout.equipment.set_slot("combat_2", ItemStack.new(BattleItems.make(11), 1))
	celestial.loadout.select(2)
	game.pack.refresh(18)
	check(is_equal_approx(celestial.combat.gun.damage_multiplier, 1.22 * 1.20) and is_equal_approx(celestial.combat.gun.attack_speed_multiplier, 0.94 * 1.12), "legendary weapon and full outfit bonuses compose once")
	celestial.loadout.refresh(false)
	check(is_equal_approx(celestial.combat.gun.damage_multiplier, 1.464) and is_equal_approx(celestial.actor.motor.walk_multiplier, 1.10), "repeated refresh cannot stack Celestial bonuses")
	check(InventoryItem.weapon("soy_raygun").required_level > 1 and is_equal_approx(InventoryItem.apparel("celestial_helmet").damage_reduction, 0.01), "match grades never modify adventure definitions")
	game.match_state.rows[0][9] = 0
	fighter.combat.replica_view = false
	check(game.combat.receive(20, Vector3.ZERO, Damageable.HitKind.SOY, Vector3.ZERO, null, 0), "armoured target accepts actual hit")
	var commands: Array[PlayerCommand] = []
	commands.resize(20)
	game.combat.step(commands, 0, 0)
	check(is_equal_approx(game.match_state.rows[0][8], 85), "actual damage applies twenty-five percent protection")

func _food() -> void:
	var fighter := game.combat.fighters[0]
	var heal := game.pack.healing[0]
	game.match_state.rows[0][8] = 30
	check(game.pack.transactions.consume(0, 1, 8), "Soy Milk starts gradual healing")
	check(fighter.loadout.equipment.get_slot("support_1") == null and heal.active_heal_remaining == 50, "milk is finite, with adventure fifty HP effect")
	check(not game.pack.transactions.consume(0, 1, 9), "shared food cooldown prevents spam")
	game.pack.step(1)
	check(is_equal_approx(game.match_state.rows[0][8], 50) and is_equal_approx(heal.active_heal_remaining, 30), "milk heals over time, not instantly")
	game.pack.step(1.5)
	check(is_equal_approx(game.match_state.rows[0][8], 80), "milk completes over two and a half seconds")
	fighter.combat.vitals.current = 20
	check(game.pack.transactions.consume(0, 1, 9), "apples use the next support slot")
	check(fighter.loadout.equipment.get_slot("support_2").count == 1, "apple count decreases exactly once")
	game.pack.step(5)
	check(is_equal_approx(game.match_state.rows[0][8], 90) and is_equal_approx(fighter.combat.vitals.current, 30) and is_equal_approx(heal.apple_duration_remaining, 20), "apples retain adventure health and stamina regeneration")
	var bag := fighter.loadout.inventory
	bag.set_slot(0, ItemStack.new(BattleItems.make(29), 2))
	check(game.pack.transactions.consume(0, 0, 0), "vegetables can be used from the backpack")
	check(not game.pack.transactions.consume(0, 0, 0) and bag.get_slot(0).count == 1, "bag food respects the same cooldown")
	game.pack.capture(true)
	check(BattlePackWire.packs(game.match_state.pack), "partial healing and all equipped items fit bounded wire")

func _cpu_gear() -> void:
	var fighter := game.combat.fighters[19]
	var initial: Array = game.match_state.pack[19]
	check(not BattlePackBots.wants(initial, 1) and not BattlePackBots.wants(initial, 24), "CPUs leave duplicate starter weapons and smaller bags for others")
	check(BattlePackBots.wants(initial, 26) and BattlePackBots.wants(initial, 28), "CPUs pursue bigger bags and finite healing")
	for i in 4: fighter.loadout.inventory.set_slot(i, ItemStack.new(BattleItems.make(12 + i), 1))
	BattlePackBots.equip(game.pack, 19)
	check(fighter.loadout.equipment.complete_set() == "bright_leaf", "CPUs wear found armour through normal atomic transfers")
	for kind in [3, 9, 1]:
		fighter.loadout.inventory.clear()
		fighter.loadout.inventory.set_slot(0, ItemStack.new(BattleItems.make(kind), 1))
		BattlePackBots.equip(game.pack, 19)
	check(fighter.loadout.equipment.get_slot("combat_1").item.id == "celestial_sword", "CPUs upgrade common to rare to legendary and never downgrade")
	for i in 4:
		fighter.loadout.inventory.set_slot(i, ItemStack.new(BattleItems.make(20 + i), 1))
	BattlePackBots.equip(game.pack, 19)
	check(fighter.loadout.equipment.complete_set() == "celestial", "CPUs pursue the strongest full set over a weaker completed family")
	game.match_state.rows[19][8] = 35
	BattlePackBots.heal(game.pack, 19)
	check(fighter.loadout.equipment.get_slot("support_1") == null and game.pack.healing[19].active_heal_remaining == 50, "CPU healing spends actual consumables")

func _identical_weapons() -> void:
	var fighter := game.combat.fighters[1]
	for i in 2:
		var stack := ItemStack.new(BattleItems.make(7), 1)
		stack.reserve = 32.75 if i == 0 else 60.25
		fighter.loadout.equipment.set_slot("combat_%d" % (i + 1), stack)
	game.pack.refresh(1)
	var command := PlayerCommand.new()
	command.weapon_slot = 1
	game.combat.prepare(1, command)
	check(fighter.loadout.active_slot == 1 and is_equal_approx(fighter.combat.sotjet.milk, 32.75), "identical weapon kinds still select their own inventory slot")
	fighter.combat.sotjet.milk = 24.5
	command.weapon_slot = 2
	game.combat.prepare(1, command)
	check(fighter.loadout.active_slot == 2 and is_equal_approx(fighter.combat.sotjet.milk, 60.25), "second Sotjet retains its own finite reservoir")
	check(is_equal_approx(fighter.loadout.equipment.get_slot("combat_1").reserve, 24.5), "switching identical weapons persists the spent first reservoir")

func _controls() -> void:
	var event := InputEventAction.new()
	event.action = "toggle_inventory"
	event.pressed = true
	root.push_input(event)
	await process_frame
	check(game.pack_ui.bag.visible, "B action opens the actual match backpack")
	game._physics_process(0)
	check(not game.local_input.enabled and game.playing, "bag blocks local attacks while the match keeps running")
	event.action = "ui_cancel"
	root.push_input(event)
	await process_frame
	check(not game.pack_ui.blocked() and not game.hud.exit_panel.visible, "Escape closes the item window without opening Leave")
	event.action = "toggle_character"
	root.push_input(event)
	await process_frame
	check(game.pack_ui.page == "stats" and game.pack_ui.panel.visible, "I action opens actual match stats")
	game.pack_ui.close()

func _requests() -> void:
	var requests := game.pack.requests
	var bag := game.combat.fighters[0].loadout.inventory
	bag.clear()
	bag.set_slot(0, ItemStack.new(BattleItems.make(12), 1))
	requests.request(2, [0, 0, 1, 0])
	game.pack.refresh(0)
	requests.flush(game.simulation.clock + 0.101, 0)
	check(bag.get_slot(0) != null, "stale UI revision cannot swap a different item")
	var before := requests.queue.size()
	requests.receive("f".repeat(64), {"kind": "br_pack", "epoch": game.room.epoch, "term": game.room.term, "seq": 1, "revision": 1, "action": 1, "args": [0]})
	check(requests.queue.size() == before, "unadmitted identity cannot manipulate inventory")
	requests.request(2, [0, 0, 1, 0])
	requests.flush(game.simulation.clock + 0.101, 0)
	check(game.combat.fighters[0].loadout.equipment.get_slot("helmet").item.id == "bright_leaf_helmet", "fresh revision applies through delayed authority path")
	var replay := requests.sequence
	requests.receive(game.room.local_key, {"kind": "br_pack", "epoch": game.room.epoch, "term": game.room.term, "seq": replay, "revision": game.pack.revisions[0], "action": 4, "args": [1, 0]})
	check(requests.queue.is_empty(), "sequence replay cannot repeat a gear action")
	var drop: Array = game.match_state.drops[1]
	var at := Vector3(drop[1], drop[2], drop[3])
	game.bodies[0].position = at + Vector3.RIGHT * 15
	check(not game.pack.transactions.take(0, drop[0]), "range is rechecked before taking")
	game.bodies[0].position = at + Vector3.RIGHT * 2
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.3, 3, 3)
	shape.shape = box
	wall.add_child(shape)
	wall.position = at + Vector3(1, 1, 0)
	game.add_child(wall)
	await physics_frame
	check(not game.pack.transactions.take(0, drop[0]), "loot cannot be taken through solid cover")
	wall.queue_free()
	await physics_frame

func _checkpoint() -> void:
	game.pack.capture(true)
	game.recovery.publish()
	var saved := BattleCheckpoint.decode(game.room.migration.checkpoint, game.room.members)
	check(not saved.is_empty(), "inventory-bearing recovery checkpoint is valid")
	if saved.is_empty(): return
	var expected := JSON.stringify(BattleCombatWire.precision(saved.pack))
	var chest_state := JSON.stringify(saved.chests)
	var drop_state := JSON.stringify(saved.drops)
	game.combat.fighters[0].loadout.inventory.clear()
	game.pack.healing[0].apple_duration_remaining = 0
	game.match_state.chests[0][4] = 0
	game.recovery.restore(saved)
	game.pack.capture(true)
	check(JSON.stringify(game.match_state.pack) == expected, "host recovery restores exact bags, gear, healing and revisions")
	check(JSON.stringify(game.match_state.chests) == chest_state and JSON.stringify(game.match_state.drops) == drop_state, "opened chests and unclaimed items survive recovery without rerolls")
	check(game.pack.healing[0].apple_duration_remaining > 0, "ongoing apple effect survives recovery")
	check(game.pack.requests.queue.is_empty(), "old inventory intents cannot replay after promotion")

func _wire() -> void:
	var malformed := game.match_state.pack.duplicate(true)
	malformed[0][2][8] = [28, 11, 0]
	check(not BattlePackWire.packs(malformed), "milk stack above actual capacity is rejected")
	malformed[0][2][8] = [12, 1, 0]
	check(not BattlePackWire.packs(malformed), "armour cannot arrive in a support slot")
	var baseline: Array = [game.match_state.pack.duplicate(true), game.match_state.chests.duplicate(true), game.match_state.drops.duplicate(true)]
	var packet := {"pack": baseline[0].duplicate(true), "chests": baseline[1].duplicate(true), "drops": baseline[2].duplicate(true)}
	packet.pack[0][3][4] = 12.5
	BattlePackDelta.compact(packet, baseline, 42, false)
	check(packet.pack_delta[0].size() == 1 and packet.pack_delta[1].is_empty() and packet.pack_delta[2].is_empty(), "a healing tick sends only the changed actor bag")
	check(JSON.stringify(packet).length() < 160 and BattlePackDelta.expand(packet, baseline) and packet.pack[0][3][4] == 12.5, "healing-only changes omit all bag and equipment contents and reconstruct exact state")
	var hostile := {"pack_delta": [[[20, []]], [], []]}
	check(not BattlePackDelta.expand(hostile, baseline), "fixed-size player pack cannot be extended by a delta")
	check(BattleProtocol.command([0.708, 0.707, 0, 1, 0]), "rounded joystick diagonals stay inside command bounds")
	var state := BattleCheckpoint.decode(game.room.migration.checkpoint, game.room.members)
	state.motors[0][12] = 0.708
	state.motors[0][13] = 0
	state.motors[0][14] = 0.708
	state.actors[0][20] = 0.708
	state.actors[0][21] = 0.708
	check(not BattleCheckpoint.decode(JSON.stringify(state), game.room.members).is_empty(), "millimetre-rounded diagonal movement remains recoverable")
	var members: Array = []
	state.voters = []
	for slot in BattleProtocol.CAPACITY:
		if slot < BattleProtocol.HUMAN_CAPACITY:
			var key := "%064x" % (slot + 1)
			members.append({"key": key, "name": "Test", "skin": 0})
			state.voters.append(key)
		if slot >= 20:
			for field in ["actors", "pack", "combat", "motors", "stats"]: state[field].append(state[field][0].duplicate(true))
			state.mobs[1].append(0)
			state.cooldowns.append(0.0)
			state.reloads.append(0.0)
		state.actors[slot][17] = int(slot >= 20)
		state.actors[slot][12] = 69
		state.actors[slot][13] = 70
		var pack: Array = state.pack[slot]
		pack[2][4] = [26, 1, 0]
		pack[1] = []
		for i in 20:
			var kind := (slot * 7 + i) % 32 + 1
			var count := (10 if kind == 28 else 50) if kind >= 27 else 1
			pack[1].append([kind, count, (slot * 13 + i * 3) % 100 + 0.123])
	while state.mobs[0].size() < BattleMobWire.LIMIT:
		state.mobs[0].append(state.mobs[0][0].duplicate(true))
	for row: Array in state.mobs[0]: row[14] = [2.8, 0.85, 0.708, 0, 0.707, 345.125, 123.123, -342.999, 23.456, 0, 26.789, 3.123, 999999]
	state.chests = []
	for i in 80: state.chests.append([i, -342.999 + i, 99.999, -342.999 + i, 1])
	state.drops = []
	for i in BattlePackWire.DROPS:
		var kind := i % 32 + 1
		state.drops.append([999000 + i, -342.999 + i * 0.25, 99.999, -342.999 + i * 0.3, kind, 1, i % 100 + 0.123])
	state.options = [50, 1]
	state.deployment = BattleDeploymentState.create(game.match_state.deployment.sites.duplicate(true), 70)
	BattleDeploymentState.complete(state.deployment, state.options)
	state.deployment.stage = 2
	state.deployment.remaining = 0.0
	var value: Dictionary = BattleCombatWire.precision(state)
	var blob := BattleWire.encode(value)
	print("Worst 70-survivor checkpoint: raw=", JSON.stringify(value).to_utf8_buffer().size(), " encoded=", blob.length())
	check(not blob.is_empty() and not BattleCheckpoint.decode(blob, members).is_empty(), "seventy full bags and maximum world items fit bounded recovery")
	var frame := JSON.stringify({"type": "broadcast", "keys": state.voters, "data": {"kind": "br_checkpoint", "blob": blob}})
	check(frame.to_utf8_buffer().size() < 65536, "largest inventory checkpoint fits actual transport framing")
	value.kind = "br_state"
	value.epoch = game.room.epoch
	value.term = 0
	var packed := BattleWire.packet(value)
	check(JSON.stringify({"type": "broadcast", "keys": state.voters, "data": packed}).to_utf8_buffer().size() < 65536, "maximum large-roster keyframe fits one authenticated frame")
	check(BattleProtocol.snapshot(BattleWire.restore(packed)), "maximum compressed keyframe restores every bounded actor and item")

func _death() -> void:
	var fighter := game.combat.fighters[0]
	var bag := fighter.loadout.inventory
	bag.clear()
	bag.set_slot(0, ItemStack.new(BattleItems.make(7), 1))
	bag.get_slot(0).reserve = 32.75
	game.pack.refresh(0)
	var expected := 0
	for stack in bag.slots:
		if stack != null: expected += 1
	for name in CharacterEquipment.SLOTS:
		if fighter.loadout.equipment.get_slot(name) != null: expected += 1
	var before := _active_drops()
	game.match_state.rows[0][8] = 0
	game.pack.step(0)
	check(_active_drops() == before + expected and bag.count_item("sotjet") == 0, "elimination drops the whole bag and worn gear once")
	game.pack.step(0)
	check(_active_drops() == before + expected, "dead actors never duplicate their backpack")
	var found := false
	for drop: Array in game.match_state.drops:
		if drop[4] == 7 and is_equal_approx(drop[6], 32.75): found = true
	check(found, "dropped Sotjet keeps its finite reservoir")
	check(game.pack.healing[0].apple_duration_remaining == 0 and game.pack.healing[0].active_heal_remaining == 0, "death clears pending healing without resurrection")
	var fresh := BattleMatch.new()
	var positions: Array[Vector3] = []
	positions.resize(20)
	fresh.initialize(positions, 1)
	check(fresh.pack.is_empty() and fresh.drops.is_empty() and fresh.chests.is_empty(), "new matches cannot inherit old RPG loot")

func _active_drops() -> int:
	var count := 0
	for drop: Array in game.match_state.drops:
		if drop[5] > 0: count += 1
	return count
