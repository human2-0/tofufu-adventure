extends SceneTree
## Tier probabilities, atomic enhancement, actual combat modifiers and recovery.
var failures: int = 0
var game: BattleRoyaleGame

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: return
	failures += 1
	printerr("FAIL: ", label)

func _run() -> void:
	_loot()
	var room := BattleRoom.new()
	root.add_child(room)
	room.options = [2, 1]
	room.practice()
	game = BattleRoyaleGame.new()
	game.preferences.path = "user://battle-upgrades-%d.cfg" % Time.get_ticks_usec()
	game.room = room
	root.add_child(game)
	while not game.composed: await physics_frame
	BattleTestDeployment.finish(game)
	game.set_physics_process(false)
	game.combat.process_mode = Node.PROCESS_MODE_DISABLED
	game.match_state.time = 13
	var tiers := [0, 0, 0]
	for chest: Array in game.match_state.chests: tiers[int(chest[5])] += 1
	check(game.match_state.chests.size() == 192 and tiers == [125, 52, 15], "dense world has fixed geographic-neutral tier quotas")
	_upgrade()
	await _drop_and_recovery()
	_cpu()
	await _full_chest()
	await _results()
	_wire()
	game.queue_free()
	room.queue_free()
	await process_frame
	await process_frame
	print("Royale tiers and enhancements: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _loot() -> void:
	var chunk_totals := [0, 0, 0]
	var legendary_totals := [0, 0, 0]
	for tier in 3:
		for id in 6000:
			var choices := BattleChestLoot.contents("chest-tier-proof", id, tier)
			check(choices == BattleChestLoot.contents("chest-tier-proof", id, tier), "seeded choices cannot reroll")
			check(choices.size() in [4, 5] and choices[0] <= 11 and choices[1] >= 12 and choices[1] <= 26 and choices[2] >= 27 and choices[2] <= 32, "every chest supplies weapon, protection and food")
			if choices.has(33): chunk_totals[tier] += 1
			for kind in choices.slice(0, 4):
				if BattleRarity.grade(kind) == 2: legendary_totals[tier] += 1
			if tier == 2: check(BattleRarity.grade(choices[0]) == 2 and BattleRarity.grade(choices[1]) == 2, "legendary chest guarantees legendary weapon and protection")
		check(absf(float(chunk_totals[tier]) / 6000 - BattleChestLoot.CHUNK_CHANCE[tier]) < 0.025, "tier chunk percentage within sampling tolerance")
	check(legendary_totals[0] < legendary_totals[1] and legendary_totals[1] < legendary_totals[2], "gear quality increases with tier")
	print("6000 chests per tier: chunks=", chunk_totals, " legendary=", legendary_totals)

func _upgrade() -> void:
	var fighter := game.combat.fighters[0]
	var loadout := fighter.loadout
	loadout.inventory.set_slot(0, ItemStack.new(BattleItems.make(33), 3))
	loadout.select(2)
	fighter.combat.gun.magazine = 3
	fighter.combat.gun.cooldown = 0.17
	fighter.combat.gun.reload_remaining = 0.7
	var weapon := loadout.equipment.get_slot("combat_2")
	game.pack.requests.request(2, [0, 0, 1, 7])
	check(not weapon.enhanced, "host enhancement waits through the same intent delay")
	game.pack.requests.flush(game.simulation.clock + 0.11, 0)
	check(weapon.enhanced and loadout.inventory.get_slot(0).count == 2, "one chunk is consumed atomically")
	var gun := fighter.combat.gun
	check(gun.magazine_capacity == 14 and gun.magazine == 3 and is_equal_approx(gun.cooldown, 0.17) and is_equal_approx(gun.reload_remaining, 0.7), "upgrade grows capacity without refilling or resetting cadence")
	check(is_equal_approx(gun.enhancement_multiplier, 1.2) and is_equal_approx(gun.attack_speed_multiplier, 1.1) and is_equal_approx(gun.projectile_speed_multiplier, 1.2) and is_equal_approx(gun.spread_multiplier, 0.75), "gun gains power, accuracy, fire rate and faster bullets")
	check(is_equal_approx(gun.tuning.bean_speed * gun.projectile_speed_multiplier * gun.projectile_lifetime, 90), "faster bullets preserve reach")
	check(not game.pack.transactions.transfer(0, 0, 0, 1, 7) and loadout.inventory.get_slot(0).count == 2, "enhancement cannot stack or consume another chunk")
	check(game.pack.transactions.transfer(0, 0, 0, 1, 6), "same material enhances a melee weapon")
	gun.magazine = 14
	loadout.select(1)
	check(gun.magazine == 14 and gun.magazine_capacity == 14, "switching to melee preserves the upgraded gun's loaded rounds")
	loadout.select(2)
	check(gun.magazine == 14, "returning to enhanced gun retains all fourteen rounds")
	loadout.select(1)
	fighter.combat.vitals.current = 100
	check(fighter._pay_guard(20) and is_equal_approx(fighter.combat.vitals.current, 87), "enhanced melee reflection costs 35 percent less SP")
	check(is_equal_approx(fighter.combat.attack_speed_multiplier, 1.1), "enhanced melee attacks faster")
	var normal := InventoryItem.weapon("soy_gun")
	check(normal.required_level == 1 and MagicalTofufu.DROP_CHANCE == 0.001, "adventure item rules and mob odds stay independent")
	var body := game.pack_ui.bag
	body.open()
	body.execute_transfer("inventory", 0, "equipment", "combat_1")
	check(not body.enhancement_confirmation.visible, "already enhanced weapon does not open another spending dialog")
	body.close()

func _drop_and_recovery() -> void:
	var fighter := game.combat.fighters[0]
	check(game.pack.transactions.drop(0, 1, 6), "enhanced weapon can be dropped")
	var drop: Array = game.match_state.drops.back()
	check(drop.size() == 8 and drop[7] == true and BattlePackWire.world(game.match_state.chests, game.match_state.drops), "world drop retains validated per-weapon enhancement")
	game.bodies[0].position = Vector3(drop[1], drop[2], drop[3])
	await physics_frame
	check(game.pack.transactions.take(0, drop[0]) and fighter.loadout.inventory.get_slot(1).enhanced, "pickup retains enhancement")
	game.recovery.publish()
	var saved := BattleCheckpoint.decode(game.room.migration.checkpoint, game.room.members)
	check(not saved.is_empty(), "enhancement checkpoint validates")
	if saved.is_empty(): return
	fighter.loadout.inventory.clear()
	game.recovery.restore(saved)
	check(fighter.loadout.inventory.get_slot(1).enhanced and fighter.loadout.equipment.get_slot("combat_2").enhanced, "host recovery restores bag and equipped upgrades")
	check(fighter.combat.gun.magazine == 14 and fighter.combat.gun.magazine_capacity == 14, "recovery retains the stowed enhanced magazine")
	check(fighter.loadout.inventory.get_slot(0).count == 1, "recovery retains exactly spent chunks")
	check(game.pack.transactions.drop_all(0), "elimination spills the complete enhanced kit")
	check(game.match_state.drops.any(func(row: Array) -> bool: return row[5] > 0 and row.size() == 8), "enhanced death loot stays available")

func _cpu() -> void:
	var loadout := game.combat.fighters[1].loadout
	loadout.inventory.set_slot(0, ItemStack.new(BattleItems.make(33), 2))
	BattlePackBots.equip(game.pack, 1)
	check(loadout.equipment.get_slot("combat_1").enhanced and loadout.equipment.get_slot("combat_2").enhanced and loadout.inventory.get_slot(0) == null, "CPU spends the same two finite chunks on its weapons")

func _full_chest() -> void:
	var chest: Array = []
	for row: Array in game.match_state.chests:
		if BattleChestLoot.contents(game.room.epoch, int(row[0]), int(row[5])).size() == 5:
			chest = row
			break
	check(not chest.is_empty(), "seed includes a chunk-bearing chest")
	if chest.is_empty(): return
	game.bodies[1].position = Vector3(chest[1], chest[2], chest[3]) + Vector3(0, 0, 2.4)
	await physics_frame
	game.match_state.drops.clear()
	for i in BattlePackWire.DROPS - 4: game.match_state.drops.append([i, 0, 0, 0, 27, 1, 100])
	check(not BattleChestLoot.open(game.pack, 1, int(chest[0])) and chest[4] == 0 and game.match_state.drops.size() == BattlePackWire.DROPS - 4, "four free ledger entries cannot partially open a five-item chest")
	game.match_state.drops[0][5] = 0
	game.pack.next_drop = BattlePackWire.DROPS
	check(BattleChestLoot.open(game.pack, 1, int(chest[0])) and chest[4] == 1, "fifth available entry atomically permits the complete chest spill")
	game.match_state.drops.clear()

func _results() -> void:
	var state := BattleMatch.new()
	var positions: Array[Vector3] = [Vector3.ZERO, Vector3(4, 0, 0), Vector3(8, 0, 0)]
	state.initialize(positions, 1, [2, 1])
	state.time = 13
	state.stats[0] = [160, 20, 3, 1, 120, 0]
	for slot in [1, 2]: state.hit(slot, 1000, 0)
	state.step(0.01)
	var summary := BattleRoundStats.summary(state, 0)
	check(summary.rewards.reduce(func(a: int, b: int) -> int: return a + b, 0) == summary.xp, "graphical reward breakdown equals actual career award")
	var panel := BattleResultPanel.new()
	root.add_child(panel)
	panel.display(summary, 90, 2)
	panel.show()
	await create_timer(2).timeout
	check(roundi(panel.xp.shown_xp) == 90 + summary.xp and panel.xp.bar.value < panel.xp.bar.max_value, "XP animation crosses levels and ends at the exact reward")
	check(panel.xp.celebration.text.contains("2") and panel.metrics.values.size() == 6, "recap shows a level celebration and six icon metrics")
	check(panel.xp.size.y < 140 and panel.xp.gain_label.size.x >= 100, "XP reward remains a compact readable row")
	root.size = Vector2i(640, 360)
	root.content_scale_size = root.size
	await process_frame
	await process_frame
	check(panel.size.x <= 608 and panel.size.y <= 328, "compact result panel stays within the viewport")
	panel.queue_free()

func _wire() -> void:
	check(BattlePackWire.stack([2, 1, 100, true]), "enhanced weapon wire accepted")
	check(not BattlePackWire.stack([27, 1, 100, true]), "food cannot carry forged enhancement")
	check(not BattlePackWire.stack([2, 1, 100, 1]), "integer enhancement flags rejected")
	check(BattlePackWire.stack([33, 50, 100]) and not BattlePackWire.stack([33, 51, 100]), "chunks have a bounded material stack")
	check(not BattlePackWire.world([[0, 0, 0, 0, 0, 3]], []), "unknown chest rarity rejected")
