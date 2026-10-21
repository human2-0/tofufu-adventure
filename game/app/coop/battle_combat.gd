class_name BattleCombat
extends Node
## All capsules move before adventure attacks; attributed hits commit together.

var game: BattleRoyaleGame
var fighters: Array[BattleFighter] = []
var pending: Array = []
var pending_pushes: Array = []

func build() -> void:
	for slot in game.bodies.size():
		var fighter := BattleFighter.new()
		fighter.actor = game.bodies[slot]
		add_child(fighter)
		fighter.authority(game.room.authority())
		fighter.equip(game.match_state.rows[slot])
		fighter.health.attack_receiver = receive.bind(slot)
		fighter.health.pushed.connect(_push.bind(slot))
		fighters.append(fighter)
	for slot in game.bodies.size():
		var combat := fighters[slot].combat
		for other in game.bodies.size():
			if BattleTeams.allies(game.match_state.options, slot, other): continue
			combat.targets.append(fighters[other].health)
			combat.clash.opponents.append(fighters[other].combat)
		combat.gun.targets = combat.targets
		combat.sotjet.flow.targets = combat.targets
	capture()

func prepare(slot: int, command: PlayerCommand) -> void:
	var row: Array = game.match_state.rows[slot]
	var fighter := fighters[slot]
	if command.drop_pressed and not fighter.combat.active and not fighter.combat.claws.busy():
		if game.pack != null: game.pack.transactions.drop(slot, 1, 5 + fighter.loadout.active_slot)
		else: game.match_state.drop(slot)
		command.drop_pressed = false
	if command.weapon_slot in [1, 2] and not fighter.combat.active and not fighter.combat.claws.busy():
		row[18] = command.weapon_slot
		row[10] = row[21 + command.weapon_slot]
	fighter.equip(row)
	fighter.health.current = float(row[8])

func step(commands: Array[PlayerCommand], delta: float, rotation: int) -> void:
	for offset in game.bodies.size():
		var slot := (rotation + offset) % game.bodies.size()
		if commands[slot] != null: fighters[slot].step(commands[slot], delta)
	for hit: Array in pending:
		var slot := int(hit[0])
		var before: float = game.match_state.rows[slot][8] + game.match_state.rows[slot][9]
		game.match_state.hit(slot, hit[1], hit[2])
		var health := fighters[slot].health
		health.current = float(game.match_state.rows[slot][8])
		health.last_hit_amount = before - health.current - float(game.match_state.rows[slot][9])
		health.last_hit_kind = hit[4]
		health.hit.emit(hit[1], hit[3])
	for push: Array in pending_pushes:
		if game.match_state.rows[push[0]][8] > 0: game.bodies[push[0]].apply_push(push[1])
	pending.clear()
	pending_pushes.clear()

func receive(amount: float, direction: Vector3, kind: Damageable.HitKind, _point: Vector3, source: Damageable, slot: int) -> bool:
	if not game.room.authority() or not game.playing or game.deployment.active() or game.match_state.winner != -2: return false
	if game.match_state.time < BattleRing.GRACE or game.match_state.rows[slot][8] <= 0: return false
	var attacker := -1
	for index in fighters.size():
		if fighters[index].health == source: attacker = index
	if BattleTeams.allies(game.match_state.options, slot, attacker): return false
	var fighter := fighters[slot]
	if fighter.actor.motor.is_dashing or fighter.combat.claws.dashing: return false
	fighter.combat.vitals.engage()
	if kind != Damageable.HitKind.SOY and source != null and fighter.combat.equipment.defend(source.body.global_position, amount):
		fighter.health.hit_absorbed = true
		return false
	amount *= fighter.health.armor_multiplier
	fighter.health.hit_absorbed = false
	fighter.health.last_hit_amount = minf(amount, float(game.match_state.rows[slot][8]) + float(game.match_state.rows[slot][9]))
	pending.append([slot, amount, attacker, direction, kind])
	return true

func sync() -> void:
	for slot in game.bodies.size():
		var row: Array = game.match_state.rows[slot]
		var fighter := fighters[slot]
		fighter.health.current = float(row[8])
		fighter.visible = row[8] > 0
		if row[8] <= 0: fighter.clear_flights()
		row[11] = fighter.combat.gun.magazine
		row[14] = fighter.combat.gun.shot_sequence + fighter.combat.equipment.punch_sequence
		row[18] = fighter.loadout.active_slot
		game.match_state.reloads[slot] = fighter.combat.gun.reload_remaining

func capture() -> void:
	sync()
	game.match_state.combat.clear()
	for fighter in fighters:
		var state := CombatState.capture(fighter.combat)
		state.gun_clock = fighter.combat.gun.cooldown
		state.click_clock = fighter.combat.equipment._click_remaining
		state.refill_wait = fighter.combat.sotjet._refill_wait
		state.recoil_quiet = minf(fighter.combat.gun.recoil.quiet_time, 0.12)
		state.cloud_sequence = fighter.cloud_sequence
		state.cloud_at = [fighter.cloud_at.x, fighter.cloud_at.y, fighter.cloud_at.z]
		game.match_state.combat.append(BattleCombatWire.pack(state))

func present() -> void:
	if game.match_state.combat.is_empty(): return
	for slot in game.bodies.size():
		var fighter := fighters[slot]
		fighter.health.current = float(game.match_state.rows[slot][8])
		fighter.visible = fighter.health.current > 0
		var row: Array = game.match_state.rows[slot]
		var state := BattleCombatWire.unpack(game.match_state.combat[slot])
		if int(state.cloud_sequence) > fighter.cloud_sequence: FartCloud.spawn(fighter, CombatState._vector(state.cloud_at))
		fighter.cloud_sequence = int(state.cloud_sequence)
		CombatState.present(fighter.combat, state, Vector2(row[6], row[7]))
		game.presentation.gunfire.replica(slot, state)
		var aiming: bool = state.guard or state.ads or state.gun_charge > 0 or state.jet_firing or state.bow_charge > 0 or state.punch > 0
		fighter.actor.visuals.attack_facing = Vector2(state.aim[0], state.aim[1]) if state.active else (Vector2(row[6], row[7]) if aiming else Vector2.ZERO)

func restore(values: Array, authority_enabled: bool) -> void:
	pending.clear()
	pending_pushes.clear()
	game.match_state.combat = values.duplicate(true)
	for slot in game.bodies.size():
		var fighter := fighters[slot]
		fighter.clear_flights()
		fighter._gear.clear()
		fighter.equip(game.match_state.rows[slot])
		var state := BattleCombatWire.unpack(values[slot])
		CombatState.restore(fighter.combat, state)
		fighter.cloud_sequence = int(state.cloud_sequence)
		fighter.cloud_at = CombatState._vector(state.cloud_at)
		# Cancel transient attacks, retaining SP, reloads and every special cooldown.
		fighter.combat.active = false
		fighter.combat.plunge.cancel()
		fighter.combat.claws.cancel()
		fighter.combat.gun.cooldown = maxf(0.22, float(state.gun_clock))
		fighter.combat.equipment._click_remaining = maxf(0.16, float(state.click_clock))
		fighter.combat.gun.charge_elapsed = 0
		fighter.combat.gun.recoil.heat = float(state.recoil)
		fighter.combat.gun.recoil.quiet_time = float(state.recoil_quiet)
		fighter.combat.sotjet._refill_wait = float(state.refill_wait)
		fighter.combat.gun._replica_sequence = int(state.shot)
		fighter.combat.gun._replica_ricochet_sequence = int(state.ricochet)
		fighter.combat.bow._replica_sequence = int(state.bow_shot)
		fighter.combat.bow._replica_burst = int(state.bow_burst)
		fighter.health.current = float(game.match_state.rows[slot][8])
		fighter.authority(authority_enabled)

func _push(impulse: Vector3, slot: int) -> void:
	pending_pushes.append([slot, impulse])
