class_name BattleRecovery
extends RefCounted
## Serialize only match simulation state; keep the loaded map and selected survivors.

var game: BattleRoyaleGame

func publish(refresh_combat: bool = true) -> void:
	if refresh_combat: game.combat.capture()
	game.mobs.capture()
	if game.pack != null: game.pack.capture(true)
	var state := game.match_state.capture()
	state.cooldowns = game.match_state.cooldowns.duplicate()
	state.reloads = game.match_state.reloads.duplicate()
	state.tick = game.simulation._tick
	state.motors = []
	state.voters = []
	for body: Player in game.bodies: state.motors.append(_motor(body))
	for slot in game.room.members.size():
		var key: String = game.room.members[slot].key
		if game.match_state.rows[slot][17] == 0 and game.room.connected.has(key): state.voters.append(key)
	if not game.room.migration.voters.is_empty(): state.voters = game.room.migration.voters.duplicate()
	game.room.migration.publish(BattleWire.encode(BattleCombatWire.precision(state)))

func pause() -> void:
	game.playing = false
	game.presentation.gunfire.reset()
	game.deployment.clear_pending()
	if game.pack != null: game.pack.requests.clear()
	if game.pack_ui != null: game.pack_ui.close()
	game.combat.process_mode = Node.PROCESS_MODE_DISABLED
	game.local_input.enabled = false
	game.local_input.sample(game.bodies[game.local_slot].position)
	game.simulation.buffer = BattleInputBuffer.new()
	game.replication.pending = [0.0, 0.0, 0.0, 1.0, 256]
	game._update_hud()

func restore(state: Dictionary) -> void:
	var match_state := game.match_state
	match_state.rows = state.actors.duplicate(true)
	match_state.deployment = state.get("deployment", {}).duplicate(true)
	match_state.loot = state.loot.duplicate(true)
	match_state.mobs = state.get("mobs", []).duplicate(true)
	game.mobs.restore()
	match_state.time = float(state.time)
	match_state.circle = Vector2(state.circle[0], state.circle[1]) if state.has("circle") else BattleRing.CENTER
	match_state.stats = state.get("stats", BattleRoundStats.create(game.bodies.size())).duplicate(true)
	game.simulation.navigation.clear()
	match_state.winner = int(state.winner)
	match_state.sequence = int(state.seq)
	match_state.alive = 0
	match_state.cooldowns.assign(state.cooldowns)
	match_state.reloads.assign(state.reloads)
	game.simulation.clock = float(state.time)
	game.simulation._tick = int(state.tick)
	game.simulation.buffer = BattleInputBuffer.new()
	for slot in game.bodies.size():
		var body := game.bodies[slot]
		var row: Array = match_state.rows[slot]
		if row[8] > 0: match_state.alive += 1
		body.position = match_state.position_of(slot)
		body.collision_layer = 2 if row[8] > 0 else 0
		body.collision_mask = 3 if game.room.local_key == game.room.migration.candidate() else 0
		_restore_motor(body, state.motors[slot])
		body.velocity = Vector3(row[3], row[4], row[5])
		(body.command_source as BattleCommandSource).command = PlayerCommand.new()
		game.presentation.shots[slot] = int(row[14])
		game.presentation.fallen[slot] = row[8] <= 0
		game.presentation.poses[slot] = 0
	game.replication.sequence = 0
	game.replication.snapshot_sequence = int(state.seq)
	game.replication.last_packet = game.elapsed
	game.replication.last_sequences.clear()
	game.replication.activity.clear()
	game.replication.loot_cache.clear()
	game.replication.combat_cache.clear()
	game.replication.pack_cache.clear()
	game.replication.mob_cache.clear()
	game.replication.combat_sequence = 0
	game.replication.sent_snapshots = 0
	game.replication.published_winner = int(state.winner)
	game.replication.input_clock = 0
	game.replication.snapshot_clock = 0
	game.presentation.feed.clear()
	game.presentation._lines.clear()
	game.presentation.traces.clear_surfaces()
	for i in range(match_state.loot.size(), game.presentation.loot_sprites.size()): game.presentation.loot_sprites[i].hide()
	if state.has("pack"):
		game.match_state.pack = state.pack.duplicate(true)
		game.match_state.chests = state.chests.duplicate(true)
		game.match_state.drops = state.drops.duplicate(true)
		game.pack.restore(state.pack)
	if state.has("combat"): game.combat.restore(state.combat, game.room.local_key == game.room.migration.candidate())
	game.presentation.gunfire.reset()
	game.camera.reset_follow()

func resume() -> void:
	for slot in game.room.members.size():
		if not game.room.connected.has(game.room.members[slot].key): game.match_state.rows[slot][17] = 1
	game.replication.last_packet = game.elapsed
	game.playing = true
	game.combat.process_mode = Node.PROCESS_MODE_DISABLED if game.deployment.active() else Node.PROCESS_MODE_INHERIT
	game._update_hud()

func _motor(body: Player) -> Array:
	var m := body.motor
	return [int(m.is_dashing), int(m.is_super_dashing), m.dash_remaining, m.cooldown_remaining,
		m.dash_charge, int(m.is_charging_dash), m.jump_charge, int(m.is_charging_jump),
		m._buffered_charge, m._coyote_remaining, m._jump_buffer_remaining, m.surface_grip,
		m._dash_direction.x, m._dash_direction.y, m._dash_direction.z,
		m.endurance.current, m.endurance.rest_remaining, int(m.endurance.exhausted), int(m.endurance.running),
		m.impact.remaining, m.impact.push.x, m.impact.push.y, int(body.is_on_floor())]

func _restore_motor(body: Player, data: Array) -> void:
	var m := body.motor
	m.is_dashing = data[0] == 1
	m.is_super_dashing = data[1] == 1
	m.dash_remaining = float(data[2])
	m.cooldown_remaining = float(data[3])
	m.dash_charge = float(data[4])
	m.is_charging_dash = data[5] == 1
	m.jump_charge = float(data[6])
	m.is_charging_jump = data[7] == 1
	m._buffered_charge = float(data[8])
	m._coyote_remaining = float(data[9])
	m._jump_buffer_remaining = float(data[10])
	m.surface_grip = float(data[11])
	m._dash_direction = Vector3(data[12], data[13], data[14])
	m.endurance.current = float(data[15])
	m.endurance.rest_remaining = float(data[16])
	m.endurance.exhausted = data[17] == 1
	m.endurance.running = data[18] == 1
	m.impact.remaining = float(data[19])
	m.impact.push = Vector2(data[20], data[21])
	# Refresh engine contact flags without advancing the saved pose or motor timers.
	if body.collision_mask != 0:
		var at := body.position
		body.velocity = Vector3.DOWN * 0.01 if data[22] == 1 else Vector3.ZERO
		body.move_and_slide()
		if data[22] == 1: body.apply_floor_snap()
		body.position = at
