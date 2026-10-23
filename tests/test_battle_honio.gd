extends SceneTree
## Real Royale composition: melee danger/counterplay, bounded art/state and finite rewards.
var failures: int = 0
var game: BattleRoyaleGame
var room: BattleRoom
var mob: HonioMeniono
var id: int
var base := Vector3(650, 40, 650)

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: return
	failures += 1
	printerr("FAIL: ", label)

func _run() -> void:
	GamePreferences.install_translations(self)
	_seed_and_wire()
	room = BattleRoom.new()
	room.options = [2, 1]
	root.add_child(room)
	room.practice()
	room.epoch = "0".repeat(24)
	game = BattleRoyaleGame.new()
	game.room = room
	game.preferences.path = "user://honio-test-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	while not game.composed: await physics_frame
	game.set_physics_process(false)
	id = BattleHonioSpawn.site(room.epoch, game.mobs.actors.size())
	check(id >= 0, "fixed epoch spawns the Easter egg")
	if id < 0:
		quit(1)
		return
	mob = game.mobs.actors[id] as HonioMeniono
	check(mob != null and game.mobs.ranged[id] == null, "Honio has no ranged component or projectile")
	check(game.mobs.actors.size() <= 24 and game.bodies.size() == 3, "Easter egg replaces a hunt without adding a survivor or extra population")
	check(not mob.is_physics_processing() and not mob.target.is_physics_processing(), "authority manually advances all Honio outcomes")
	check(not _hurt(10), "deployment forbids damage and rewards")
	BattleTestDeployment.finish(game)
	game.match_state.time = 13
	_fixture()
	await physics_frame
	await _combat()
	_art()
	await _recovery_and_loot()
	game.queue_free()
	room.queue_free()
	await process_frame
	print("Battle Royale Honio Meniono: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _seed_and_wire() -> void:
	check(not ResourceLoader.has_cached(HonioVisuals.SHEETS.idle) and not ResourceLoader.has_cached(HonioVFX.SHEET), "encounter art loads only when Honio is composed")
	var found := 0
	var sites: Dictionary = {}
	for seed_index in 2048:
		var epoch := "%024x" % seed_index
		var site := BattleHonioSpawn.site(epoch, 24)
		check(site == BattleHonioSpawn.site(epoch, 24), "encounter cannot reroll on reconnect")
		if site >= 0:
			found += 1
			sites[site] = true
	check(found > 420 and found < 620 and sites.size() == 24, "roughly one quarter of rounds can select any hunt site")
	var data := BattleHonioWire.initial()
	check(BattleHonioWire.valid(JSON.parse_string(JSON.stringify(data))), "bounded initial melee state crosses JSON")
	for index in data.size():
		var invalid := data.duplicate()
		invalid[index] = INF
		check(not BattleHonioWire.valid(invalid), "all melee values reject infinity")
	data[0] = 2
	check(not BattleHonioWire.valid(data), "a jab cannot claim a rushing phase")
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		for line in HonioSpeech.LINES:
			if locale == "pl": check(TranslationServer.translate(line) != line, "every Honio joke is localized")
	TranslationServer.set_locale("en")
	var rest := HonioMelee.new()
	rest.interrupt_rest = 2.5
	rest.elapse(1.5)
	check(rest.phase == HonioMelee.Phase.IDLE and rest.remaining == 0 and rest.interrupt_rest == 1, "sleeping recovery expires instead of leaving permanent vulnerability")

func _fixture() -> void:
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	shape.position.y = -0.5
	floor_body.position = base
	floor_body.add_child(shape)
	game.add_child(floor_body)
	mob.position = base
	mob._home = base
	mob.quarry = game.bodies[0]
	for slot in game.bodies.size():
		game.bodies[slot].position = base + Vector3(slot * 3, 0, 1.5)
		game.match_state.rows[slot][8] = 100
		game.match_state.rows[slot][9] = 0
		game.combat.fighters[slot].health.current = 100
		game.bodies[slot].velocity = Vector3.ZERO

func _combat() -> void:
	mob.melee.phase = HonioMelee.Phase.IDLE
	mob.melee.remaining = 0
	check(_hurt(40) and mob.target.current == 290, "chasing Honio resists 25 percent of damage")
	mob.melee.recover(1.25)
	check(_hurt(40) and mob.target.current == 250, "recovery removes his resistance")
	check(mob.target.is_headshot(mob.position + Vector3.UP * 1.55), "visible upper tofu body remains a headshot")
	check(not mob.target.is_headshot(mob.position + Vector3.UP * 0.65), "lower body remains a body hit")
	var head_ray := PhysicsRayQueryParameters3D.create(mob.position + Vector3(-3, 1.55, 0), mob.position + Vector3.UP * 1.55, 2)
	var head_hit := game.get_world_3d().direct_space_state.intersect_ray(head_ray)
	check(not head_hit.is_empty() and head_hit.collider == mob and mob.target.is_headshot(head_hit.position), "a real ray through the visible upper tofu body hits the calibrated capsule/head region")
	mob.melee.begin(HonioMelee.Skill.TOFU_TENDERIZER, Vector3.BACK)
	check(mob.melee.step(mob, 0.5).is_zero_approx(), "slam warning holds position for a full second")
	_flush()
	check(game.match_state.rows[0][8] == 100, "warning alone deals no damage")
	game.bodies[0].position = base + Vector3.BACK * 4
	mob.melee.step(mob, 0.51)
	_flush()
	check(game.match_state.rows[0][8] == 100, "moving beyond the visible three metre ring dodges the slam")
	game.bodies[0].position = base + Vector3.BACK * 1.5
	game.bodies[1].position = base + Vector3.RIGHT * 2.0
	mob.melee.begin(HonioMelee.Skill.TOFU_TENDERIZER, Vector3.BACK)
	mob.melee.step(mob, 1.01)
	_flush()
	check(game.match_state.rows[0][8] == 68 and game.match_state.rows[1][8] == 68, "real slam damages all exposed survivors in the ring")
	mob.melee.begin(HonioMelee.Skill.JAB, Vector3.FORWARD)
	mob.melee.step(mob, 0.51)
	_flush()
	check(game.match_state.rows[0][8] == 68, "committed punches cannot hit behind him")
	game.bodies[0].motor.is_dashing = true
	mob.melee.begin(HonioMelee.Skill.JAB, Vector3.BACK)
	mob.melee.step(mob, 0.51)
	_flush()
	check(game.match_state.rows[0][8] == 68, "normal dash immunity counters his melee")
	game.bodies[0].motor.is_dashing = false
	var fighter := game.combat.fighters[0]
	game.match_state.rows[0][10] = 1
	fighter.equip(game.match_state.rows[0])
	fighter.combat.vitals.current = 100
	fighter.combat.equipment.step(Vector2.UP, true, false, false, false, 0, 0.02)
	mob.melee.begin(HonioMelee.Skill.JAB, Vector3.BACK)
	mob.melee.step(mob, 0.51)
	_flush()
	check(game.match_state.rows[0][8] == 68 and fighter.combat.vitals.current < 100, "facing guard spends stamina to stop a jab")
	fighter.combat.equipment.step(Vector2.UP, false, false, false, false, 0, 0.02)
	mob.melee.begin(HonioMelee.Skill.PROTEIN_EXPRESS, Vector3.BACK)
	check(_hurt(10, Damageable.HitKind.KNIFE) and mob.melee.phase == HonioMelee.Phase.RECOVERY, "close melee interrupts the rush windup")
	mob.melee.begin(HonioMelee.Skill.PROTEIN_EXPRESS, Vector3.BACK)
	_hurt(10, Damageable.HitKind.KNIFE)
	check(mob.melee.phase == HonioMelee.Phase.WARNING, "brief interrupt resistance prevents permanent melee stunlock")
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8, 4, 0.25)
	shape.shape = box
	wall.position = base + Vector3(0, 1.5, 0.8)
	wall.add_child(shape)
	game.add_child(wall)
	await physics_frame
	mob.melee.begin(HonioMelee.Skill.TOFU_TENDERIZER, Vector3.BACK)
	mob.melee.step(mob, 1.01)
	_flush()
	check(game.match_state.rows[0][8] == 68, "solid cover occludes the close melee impact")
	check(not HonioMelee.safe_step(mob, Vector3.BACK), "rush refuses to run through a wall")
	game.bodies[0].position = base + Vector3.BACK * 8
	mob.melee.phase = HonioMelee.Phase.IDLE
	mob.melee.remaining = 0
	mob.melee.special_rest = 1
	var around := mob.melee.step(mob, 0.01)
	check(around.length() > 8 and absf(around.z) < 0.1, "normal chase steers along cover instead of becoming a stationary target")
	wall.queue_free()
	await physics_frame
	mob.position = base + Vector3(19, 0, 0)
	check(not HonioMelee.safe_step(mob, Vector3.RIGHT), "ground probes prevent charging into a pit")
	mob.position = base
	game.bodies[0].position = base + Vector3.BACK * 15
	mob.melee.phase = HonioMelee.Phase.IDLE
	mob.melee.remaining = 0
	check(mob.melee.step(mob, 0.01).length() > 8, "normal chase outruns a survivor sprint")
	game.bodies[0].position = base + Vector3.BACK * 8
	mob.melee.begin(HonioMelee.Skill.PROTEIN_EXPRESS, Vector3.BACK)
	mob.melee.step(mob, 0.81)
	check(mob.melee.step(mob, 0.01).length() == 13, "warned rush is a fast physical body movement")
	for frame in 50:
		mob._physics_process(1.0 / 60)
		await physics_frame
	_flush()
	print("Rush evidence: ", mob.position - base, " phase ", mob.melee.phase, " hp ", game.match_state.rows[0][8])
	check(game.match_state.rows[0][8] < 68, "physical rush reaches and endangers a stationary gunner")
	check(mob.position.z < base.z + 8 and mob.melee.phase == HonioMelee.Phase.RECOVERY, "rush hits once and leaves a punishable opening")
	mob.position = base
	mob.melee.begin(HonioMelee.Skill.PROTEIN_EXPRESS, Vector3.BACK)
	game.playing = false
	var state := BattleHonioState.capture(mob)
	game.mobs.step(2)
	check(state == BattleHonioState.capture(mob) and not _hurt(10), "paused match cannot advance or damage Honio")
	game.playing = true

func _art() -> void:
	check(mob.art.frames.size() == 40, "all forty generated poses are loaded")
	var counts: Dictionary = {}
	for frame: Dictionary in mob.art.layout:
		counts[frame.direction] = int(counts.get(frame.direction, 0)) + 1
		check(frame.center > 0 and frame.center < frame.region[2] and frame.foot < frame.region[3], "all frames have calibrated anchors inside their cell")
	check(counts.size() == 8, "every action has all eight authored directions")
	for camera_quarter in 4:
		var angle := camera_quarter * PI / 2
		game.camera.global_position = base + Vector3(sin(angle) * 12, 10, cos(angle) * 12)
		game.camera.look_at(base)
		for direction in 8:
			var heading := -direction * PI / 4
			mob.art.present(Vector3(sin(heading), 0, cos(heading)), false, 0, 0, 0, 0)
			check(mob.art.direction_index == posmod(direction + camera_quarter * 2, 8), "authored directions follow all four camera viewpoints without reversing travel")
	var node_count := mob.get_child_count()
	for attack in 200:
		mob.melee.begin(HonioMelee.Skill.TOFU_TENDERIZER, Vector3.BACK)
		mob.effects.present(mob.melee, 0.016)
	check(mob.get_child_count() == node_count, "repeated effects reuse fixed nodes")
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		mob._present_visual(Vector3.ZERO, 0.016)
		check(mob.speech.text == tr(HonioSpeech.LINES[2]), "live language switching updates enemy speech")
	TranslationServer.set_locale("en")

func _recovery_and_loot() -> void:
	mob.melee.special_rest = 3.25
	mob.melee.interrupt_rest = 1.75
	mob._returning = true
	game.recovery.publish()
	var saved := BattleCheckpoint.decode(room.migration.checkpoint, room.members)
	check(not saved.is_empty(), "Honio's health, exact cooldown and melee skill fit the real checkpoint")
	if saved.is_empty(): return
	var before: Array = saved.mobs[0][id][14].duplicate()
	game.recovery.pause()
	mob.target.current = 1
	game.recovery.restore(saved)
	game.recovery.resume()
	check(mob.target.current == saved.mobs[0][id][4][6], "migration restores exact boss health")
	check(mob.melee.phase == HonioMelee.Phase.RECOVERY and mob.melee.remaining >= 1.25 and mob.melee.special_rest == before[2], "migration cancels contact skills while retaining cooldown and giving fair grace")
	check(mob._returning, "migration retains his return-to-home intent")
	check(mob.melee.interrupt_rest == 1.75, "migration retains interrupt resistance instead of rerolling it")
	var baseline := game.match_state.mobs.duplicate(true)
	mob.melee.begin(HonioMelee.Skill.PROTEIN_EXPRESS, Vector3.RIGHT)
	game.mobs.capture()
	var packet := {"mobs": game.match_state.mobs.duplicate(true)}
	BattleMobDelta.compact(packet, baseline, 2, false)
	check(BattleMobDelta.expand(packet, baseline) and packet.mobs == game.match_state.mobs, "active skill crosses existing indexed hunt deltas")
	var host := room.host_key
	room.host_key = "f".repeat(64)
	game.mobs.present(0)
	var old_health := mob.target.current
	check(not _hurt(100) and mob.target.current == old_health, "replica presentation cannot deal damage or pay rewards")
	room.host_key = host
	var original := game.match_state.drops.duplicate(true)
	game.match_state.drops.clear()
	for drop in BattlePackWire.DROPS: game.match_state.drops.append([drop, 0, 0, 0, 27, 1, 0])
	check(_hurt(1000), "ordinary match weapons can defeat Honio")
	check(game.match_state.mobs[0][id][9] == 1, "full ledger retains the entire unpaid bounty")
	for drop in 4: game.match_state.drops[drop][5] = 0
	BattleHuntLoot.release(game, id)
	check(game.match_state.mobs[0][id][9] == 2, "boss bounty releases atomically after space becomes available")
	var contents := BattleHuntLoot.contents(room.epoch, id, 3)
	check(contents.has(28) and contents.has(27) and contents.has(33) and BattleRarity.grade(contents[3]) == 2, "finite bounty includes milk, apples, chunk and legendary protection")
	var paid := game.match_state.drops.duplicate(true)
	BattleHuntLoot.release(game, id)
	check(game.match_state.drops == paid and not _hurt(1000), "no repeated rewards or respawn farming")
	check(game.match_state.mobs[1][0] == 1 and game.match_state.rows[0][12] == 0, "boss hunt does not count as a survivor elimination")
	check(BattleMobWire.valid(game.match_state.mobs, game.bodies.size()), "live and slain boss states remain valid")
	var duplicate := game.match_state.mobs.duplicate(true)
	duplicate[0][0] = duplicate[0][id].duplicate(true)
	check(not BattleMobWire.valid(duplicate, game.bodies.size()), "remote records cannot add multiple Honios")
	# A separate lifecycle branch: the storm must not pay the boss bounty.
	game.match_state.mobs[0][id][9] = 0
	game.match_state.mobs[0][id][10] = -1
	game.match_state.mobs[1][0] = 0
	mob.target.current = HonioMeniono.HEALTH
	mob._respawn = 0
	game.match_state.time = BattleRing.total_time()
	game.mobs.step(100)
	check(game.match_state.mobs[0][id][9] == 3 and game.match_state.mobs[1][0] == 0 and game.match_state.drops == paid, "storm kills Honio without bounty or hunt credit")
	game.match_state.drops = original

func _hurt(amount: float, kind: Damageable.HitKind = Damageable.HitKind.SOY) -> bool:
	return mob.target.receive_attack(amount, Vector3.ZERO, kind, mob.position + Vector3.UP, game.combat.fighters[0].health)

func _flush() -> void:
	var commands: Array[PlayerCommand] = []
	commands.resize(game.bodies.size())
	game.combat.step(commands, 0, 0)
