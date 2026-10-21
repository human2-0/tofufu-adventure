class_name BattleAuthority
extends RefCounted
## Selected actors, finite PvE hunts and shared combat; no adventure save work.

var match_state: BattleMatch
var bodies: Array[Player] = []
var buffer := BattleInputBuffer.new()
var clock: float = 0
var combat: BattleCombat
var pack: BattlePack
var mobs: BattleMobs
var _tick: int = 0
var navigation := BattleBotNavigation.new()

func step(delta: float) -> void:
	clock += delta
	if match_state.winner != -2: return
	var commands: Array[PlayerCommand] = []
	commands.resize(bodies.size())
	_tick += 1
	var rotation := _tick % bodies.size()
	for offset in bodies.size():
		var slot := (rotation + offset) % bodies.size()
		var row: Array = match_state.rows[slot]
		var body := bodies[slot]
		if row[8] <= 0:
			body.collision_layer = 0
			continue
		var command := BattleInputBuffer.decode(buffer.sample(slot, clock), body.position)
		if row[17] == 1: navigation.adjust(slot, command, body, match_state, _tick)
		if match_state.time < BattleRing.GRACE:
			command = PlayerCommand.new()
			command.cancel_actions = true
		if combat != null: combat.prepare(slot, command)
		(body.command_source as BattleCommandSource).command = command
		commands[slot] = command
		body._physics_process(delta)
		row[0] = snappedf(body.position.x, 0.001)
		row[1] = snappedf(body.position.y, 0.001)
		row[2] = snappedf(body.position.z, 0.001)
		row[3] = snappedf(body.velocity.x, 0.001)
		row[4] = snappedf(body.velocity.y, 0.001)
		row[5] = snappedf(body.velocity.z, 0.001)
		row[6] = command.aim.x
		row[7] = command.aim.y
		row[15] = int(body.motor.is_dashing)
		row[19] = (command.aim_point - body.position - Vector3.UP * 0.65).normalized().y if command.aim_point != Vector3.ZERO else 0.0
		row[20] = command.move.x
		row[21] = command.move.y
	if pack != null: pack.requests.flush(clock, rotation)
	# All capsules advance before combat, so roster order grants no movement advantage.
	for offset in bodies.size():
		var slot := (rotation + offset) % bodies.size()
		var command := commands[slot]
		if command == null: continue
		if command.pickup_pressed: _pickup(slot)
		if pack == null:
			if command.use_healing_1: match_state.heal(slot)
		elif match_state.rows[slot][17] == 1:
			if command.use_healing_1: BattlePackBots.heal(pack, slot)
		else:
			var healing := [command.use_healing_1, command.use_healing_2, command.use_healing_3, command.use_healing_4]
			for i in 4:
				if healing[i]: pack.transactions.consume(slot, 1, i + 8)
		if combat != null: combat.prepare(slot, command)
	if mobs != null: mobs.step(delta)
	if combat != null: combat.step(commands, delta, rotation)
	match_state.step(delta)
	if pack != null: pack.step(delta)
	if combat != null: combat.sync()

func _pickup(slot: int) -> void:
	if pack != null:
		if match_state.rows[slot][17] == 1: pack.interact_bot(slot)
		return
	# Nearby loot also needs unobstructed reach, including matching elevation.
	var hidden: Array = []
	var origin := bodies[slot].position + Vector3.UP * 0.6
	for item: Array in match_state.loot:
		if item[5] == 0: continue
		var point := Vector3(item[1], item[2] + 0.4, item[3])
		if origin.distance_squared_to(point) > 8: continue
		var ray := PhysicsRayQueryParameters3D.create(origin, point, 1)
		if not bodies[slot].get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			item[5] = 0
			hidden.append(item)
	if combat != null and not match_state.combat.is_empty():
		match_state.combat[slot][BattleCombatWire.FIELDS.find("vitals")] = combat.fighters[slot].combat.vitals.capture()
	var previous_sp: float = BattleCombatWire.unpack(match_state.combat[slot]).vitals.stamina if not match_state.combat.is_empty() else 100
	match_state.use_loot(slot)
	if combat != null and not match_state.combat.is_empty():
		var added: float = BattleCombatWire.unpack(match_state.combat[slot]).vitals.stamina - previous_sp
		var vitals := combat.fighters[slot].combat.vitals
		vitals.current = minf(100, vitals.current + maxf(0, added))
	for item: Array in hidden: item[5] = 1
