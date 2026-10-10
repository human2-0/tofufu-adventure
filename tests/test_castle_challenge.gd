extends SceneTree
## Exploration loot, acknowledged puzzles, evasive guardians and cover-safe fast shots.

var failures: int = 0
var game: AdventureGame
var flow: CastleAdventure
var lunge_hits: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func at_chest(index: int) -> void:
	var chest := flow.treasure.chest(index)
	game.player.relocate(chest.global_position + chest.global_basis.z * 1.8 + Vector3.UP * 0.05)
	await ticks(2)

func interact(action: int) -> void:
	var command := PlayerCommand.new()
	command.pickup_pressed = true
	command.castle_action = action
	command.castle_revision = flow.state.revision
	flow._command_cooldown.clear()
	flow._command(command, 0.016, game.player)

func _run() -> void:
	game = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.weather.set_physics_process(false)
	game.player.set_physics_process(false)
	game.set_physics_process(false)
	flow = game.castle_adventure
	flow.set_physics_process(false)
	flow.encounter.king.set_physics_process(false)
	flow.encounter.king.spells.set_physics_process(false)
	for guard in flow.encounter.guards:
		guard.set_physics_process(false)
		guard.spells.set_physics_process(false)
	await ticks(3)
	await _treasure()
	await _puzzles()
	await _guardians()
	await _king_chunks()
	_protocol()
	game.queue_free()
	await ticks(3)
	print("Castle challenge: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _treasure() -> void:
	for deck in 3:
		var layout := flow.castle.floors[deck].layout
		var cells := CastleTreasureLayout.cells(layout)
		check(cells.size() == 4 and flow.castle.floors[deck].chests.size() == 4, "each deck has four hidden treasures")
		check(cells == CastleTreasureLayout.cells(CastleMazeLayout.new(deck)), "treasure placement is deterministic across peers")
		for cell in cells:
			check(cell not in layout.solution and layout.passages[CastleMazeLayout.index(cell)] in [1, 2, 4, 8], "treasure rewards an optional dead-end branch")
			check(layout.route(layout.entrance, cell).size() > 1, "every hidden chest has a connected passage")
	for index in 12:
		await at_chest(index)
		check(flow.reachable(game.player, index + 13), "dead-end chest is reachable from its opening side")
	await at_chest(0)
	var before := game.inventory.count_item("golden_tofu_chunk")
	interact(13)
	check(game.inventory.count_item("golden_tofu_chunk") == before + 3 and flow.state.treasure_claimed("solo", 0), "host interaction atomically grants three Golden Tofu")
	check(flow.treasure.chest(0).opened and flow.treasure.chest(0).sparks.visible, "first opening starts hinged lid and bounded spark effects")
	interact(13)
	check(game.inventory.count_item("golden_tofu_chunk") == before + 3, "repeat interaction cannot duplicate a chest grant")
	await ticks(45)
	check(flow.treasure.chest(0).lid.rotation.x < -1.1, "chest lid reaches its open pose")
	var inventory := game.inventory.capture()
	for i in game.inventory.slots.size(): game.inventory.set_slot(i, ItemStack.new(InventoryItem.create_edamame(), 100))
	await at_chest(1)
	interact(14)
	check(flow.state.opened_chests == 1 and not flow.state.treasure_claimed("solo", 1), "a full bag leaves treasure available and the chest closed")
	game.inventory.restore(inventory)
	game.player.relocate(flow.castle.to_global(Vector3(0, 0.1, 24)))
	await ticks(2)
	check(not flow.treasure.claim(game.player, 1), "direct distant treasure requests are rejected")
	var save := flow.capture()
	check(CastleSaveValidation.valid(save), "new chest ledger is accepted by durable saves")
	flow.restore(save)
	check(flow.state.treasure_claimed("solo", 0) and not flow.treasure.claim(game.player, 0), "restored loot remains owned and cannot be minted again")
	var old := save.duplicate(true)
	for field in ["opened_chests", "treasure_claims", "last_action", "accepted", "feedback_revision"]: old.trial.erase(field)
	check(CastleSaveValidation.valid(old), "saves made before treasure and feedback remain valid")

func _puzzles() -> void:
	var camera_at := game.camera.global_position
	for child in flow.castle.floors[1].trial.get_children():
		if not child is CastleTrialSigns: continue
		for height in [-3.0, 3.0]:
			game.camera.global_position = child.global_position + Vector3.UP * height
			child._process(0)
			check(child.pivot.global_basis.z.dot(Vector3.UP * signf(height)) > 0.99, "contextual placard also supports a view directly above or below it")
	game.camera.global_position = camera_at
	var memory := flow.castle.floors[1].trial.feedback
	flow.state.operate(6)
	flow.present_state()
	check(memory.selected == 2 and memory.pulse > 0 and memory.success, "memory press has an immediate accepted acknowledgement")
	memory.step(1)
	check(memory.materials[2].albedo_color.g > 0.7 and memory.materials[0].albedo_color.g < 0.7, "remembered glyph stays highlighted after its acknowledgement fades")
	flow.state.operate(5)
	flow.present_state()
	check(not memory.success and memory.selected == 1 and memory.materials[1].albedo_color.r > 0.9, "wrong memory press flashes red and resets the sequence")
	memory.step(1)
	flow.state.revision += 1
	flow.present_state()
	check(memory.pulse == 0, "unrelated state updates do not replay memory interaction")
	flow.notice_time = 0
	game.world_items.focused_plot = 4
	check(CastleHudCopy.text(flow, 1, true).length() < 70, "focused memory clue is compact")
	flow.view.present(true, "TOFUFU CASTLE · MEMORY", CastleHudCopy.text(flow, 1, true), "[E] Operate Tide", 0, 0)
	await ticks(2)
	check(flow.view.panel.size.x <= 390 and flow.view.panel.size.y < 125, "ordinary puzzle HUD occupies a compact panel")

func _guardians() -> void:
	for i in 9: check(flow.encounter.guards[i].target.maximum == 360 + (i / 3) * 60, "guardian health increases across decks")
	var guard := flow.encounter.guards[0]
	var original := guard.capture()
	var center := CastleMazeLayout.center(flow.castle.floors[0].layout.solution[15], 0)
	guard.global_position = flow.castle.to_global(center + Vector3.UP * 0.05)
	game.player.relocate(guard.global_position + Vector3(0, 0, 1.8))
	await ticks(2)
	guard.quarry = game.player
	guard.ranged_threat = true
	guard.cooldown = 1
	guard.tactics.dash_cooldown = 1
	var motion := guard.tactics.step(guard, 0.01, Vector3(0, 0, 5), true)
	check(absf(motion.x) > 3 and absf(motion.z) < 2, "ranged opponent induces lateral strafing")
	guard.tactics.dash_cooldown = 0
	guard.tactics.request_dash(guard)
	check(guard.tactics.dash_time > 0 and absf(guard.tactics.dash_direction.x) > 0.9, "guardian can evade sideways within a real maze chamber")
	var start := guard.global_position
	for frame in 8:
		guard._physics_process(1.0 / 60)
		await physics_frame
	check(absf(guard.global_position.x - start.x) > 0.8, "side dash physically moves the guardian")
	guard.tactics.shield = 0.5
	guard.torso.rotation.y = 0
	check(is_equal_approx(guard._filter_damage(100, Vector3.FORWARD, Damageable.HitKind.SOY), 30), "front shield reduces shooting damage")
	check(guard._filter_damage(100, Vector3.RIGHT, Damageable.HitKind.SOY) == 100, "flanking bypasses the front shield")
	guard.tactics.skill = 1
	guard.release_attack(Vector3.BACK * 5, true)
	check(guard.spells.bolts.size() == 1 and is_equal_approx(Vector3(guard.spells.bolts[0][3], guard.spells.bolts[0][4], guard.spells.bolts[0][5]).length(), 18), "guardian releases an actual burning ranged projectile")
	guard.attacked.connect(func(_victim: Node3D, _amount: float, _source: Vector3) -> void: lunge_hits += 1)
	guard.global_position = flow.castle.to_global(center + Vector3.UP * 0.05)
	game.player.relocate(guard.global_position + Vector3.BACK * 2.5)
	guard.tactics.skill = 2
	guard.tactics.dash_direction = Vector3.BACK
	guard.tactics.shield = 0
	guard.release_attack(Vector3.BACK * 2.5, true)
	check(lunge_hits == 0, "lunge telegraph cannot deal an immediate distant hit")
	for frame in 6:
		guard._physics_process(1.0 / 60)
		await physics_frame
	check(lunge_hits == 1, "physical lunge strikes once on contact")
	guard.apply(original, true)
	guard.set_physics_process(false)
	guard.quarry = null
	guard.spells.clear()

func _king_chunks() -> void:
	var king := flow.encounter.king
	king.quarry = game.player
	king.global_position = flow.castle.to_global(Vector3(-8.5, 24, -12))
	game.player.relocate(flow.castle.to_global(Vector3(-8.5, 24, -3)))
	king.begin(1)
	king.global_position = flow.castle.to_global(Vector3(-8.5, 24, -12))
	king.cycle = 4
	king._windup(Vector3.BACK)
	var aim := king.chunk_aim
	check(king.skill == 4 and king.cast == 0.5, "new fire-tofu attack has a brief readable telegraph")
	game.player.global_position.x += 2
	king._release()
	king._physics_process(0.01)
	check(king.burst == 2 and king.spells.bolts.size() == 1, "fast attack starts a three-chunk cadence")
	var bolt: Array = king.spells.bolts[0]
	check(bolt[7] == 1 and is_equal_approx(Vector3(bolt[3], bolt[4], bolt[5]).length(), 30), "fire tofu has a distinct chunk visual and fast flight speed")
	check(Vector3(bolt[3], bolt[4], bolt[5]).normalized().distance_to(aim) < 0.001, "released chunk uses locked aim rather than chasing a dodge")
	king.spells.clear()
	king.burst = 0
	game.player.relocate(flow.castle.to_global(Vector3(-8.5, 24, -3)))
	king.spells.actors = [game.player]
	await ticks(2)
	game.health.invulnerability = 0
	var hp := game.health.current
	var origin := flow.castle.to_global(Vector3(-8.5, 25.4, -12))
	king.spells.bolt(origin, game.player.global_position + Vector3.UP * 0.7 - origin, 30, true)
	for frame in 20: king.spells._physics_process(0.02)
	check(game.health.current == hp and king.spells.bolts.is_empty(), "solid arena cover stops the fast fire chunk before it reaches the player")
	game.player.relocate(flow.castle.to_global(Vector3(0, 24, -3)))
	origin = flow.castle.to_global(Vector3(0, 25.4, -12))
	await ticks(2)
	king.spells.bolt(origin, game.player.global_position + Vector3.UP * 0.7 - origin, 30, true)
	for frame in 20: king.spells._physics_process(0.02)
	check(game.health.current == hp - 30 and flow.party.burns.has("solo"), "uncovered chunk damages and applies the six-second burning status")
	king.phase = 2
	king.cycle = 4
	king._windup(Vector3.BACK)
	check(king.cast == 0.36, "enraged chunk telegraph is faster")
	king._release()
	king._physics_process(0.01)
	check(king.burst == 3 and king.spells.bolts[0][7] == 1 and is_equal_approx(Vector3(king.spells.bolts[0][3], king.spells.bolts[0][4], king.spells.bolts[0][5]).length(), 34), "phase two fires four faster chunks")
	king.reset()
	check(king.burst == 0 and king.spells.bolts.is_empty(), "reset cancels in-flight chunks and queued burst shots")
	flow.party.burns.clear()

func _protocol() -> void:
	var live := flow.capture(true)
	check(CastleProtocol.valid(live, true), "challenge additions produce a valid bounded live snapshot")
	check(JSON.stringify(CoopWorld.capture(game)).to_utf8_buffer().size() < 65536, "full world remains within the existing wire packet budget")
	var corrupt := live.duplicate(true)
	corrupt.trial.treasure_claims.solo = 4096
	check(not CastleProtocol.valid(corrupt, true) and not CastleSaveValidation.valid(corrupt), "out-of-range treasure masks are rejected for wire and save")
	corrupt = live.duplicate(true)
	corrupt.guards[0].body[9] = NAN
	check(not CastleProtocol.valid(corrupt, true), "nonfinite guardian evasion is rejected")
	corrupt = live.duplicate(true)
	corrupt.king.spells.bolts = [[316, 29, 334, 50, 0, 0, 1, 1]]
	check(not CastleProtocol.valid(corrupt, true), "excessive projectile speed cannot enter a replica")
	flow.authoritative = false
	flow.encounter.authority(false)
	var amount := game.inventory.count_item("golden_tofu_chunk")
	check(not flow.treasure.claim(game.player, 2) and game.inventory.count_item("golden_tofu_chunk") == amount, "guest treasure presentation cannot mint rewards")
