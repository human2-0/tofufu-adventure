extends SceneTree
## Real jungle roster, committed claws, rare loot, training, rift and persistence.

var failures: int = 0
var game: AdventureGame

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	game = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.weather.set_physics_process(false)
	for mob in game.encounters.mob_nodes:
		mob.set_physics_process(false)
		mob.target.set_physics_process(false)
	await physics_frame
	await physics_frame
	_roster()
	var cat := game.encounters.mob_nodes[59] as BengalMonster
	_claws(cat)
	_views(cat)
	await _weapon(cat)
	_localization()
	_loot(cat)
	game.queue_free()
	await process_frame
	print("Bengal: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _roster() -> void:
	check(game.encounters.mob_nodes.size() == 71, "twelve Bengals append after all 59 legacy encounters")
	for index in range(59, 71):
		var cat := game.encounters.mob_nodes[index] as BengalMonster
		check(cat != null and cat.target.maximum == 240 and cat.tuning.dry_damage == 30, "level fifteen authored strength")
		check(BengalGrounds.contains(cat.position), "spawn stays in jungle grinding grounds")
		check(absf(cat.position.y - game.world.ground_point(cat.position.x, cat.position.z).y - 0.1) < 0.01, "spawn shares actual terrain height")
		check(cat._home_is_clear(), "spawn capsule clears scenery and other cats")
		cat.set_rain(true)
		check(cat.available and cat.target.maximum == 240, "renewable Bengals retain strength in rain")
		cat.set_rain(false)
	var world := CoopWorld.capture(game)
	check(WorldProtocol.valid(world), "expanded world validates")
	var legacy := world.duplicate(true)
	legacy.mobs.resize(59)
	legacy.erase("mob_paralysis")
	check(WorldProtocol.valid(legacy), "older 59-mob checkpoints remain accepted")
	world.mobs[59][6] = 241
	check(not WorldProtocol.valid(world), "Bengal HP is bounded independently of other mobs")

func _claws(cat: BengalMonster) -> void:
	cat.quarry = game.player
	game.player.position = cat.position + Vector3.BACK * 6
	var motion := cat._choose_direction(0.01)
	check(is_equal_approx(motion.length(), 5.6) and cat.facing.dot(Vector3.BACK) > 0.99, "fast pursuit faces actual running direction")
	var hits: Array[float] = []
	cat.attacked.connect(func(amount: float, _at: Vector3) -> void: hits.append(amount))
	game.player.position = cat.position + Vector3.BACK * 1.2
	cat._choose_direction(0.01)
	check(is_equal_approx(cat._windup, 0.42), "readable claw warning")
	game.player.position.x += 3
	cat._choose_direction(0.43)
	check(hits.is_empty() and cat.claw_time > 0, "committed claw can be dodged and has an attack pose")
	cat._rest = 0
	game.player.position = cat.position + Vector3.BACK * 1.2
	cat._choose_direction(0.01)
	cat._choose_direction(0.43)
	check(hits == [30.0], "close claw deals authored damage once")
	cat.target.paralyze(4)
	cat.velocity = Vector3.RIGHT * 5.6
	cat._physics_process(1.0 / 60)
	check(cat.velocity.x == 0 and cat.velocity.z == 0 and hits.size() == 1, "paralysis stops running and attack decisions")
	cat.target.damage(1)
	check(cat.target.paralysis == 4, "normal hit reactions cannot shorten paralysis")
	cat.target._physics_process(3.99)
	check(cat.target.paralysis > 0, "paralysis lasts until four seconds")
	cat.target._physics_process(0.011)
	check(cat.target.paralysis == 0, "paralysis expires after four seconds")
	cat.target.current = 240

func _views(cat: BengalMonster) -> void:
	var forward := game.camera.global_basis.z
	forward.y = 0
	forward = forward.normalized()
	var right := Vector3(forward.z, 0, -forward.x)
	for index in 8:
		var angle := index * PI / 4
		cat.art.present(forward * cos(angle) + right * sin(angle), false, 0, 0, 0)
		check(cat.art.direction_index == index and cat.art.flip_h == (index > 4), "five authored views cover eight observer-relative directions")
		check((cat.art.texture as AtlasTexture).filter_clip, "isolated crops prevent adjacent pose bleed")
	cat.art.elapsed = 0
	cat.art.present(forward, true, 0, 0, 0)
	check(cat.art.pose_row == 1, "extended running stride")
	cat.art.present(forward, true, 0, 0, 0.12)
	check(cat.art.pose_row == 2, "compressed running stride")
	cat.art.present(forward, false, 0, 0.2, 0)
	check(cat.art.pose_row == 3, "directional claw action")

func _weapon(cat: BengalMonster) -> void:
	var paws := ItemStack.new(BengalPawsItem.create(), 1)
	check(not game.character_equipment.can_equip("combat_1", paws), "paws enforce level fifteen")
	game.progression.progress.award_experience(CharacterProgress.threshold(15, true))
	game.character_equipment.set_slot("combat_1", paws)
	game.loadout.select(1)
	check(game.combat.claws.selected and not game.combat.equipment.melee_selected(), "active paws use the fist attack path")
	var combat := game.combat
	combat.targets = [cat.target]
	cat.position = cat._home
	game.player.position = cat.position - Vector3.BACK * 1.25
	cat.target.current = 240
	cat.target.invulnerability = 0
	await physics_frame
	var expected := combat.claws.damage(combat)
	var before := cat.target.current
	combat.equipment.step(Vector2.DOWN, false, true, false, false, 0, 0.016)
	check(is_equal_approx(before - cat.target.current, expected), "normal claws scale from fist damage")
	check(game.progression.progress.practice.fist == 1 and game.progression.progress.practice.attack_speed == 1, "confirmed claw trains fists and speed together")
	combat.equipment._punch_time = 0
	game.player.position.x += 20
	combat.equipment.step(Vector2.DOWN, false, true, false, false, 0, 0.016)
	check(game.progression.progress.practice.attack_speed == 1, "missed claw cannot train speed")
	game.player.position.x -= 20
	combat.equipment._punch_time = 0
	var stamina := combat.vitals.current
	before = cat.target.current
	combat.step(Vector2.DOWN, false, 2.0, Vector2.ZERO, false, true)
	check(combat.claws.dashing and cat.target.current == before, "charged launch waits for collision-resolved motion")
	var dt := combat.claws.remaining
	game.player.position += combat.claws.velocity(Vector3.ZERO, true, dt) * dt
	combat.step(Vector2.DOWN, false, dt, Vector2.ZERO, false, true)
	check(is_equal_approx(before - cat.target.current, expected * 4), "RMB contact plus finisher total four normal hits")
	check(cat.target.paralysis == 4 and combat.claws.cooldown > 7.9, "successful rift applies four-second paralysis and eight-second cooldown")
	check(is_equal_approx(stamina - combat.vitals.current, 20), "rift pays exactly 20 SP")
	check(game.progression.progress.practice.fist == 2 and game.progression.progress.practice.attack_speed == 2, "rift trains both skills once")
	var sequence := combat.claws.sequence
	combat.step(Vector2.DOWN, false, 0.016, Vector2.ZERO, false, true)
	check(combat.claws.sequence == sequence, "held RMB cannot repeat a cast")
	game.loadout.select(2)
	game.loadout.select(1)
	check(combat.claws.cooldown > 7.9, "weapon swaps cannot reset rift cooldown")
	var state := CombatState.capture(combat)
	check(ExplorationProtocol.combat(state), "bounded paw combat state validates")
	var invalid := state.duplicate(true)
	invalid.claw_cooldown = 9
	check(not ExplorationProtocol.combat(invalid), "oversized cooldown rejected")
	invalid = state.duplicate(true)
	invalid.gun = true
	check(not ExplorationProtocol.combat(invalid), "simultaneous paws and gun rejected")
	var world := CoopWorld.capture(game)
	check(WorldProtocol.valid(world), "paralysis and claw state survive JSON world schema")
	cat.target.paralysis = 0
	CoopWorld.apply(game, JSON.parse_string(JSON.stringify(world)), false)
	check(cat.target.paralysis == 4, "host checkpoint restores remaining paralysis")
	var saved := AdventureSnapshot.capture(game, "Bengal practice", 0)
	check(SaveStore.valid(saved), "solo save accepts rare paws and both practice counters")
	for value in [-1, 9, NAN, "eight"]:
		var broken := saved.duplicate(true)
		broken.claw_cooldown = value
		check(not SaveStore.valid(broken), "solo save rejects invalid ability cooldown")
	AdventureSnapshot.restore(game, saved)
	check(game.combat.claws.selected and game.progression.progress.practice.attack_speed == 2, "solo restore keeps weapon and earned speed practice")
	check(ItemStack.restore(paws.capture()).item.id == BengalPawsItem.ID, "item stack roundtrip")
	check(BengalPawsItem.ID in MerchantLocations.stock(game.world, game.world.weapon_merchant), "Grandpa stocks paws for testing")
	var purchase := WeaponTrade.purchase(game.inventory, BengalPawsItem.ID)
	check(purchase.begins_with("Bought") and game.inventory.count_item(BengalPawsItem.ID) == 1, "testing shop grants paws for its standard zero price")
	check(combat.claws.cooldown > 7.8 and not combat.claws.busy(), "solo save preserves cooldown without replaying the skill")
	check(is_equal_approx(game.player.motor.equipment_walk_multiplier, 1.15), "selected paws apply movement bonus after restore")
	game.loadout.select(2)
	check(game.player.motor.equipment_walk_multiplier == 1.0 and game.player.motor.dash_cost_multiplier == 1.0, "stowing paws removes mobility bonuses")
	game.loadout.select(1)
	var rows: Array = CharacterDetailsData.build(game).rows
	check(is_equal_approx(rows[2].total, game.player.tuning.walk_speed * game.player.motor.walk_multiplier * 1.15), "character sheet includes held paw speed as equipment")
	var level_fifteen_hp := combat.tuning.maximum_health * pow(VitalRules.HP_GROWTH, 14)
	check(30 * game.progression.progress.incoming_multiplier() < level_fifteen_hp * 0.2, "a claw remains approachable at recommended level")

func _loot(cat: BengalMonster) -> void:
	var items := game.world_items
	items.magic_roll = func() -> float: return 1.0
	var count := items.pool.drops.size()
	for roll in [0.01, 0.9, -1.0, NAN, INF]:
		items.bengal_roll = func() -> float: return roll
		check(not BengalMobLoot.drop(items, cat.position), "invalid and outside-one-percent rolls do not drop paws")
	items.bengal_roll = func() -> float: return 0.009999
	items.pool.authoritative = false
	check(not BengalMobLoot.drop(items, cat.position), "replicas cannot roll or mint paws")
	items.pool.authoritative = true
	cat.target.current = 1
	var experience := game.encounters.experience
	cat.target.damage(999)
	check(items.pool.drops.size() == count + 1 and game.encounters.experience == experience + 250, "one successful Bengal kill grants one paw item and grinding EXP")
	cat.target.damage(999)
	check(items.pool.drops.size() == count + 1 and cat._respawn == 18, "dead mob cannot reroll loot and returns after eighteen seconds")
	check(WorldProtocol.world_items(items.pool.capture()) and SaveStore._world_items(items.pool.capture()), "rare world drop validates in session and save contracts")

func _localization() -> void:
	TranslationServer.set_locale("pl")
	check(tr("Bengal Paws") == "Bengalskie Łapcie", "Polish item name is available on live language switch")
	game.hud.show_paws_state(true, 0)
	check(tr(game.hud._charge_text.text) == "TRZYMAJ PPM 2s · 20 SP", "ready skill caption translates with exact mechanics")
	game.hud.show_paws_state(true, 0, 1.0)
	check(tr(game.hud._charge_text.text) == "ŁADOWANIE 50%", "charge progress translates")
	game.hud.show_paws_state(true, 7.5)
	check(tr(game.hud._charge_text.text) == "SUPERPAZUR 7.5s", "formatted cooldown translates")
	check(tr("Weapon · Requires Lv. 15") == "Broń · Wymagany poz. 15", "level requirement translates as a complete tooltip line")
	TranslationServer.set_locale("en")
