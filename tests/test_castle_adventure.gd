extends SceneTree
## Legal interactions, gates, real spells/burn recovery, and atomic save/replica state.

var failures: int = 0
var game: AdventureGame
var flow: CastleAdventure

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for tick in count: await physics_frame

func operate(action: int) -> void:
	game.player.relocate(flow.focus_position(action) - Vector3.UP + Vector3(0, 0.05, 0.8))
	await ticks(2)
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
	for guard in flow.encounter.guards: guard.set_physics_process(false)
	await ticks(3)
	check(CastleProtocol.valid(flow.capture(true), true), "initial live castle snapshot is valid")
	flow.castle.present(flow.castle.to_global(Vector3(0, 0.1, 24)), true)
	check(flow.encounter.guards[0].is_visible_in_tree() and not flow.encounter.guards[3].is_visible_in_tree(), "cutaway hides upper-floor guardians with their floor")
	check(flow.encounter.guards[3].collision_layer == 2, "cutaway leaves upper-floor guardian collision intact")
	flow.castle.present(flow.castle.to_global(Vector3(0, 16.1, 24)), true)
	check(flow.encounter.guards[6].is_visible_in_tree(), "guardians become visible when their floor is reached")
	for gate in flow.encounter.entry_gates:
		var start := gate.global_position + Vector3(0, 1, -2)
		var finish := gate.global_position + Vector3(0, 1, 2)
		var hit := game.player.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start, finish, 1))
		check(not hit.is_empty() and hit.collider == gate.body, "arrival seal physically blocks exterior-stair bypass")
	var king := flow.encounter.king
	var world_targets := game.combat.targets.duplicate()
	game.combat.targets.clear()
	flow.encounter.step(0.016)
	check(game.combat.targets.is_empty(), "inactive castle encounter preserves another activity's target filter")
	game.combat.targets.assign(world_targets)
	check(not king.target.damage(300) and king.target.current == 1100, "king cannot be attacked before the narrative challenge")
	var original := flow.state.capture()
	var remote := PlayerCommand.new()
	remote.pickup_pressed = true
	remote.castle_action = 0
	flow._command(remote, 0.016, game.player)
	check(flow.state.capture() == original, "distant castle input is rejected")
	await operate(0)
	check(flow.state.lever_bits == 3 and not flow.state.solved[0], "first lever flips two runes")
	remote.castle_revision = 0
	flow._command_cooldown.clear()
	flow._command(remote, 0.016, game.player)
	check(flow.state.lever_bits == 3, "stale revision cannot flip a lever twice")
	await operate(1)
	check(flow.state.solved[0] and not flow.state.gate_open(0), "logic solves restraint but guardian seal stays closed")
	await operate(4)
	check(flow.state.sequence_step == 0, "wrong archive order resets memory")
	for action in [6, 4, 7, 5]: await operate(action)
	check(flow.state.solved[1], "archive clues determine all four runes")
	await operate(11)
	check(not flow.state.solved[2], "incorrect scale confirmation cannot unlock measure")
	for action in [8, 9, 9, 10, 10, 10, 11]: await operate(action)
	check(flow.state.solved[2] and flow.state.dials == [1, 2, 3], "three simultaneous scale equations solve measure")
	for guard in flow.encounter.guards:
		guard.target.damage(1000)
	check(flow.state.all_open(), "confirmed guardian deaths release all three royal seals")
	for gate in flow.encounter.entry_gates:
		var start := gate.global_position + Vector3(0, 1, -2)
		var finish := gate.global_position + Vector3(0, 1, 2)
		check(game.player.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start, finish, 1)).is_empty(), "cleared trial releases its physical arrival seal")
	for floor_node in flow.castle.floors:
		check(floor_node.trial.gate.opened and floor_node.trial.gate.body.collision_layer == 0, "open gate has no blocking body")
		check(floor_node.trial.shortcut != null and floor_node.trial.shortcut.opened, "each trial opens a real return shortcut")
	await operate(12)
	check(flow.state.introduced and not king.active, "first audience introduces the king before battle")
	await operate(12)
	check(king.active and flow.state.participants == ["solo"] and not flow.encounter.arena_gate.opened, "second audience starts an owned solo challenge")
	check(not flow.reachable(game.player, 12), "king conversation focus ends while the challenge is active")
	var visit: VolcanicVisit = game.get_node("VolcanicVisit")
	flow._process(0)
	visit._process(0)
	check(not flow.castle.king.greeting.visible, "the king's nearby greeting stays hidden during combat")
	check(king.target.damage(510), "active challenge accepts weapon damage")
	king.quarry = game.player
	king.spells.actors = [game.player]
	king._physics_process(0.01)
	check(king.phase == 2, "king enrages below fifty-five percent health")
	king.cycle = 0
	king._windup(Vector3.BACK)
	king._release()
	check(king.spells.bolts.size() == 5, "enraged ranged volley has five dodgeable projectiles")
	king.spells.clear()
	king.cycle = 1
	king._windup(Vector3.BACK)
	check(king.spells.fields.size() == 2 and king.spells.fields[0][4] < 0, "rain warns on locked target position before damage")
	king.spells.clear()
	game.player.global_position = flow.castle.to_global(Vector3(7, 24, 0))
	game.health.invulnerability = 0
	var hp := game.health.current
	king.spells.mark(game.player.global_position, 0.2)
	king.spells._physics_process(0.1)
	check(game.health.current == hp, "warning circle does no early damage")
	king.spells._physics_process(0.11)
	check(game.health.current < hp and flow.party.burns.has("solo"), "eruption damages and ignites through existing health contracts")
	game.health.invulnerability = 0
	flow.party.hurt(game.player, 1, king.global_position, true)
	check(flow.party.burns.solo[0] == 6, "reapplication refreshes one burn")
	game.health.invulnerability = 0
	hp = game.health.current
	flow.party.step(1.01)
	check(is_equal_approx(hp - game.health.current, 4), "one refreshed burn delivers one armor-scaled tick")
	game.player.global_position = flow.castle.to_global(Vector3(-18, 24, -16))
	flow.party.step(0.01)
	check(not flow.party.burns.has("solo"), "cooling spring extinguishes burning")
	king.spells.clear()
	game.player.global_position = flow.castle.to_global(Vector3(5, 27, 0))
	game.health.invulnerability = 0
	hp = game.health.current
	king.spells.shockwave(flow.castle.to_global(Vector3(0, 24, 0)))
	king.spells._physics_process(1.4)
	check(game.health.current == hp, "jumping above the wave avoids its damage")
	king.spells.clear()
	game.player.global_position = flow.castle.to_global(Vector3(0, 24, 17))
	game.health.invulnerability = 0
	game.health.damage(1000)
	check(not flow.party.fallen.is_empty() and game.health.current == 0, "arena defeat waits outside the seal instead of allowing free re-entry healing")
	flow.encounter.step(2.6)
	check(not king.active and flow.party.fallen.is_empty() and game.health.current > 0, "party wipe resets the king and releases defeated participants")
	game.player.set_physics_process(false)
	await operate(12)
	king.set_physics_process(false)
	king.target.damage(5000)
	check(flow.state.completed and king.pose == "defeat" and flow.encounter.arena_gate.opened, "confirmed victory ends spells and leaves the old master alive")
	var reward_before := game.inventory.count_item("golden_tofu_chunk")
	await operate(12)
	check(game.inventory.count_item("golden_tofu_chunk") == reward_before + 1 and flow.state.rewarded == ["solo"], "royal blessing is awarded once to an encounter participant")
	await operate(12)
	check(game.inventory.count_item("golden_tofu_chunk") == reward_before + 1, "repeat audience does not duplicate rewards")
	var save := AdventureSnapshot.capture(game, "Castle", 10)
	check(SaveStore.valid(save), "completed castle and reward ledger persist in old save envelope")
	var live := flow.capture(true)
	check(CastleProtocol.valid(live, true) and WorldProtocol.valid(CoopWorld.capture(game)), "completed world snapshot remains protocol-valid")
	var corrupt := live.duplicate(true)
	corrupt.guards[3].body[4] = 999
	flow.restore(corrupt, true)
	check(flow.capture(true) == live, "malformed nested state is rejected before any mutation")
	flow.authoritative = false
	flow.encounter.authority(false)
	flow.restore(live, true)
	game.health.invulnerability = 0
	hp = game.health.current
	flow.party.hurt(game.player, 100, king.global_position, true)
	check(game.health.current == hp and not king.is_physics_processing() and not king.spells.authoritative, "guest castle presentation never decides damage or spells")
	var intent := PlayerCommand.new()
	intent.castle_action = 7
	intent.castle_revision = 23
	var encoded := CoopValues.input(intent, 1, 0)
	check(ExplorationProtocol.valid_input(encoded) and CoopValues.command(encoded).castle_action == 7, "typed castle intent round-trips through bounded co-op commands")
	encoded.castle_action = 25
	check(not ExplorationProtocol.valid_input(encoded), "out-of-range castle action is rejected")
	game.queue_free()
	await ticks(3)
	print("Castle adventure: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
