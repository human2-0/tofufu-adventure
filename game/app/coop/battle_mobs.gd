class_name BattleMobs
extends RefCounted
## Reuses adventure enemies; authority alone advances their physics and rewards.

var game: BattleRoyaleGame
var actors: Array[TrainingMob] = []
var tick: int = 0
var awake: Array[bool] = []
var ranged: Array[BattleMobRanged] = []

func accepts(values: Array) -> bool:
	if values.is_empty(): return actors.is_empty()
	if actors.is_empty(): return true
	if values[0].size() != actors.size(): return false
	for id in actors.size():
		var previous: Array = game.match_state.mobs[0][id]
		if values[0][id].slice(0, 4) != previous.slice(0, 4): return false
	return true

func present(delta: float = 0) -> void:
	if game.match_state.mobs.is_empty(): return
	var rows: Array = game.match_state.mobs[0]
	while actors.size() < rows.size(): _build(actors.size(), rows[actors.size()])
	if game.room.authority(): return
	for i in actors.size():
		var state: Array = rows[i][4].duplicate()
		var target := Vector3(state[0], state[1], state[2])
		if delta > 0 and actors[i].position.distance_squared_to(target) < 25:
			target = actors[i].position.lerp(target, 1.0 - exp(-22 * delta))
			state[0] = target.x
			state[1] = target.y
			state[2] = target.z
		EncounterState.apply_mob(actors[i], state)
		ranged[i].present(rows[i][14], delta)

func _build(id: int, row: Array) -> void:
	var mob: TrainingMob = [TrainingMob, ArmoredSnail, WildBee][int(row[0])].new()
	mob.position = Vector3(row[1], row[2], row[3])
	game.add_child(mob)
	mob.leash_radius = 18
	mob.tuning = mob.tuning.duplicate()
	mob.tuning.dry_health = BattleMobWire.HEALTH[int(row[0])]
	mob.target.maximum = mob.tuning.dry_health
	if mob is WildBee: mob.ranged_enabled = false
	mob.set_physics_process(false)
	mob.target.set_physics_process(false)
	mob.target.attack_receiver = receive.bind(id)
	mob.attacked.connect(_melee.bind(id))
	mob.defeated.connect(_defeated.bind(id))
	if mob is WildBee: mob.stung.connect(_sting.bind(id))
	actors.append(mob)
	awake.append(false)
	var shot := BattleMobRanged.new()
	shot.build(game, mob, int(row[0]), id)
	ranged.append(shot)
	shot.restore(row[14])
	BattleMobState.restore(mob, row)
	for fighter in game.combat.fighters:
		fighter.combat.targets.append(mob.target)
		fighter.combat.gun.targets = fighter.combat.targets
		fighter.combat.sotjet.flow.targets = fighter.combat.targets

func step(delta: float) -> void:
	if not game.room.authority() or not game.playing or game.deployment.active() or game.match_state.winner != -2: return
	if game.match_state.mobs.is_empty() or game.match_state.time < BattleRing.GRACE: return
	tick += 1
	for id in actors.size():
		var mob := actors[id]
		var row: Array = game.match_state.mobs[0][id]
		ranged[id].step(delta, awake[id] and row[9] == 0)
		if row[9] != 0:
			if tick % 60 == id % 60: BattleHuntLoot.release(game, id)
			continue
		if (tick + id) % 15 == 0:
			_select(id)
			BattleMobState.capture(mob, row)
		if BattleRing.outside(mob.position, game.match_state.time, game.match_state.circle):
			# Like survivor storm damage, this bypasses shell/guard and invulnerability.
			mob.target.current = maxf(0, mob.target.current - BattleRing.damage(game.match_state.time) * delta)
			if mob.target.current <= 0:
				row[9] = 3
				mob._die()
			BattleMobState.capture(mob, row)
		if row[9] != 0: continue
		mob.target._physics_process(delta)
		if awake[id]: mob._physics_process(delta)
		if mob is WildBee:
			if mob._windup > 0: mob.facing = Vector3(mob._sting_aim.x, 0, mob._sting_aim.z).normalized()
			elif not mob.velocity.is_zero_approx(): mob.facing = Vector3(mob.velocity.x, 0, mob.velocity.z).normalized()
		if mob.position.y < -4 or mob._respawn > 0:
			row[9] = 3
			mob.target.current = 0
			mob.hide()
			mob.collision_layer = 0
			BattleMobState.capture(mob, row)

func _select(id: int) -> void:
	var mob := actors[id]
	var nearest := 11664.0
	var chosen := -1
	for offset in game.bodies.size():
		var slot := (id + offset) % game.bodies.size()
		if game.match_state.rows[slot][8] <= 0: continue
		var at := game.bodies[slot].position
		if absf(at.y - mob.position.y) > 32: continue
		var distance := at.distance_squared_to(mob.position)
		if distance < nearest:
			nearest = distance
			chosen = slot
	awake[id] = chosen >= 0
	mob.quarry = game.bodies[chosen] if chosen >= 0 else null
	if chosen < 0:
		mob._windup = 0
		mob._warning.hide()
		if mob is ArmoredSnail: mob._cancel_rush()
		if mob is WildBee: mob.sting.clear()
	game.match_state.mobs[0][id][11] = chosen

func receive(amount: float, direction: Vector3, kind: Damageable.HitKind, point: Vector3, source: Damageable, id: int) -> bool:
	if not is_finite(amount) or amount <= 0: return false
	if not game.room.authority() or not game.playing or game.deployment.active(): return false
	if game.match_state.winner != -2 or game.match_state.time < BattleRing.GRACE: return false
	var killer := -1
	for slot in game.combat.fighters.size():
		if game.combat.fighters[slot].health == source and game.match_state.rows[slot][8] > 0: killer = slot
	if killer < 0 or game.match_state.mobs[0][id][9] != 0: return false
	var row: Array = game.match_state.mobs[0][id]
	row[10] = killer
	var accepted := actors[id].target.damage(amount, direction, kind, point)
	BattleMobState.capture(actors[id], row)
	BattleHuntLoot.release(game, id)
	if accepted and row[9] == 0:
		actors[id].quarry = game.bodies[killer]
		awake[id] = true
	return accepted

func _defeated(_at: Vector3, id: int) -> void:
	var row: Array = game.match_state.mobs[0][id]
	if row[9] != 0: return
	row[9] = 1
	if row[10] >= 0: game.match_state.mobs[1][int(row[10])] += 1

func _melee(amount: float, source: Vector3, id: int) -> void:
	var quarry := actors[id].quarry
	if not is_instance_valid(quarry): return
	_sting(quarry, amount, source, id)

func _sting(victim: Node3D, amount: float, source: Vector3, id: int) -> void:
	if not game.room.authority() or not game.playing or game.deployment.active(): return
	for slot in game.bodies.size():
		if game.bodies[slot] != victim: continue
		game.combat.fighters[slot].health.receive_attack(amount, victim.position - source, Damageable.HitKind.MELEE, Vector3.INF, actors[id].target)
		return

func capture() -> void:
	if game.match_state.mobs.is_empty(): return
	for id in actors.size():
		BattleMobState.capture(actors[id], game.match_state.mobs[0][id])
		game.match_state.mobs[0][id][14] = ranged[id].capture()

func restore() -> void:
	present()
	for id in actors.size():
		BattleMobState.restore(actors[id], game.match_state.mobs[0][id])
		ranged[id].restore(game.match_state.mobs[0][id][14])
		game.match_state.mobs[0][id][14] = ranged[id].capture()
		_select(id)
	tick = 0
