extends SceneTree
## Received damage, partial gear, complete sets, death loot and broad seeded finales.
var failures: int = 0
var game: BattleRoyaleGame

func _initialize() -> void: _run.call_deferred()
func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", label)

func _run() -> void:
	var room := BattleRoom.new()
	room.options = [3, 1]
	root.add_child(room)
	room.practice()
	game = BattleRoyaleGame.new()
	game.room = room
	root.add_child(game)
	while not game.composed: await physics_frame
	BattleTestDeployment.finish(game)
	game.set_physics_process(false)
	game.combat.process_mode = Node.PROCESS_MODE_DISABLED
	game.match_state.time = 13
	_armour()
	await _transfers()
	_death()
	_pending_death()
	_storm()
	game.queue_free()
	room.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("Battle survival/loot/integrity: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _wear(kinds: Array) -> void:
	var equipment := game.combat.fighters[0].loadout.equipment
	for i in 4: equipment.set_slot(CharacterEquipment.APPAREL_SLOTS[i], ItemStack.new(BattleItems.make(kinds[i]), 1) if kinds[i] > 0 else null)
	game.pack.refresh(0)

func _armour() -> void:
	var fighter := game.combat.fighters[0]
	_wear([20, 0, 0, 0])
	check(is_equal_approx(fighter.health.armor_multiplier, 0.9375) and is_equal_approx(fighter.combat.gun.damage_multiplier, 1.05), "one Celestial piece grants exactly a quarter of its protection and damage bonus")
	_wear([20, 17, 14, 23])
	game._update_hud()
	var flash := game.match_view.tactical.damage_flash
	flash.remaining = 0
	flash.hide()
	var before: float = game.match_state.stats[0][BattleRoundStats.TAKEN]
	check(game.combat.receive(20 / fighter.health.armor_multiplier, Vector3.ZERO, Damageable.HitKind.SOY, Vector3.ZERO, game.combat.fighters[1].health, 0), "enemy hit enters shared combat")
	var commands: Array[PlayerCommand] = [null, null, null, null]
	game.combat.step(commands, 0, 0)
	check(is_equal_approx(game.match_state.stats[0][1] - before, 20) and is_equal_approx(game.match_state.rows[0][9], 30), "wear uses actual received damage including the armour bar")
	for name in CharacterEquipment.APPAREL_SLOTS:
		check(is_equal_approx(BattleArmourWear.remaining(fighter.loadout.equipment.get_slot(name)), 45), "twenty damage shares five durability across four mixed pieces")
	game._update_hud()
	check(flash.visible and flash.remaining > 0, "confirmed damage triggers a visible HUD vignette")
	flash._process(0.12)
	var low := float(flash.shader.get_shader_parameter("strength"))
	flash._process(0.12)
	check(float(flash.shader.get_shader_parameter("strength")) > low, "damage vignette pulses again before fading")
	flash._process(1)
	check(not flash.visible, "damage vignette disappears promptly")
	game.pack_ui.show_bag()
	game.match_view.tactical.feedback(false, true, false)
	game._update_hud()
	check(not game.match_view.tactical.visible and flash.is_visible_in_tree(), "damage stays visible above an open inventory")
	game.pack_ui.close()
	game.room.phase = "recovering"
	game._update_hud()
	check(not flash.visible and flash.remaining == 0, "paused recovery clears transient damage flashes")
	game.room.phase = "playing"
	_wear([20, 17, 0, 0])
	fighter.loadout.equipment.get_slot("armor").reserve = 20
	BattleArmourWear.damage(game.pack, 0, 20)
	check(fighter.loadout.equipment.get_slot("armor") == null and is_equal_approx(BattleArmourWear.remaining(fighter.loadout.equipment.get_slot("helmet")), 40), "two pieces share damage; exhausted piece breaks and is removed")
	check(is_equal_approx(fighter.health.armor_multiplier, 0.9375), "broken piece immediately loses its protection")
	_wear([20, 21, 22, 23])
	var helmet := fighter.loadout.equipment.get_slot("helmet")
	helmet.reserve = 40
	BattleArmourWear.damage(game.pack, 0, 100)
	check(helmet.reserve == 40 and fighter.loadout.equipment.complete_set() == "celestial", "complete matching set remains intact without repairing existing wear")
	fighter.loadout.equipment.set_slot("boots", null)
	BattleArmourWear.damage(game.pack, 0, 15)
	check(is_equal_approx(BattleArmourWear.remaining(helmet), 15), "removing a set piece resumes shared wear without a repair exploit")

func _transfers() -> void:
	var fighter := game.combat.fighters[0]
	var at := game.world.ground_point(-22, -22, 0.08)
	game.bodies[0].position = at
	await physics_frame
	fighter.loadout.inventory.clear()
	var piece := ItemStack.new(BattleItems.make(20), 1)
	piece.reserve = 34
	check(game.pack.spawn(piece, at), "damaged armour can be dropped")
	var id: int = game.match_state.drops.back()[0]
	check(game.pack.transactions.take(0, id), "damaged armour can be picked up")
	check(is_equal_approx(BattleArmourWear.remaining(fighter.loadout.inventory.get_slot(0)), 17), "world drop and bag copies retain exact remaining durability")
	check(game.pack.transactions.transfer(0, 0, 0, 1, 0), "damaged piece equips through normal transaction")
	game.pack.capture(true)
	var saved := game.match_state.pack.duplicate(true)
	fighter.loadout.equipment.get_slot("helmet").reserve = 100
	game.pack.restore(saved)
	check(is_equal_approx(BattleArmourWear.remaining(fighter.loadout.equipment.get_slot("helmet")), 17), "recovery restores wear rather than granting fresh armour")

func _death() -> void:
	var victim := game.combat.fighters[2]
	victim.loadout.equipment.set_slot("backpack", ItemStack.new(BattleItems.make(26), 1))
	var kinds := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 28, 27, 32]
	for i in 20:
		var stack := ItemStack.new(BattleItems.make(kinds[i]), 2 if kinds[i] >= 27 else 1)
		stack.reserve = 5 + i
		victim.loadout.inventory.set_slot(i, stack)
	for i in 4: victim.loadout.equipment.set_slot(CharacterEquipment.APPAREL_SLOTS[i], ItemStack.new(BattleItems.make(20 + i), 1))
	game.pack.refresh(2)
	game.bodies[2].position = game.world.ground_point(-21, -22, 8)
	var expected := _carried(2)
	var expected_items: Array[String] = []
	for stack in victim.loadout.inventory.slots: expected_items.append(JSON.stringify(BattleItems.encode(stack)))
	for name in CharacterEquipment.SLOTS:
		var stack := victim.loadout.equipment.get_slot(name)
		if stack != null: expected_items.append(JSON.stringify(BattleItems.encode(stack)))
	expected_items.sort()
	var first_drop := game.pack.next_drop
	var before := _count()
	game.match_state.hit(2, 10000, 0)
	game.pack.step(0)
	check(_count() == before + expected and victim.loadout.inventory.capacity == 0, "elimination releases every bag slot and equipped item, including backpack")
	var found: Array[String] = []
	for drop: Array in game.match_state.drops:
		if drop[0] >= first_drop and drop[5] > 0:
			found.append(JSON.stringify(BattleCombatWire.precision([drop[4], drop[5], drop[6]])))
			check(float(drop[2]) < game.bodies[2].position.y - 5, "airborne elimination loot lands below the dead survivor")
	found.sort()
	check(found == expected_items, "every weapon, food count, armour piece and resource value survives the whole-kit drop exactly")
	for name in CharacterEquipment.SLOTS: check(victim.loadout.equipment.get_slot(name) == null, "no equipment remains on an eliminated survivor")
	game.pack.capture(true)
	check(BattleProtocol.snapshot(game.match_state.capture()), "empty eliminated inventory is a valid bounded snapshot")
	var saved := game.match_state.pack.duplicate(true)
	game.pack.restore(saved)
	game.pack.step(0)
	check(_count() == before + expected, "recovery cannot duplicate death loot or create a replacement backpack")

func _pending_death() -> void:
	game.match_state.drops.clear()
	for i in BattlePackWire.DROPS: game.match_state.drops.append([i, 0, 0, 0, 27, 1, 100])
	game.pack.next_drop = BattlePackWire.DROPS
	var count := _carried(3)
	game.match_state.hit(3, 10000, 0)
	game.pack.step(0)
	check(_carried(3) == count, "saturated drop ledger never deletes death equipment")
	game.pack.capture(true)
	game.pack.restore(game.match_state.pack.duplicate(true))
	for i in count: game.match_state.drops[i][5] = 0
	game.pack.step(0)
	check(_carried(3) == 0 and _count() == BattlePackWire.DROPS, "pending death loot retries after recovery when enough slots become free")

func _storm() -> void:
	var points := BattleStormLayout.candidates(game)
	var regions: Dictionary = {}
	var distant := false
	for point in points:
		regions[BattleStormLayout.region(point)] = true
		distant = distant or point.distance_to(BattleRing.CENTER) > 300
		check(not game.world.is_water(game.world.ground_point(point.x, point.y, 0.08)), "finales stay on supported dry land")
	check(regions.size() >= 3 and distant, "actual map offers distant finale regions beyond the old nursery cap")
	var picks: Dictionary = {}
	for seed in 1200:
		var at := BattleStormLayout.pick(points, seed)
		var region := BattleStormLayout.region(at)
		picks[region] = int(picks.get(region, 0)) + 1
		check(at == BattleStormLayout.pick(points, seed), "same match seed cannot reroll the finale")
	for count: int in picks.values(): check(absf(count / 1200.0 - 1.0 / regions.size()) < 0.06, "supported regions have equal selection odds")
	print("Finale candidates/regions/distribution: ", points.size(), " / ", regions.size(), " / ", picks)
	check(BattleRing.total_time() < 800, "expanded map keeps a bounded match duration")

func _carried(slot: int) -> int:
	var loadout := game.combat.fighters[slot].loadout
	var count := 0
	for stack in loadout.inventory.slots:
		if stack != null: count += 1
	for name in CharacterEquipment.SLOTS:
		if loadout.equipment.get_slot(name) != null: count += 1
	return count

func _count() -> int:
	var count := 0
	for drop: Array in game.match_state.drops:
		if drop[5] > 0: count += 1
	return count
