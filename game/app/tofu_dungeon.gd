class_name TofuDungeon
extends Node
## App composition for entry, encounter waves, processing timers, loot and unlock.

var game: Node3D
var state := TofuDungeonState.new()
var factory: TofuFactory
var enabled: bool = true
var cooperative: bool = false
var party: Dictionary = {}
var _carrying: Dictionary = {}
var _connected: Array[Player] = []
var _inside: bool = false
var _cooldown: float = 0.0
var _party_cooldowns: Dictionary = {}
var _spawned_stage: int = -1
var _enemies: Array[FactoryBean] = []
var _crates: Array[FactoryCrate] = []
var _replica_enemies: Array[FactoryBean] = []
var _replica_crates: Array[FactoryCrate] = []

func _ready() -> void:
	factory = game.world.tofu_factory
	state.changed.connect(_sync_unlock)
	_sync_unlock()
	_connect_actor(game.player)

func _process(_delta: float) -> void:
	if factory != null and game.shooting_view != null:
		factory.set_cutaway(not game.shooting_view.first_person)

func _physics_process(delta: float) -> void:
	if not enabled or game.opening != null and game.opening.active: return
	for carrier: Player in _carrying.keys():
		if not is_instance_valid(carrier) or not TofuFactory.contains(carrier.global_position): _carrying.erase(carrier)
	factory.show_cargo(cargo_positions())
	if cooperative:
		_step_party_portals(delta)
		if _party_inside(): _advance_inside(delta)
		return
	if _inside and not TofuFactory.contains(game.player.global_position): _inside = false
	_cooldown = maxf(0.0, _cooldown - delta)
	if _inside:
		if _cooldown <= 0.0 and (factory.entrance_inside_reached(game.player) or state.completed and factory.exit_reached(game.player)):
			_exit()
			return
		_advance_inside(delta)
	elif _cooldown <= 0.0 and factory.entrance_reached(game.player):
		_enter()

func configure_party(members: Dictionary, authority: bool) -> void:
	cooperative = true
	party = members
	enabled = authority
	set_physics_process(authority)
	_sync_unlock()

func _step_party_portals(delta: float) -> void:
	for member: CoopActor in party.values():
		var actor: Player = member.actor
		_connect_actor(actor)
		if not is_instance_valid(actor): continue
		var cooldown: float = maxf(0.0, float(_party_cooldowns.get(actor, 0.0)) - delta)
		_party_cooldowns[actor] = cooldown
		if cooldown > 0.0: continue
		if TofuFactory.contains(actor.global_position):
			if factory.entrance_inside_reached(actor) or state.completed and factory.exit_reached(actor):
				_teleport_actor(actor, TofuFactory.EAST_ENTRANCE + Vector3(-2.5, 0, 0))
				_party_cooldowns[actor] = 2.0
		elif factory.entrance_reached(actor):
			factory.ensure_interior()
			state.enter()
			_teleport_actor(actor, TofuFactory.HALL_ARRIVAL)
			_party_cooldowns[actor] = 1.5
			if actor == game.player: game.hud.announce("Tofu Dungeon · Restart the production line · [E] use stations")

func _party_inside() -> bool:
	for member: CoopActor in party.values():
		if is_instance_valid(member.actor) and TofuFactory.contains(member.actor.global_position): return true
	return false

func _advance_inside(delta: float) -> void:
	for carrier: Player in _carrying.keys():
		if not is_instance_valid(carrier) or not TofuFactory.contains(carrier.global_position): _carrying.erase(carrier)
	for enemy: FactoryBean in _enemies:
		enemy.quarry = _nearest_actor(enemy.global_position)
		if cooperative: _register_target(enemy.target)
	if cooperative:
		for crate: FactoryCrate in _crates: _register_target(crate.target)
	if not state.completed and _spawned_stage != state.stage:
		var center := TofuFactory.CENTERS[state.stage]
		for actor in _actors_inside():
			if actor.global_position.distance_to(center) < 12.0:
				_spawn_stage()
				break
	factory.show_cargo(cargo_positions())
	factory.show_objective(state.stage, state.units, state.secured or (state.stage == 3 and not state.coagulant_added), not _carrying.is_empty())
	if state.step(delta):
		_carrying.clear()
		factory.process_finished(state.stage - 1)
		if state.completed:
			game.hud.announce("Tofu Dungeon complete! Soybean refinement is now legal.")
		else:
			game.hud.announce("%s complete · Next: %s" % [TofuDungeonState.STATIONS[state.stage - 1], TofuDungeonState.STATIONS[state.stage]])
	elif state.process_remaining > 0.0:
		factory.show_processing(state.stage, state.process_remaining)

func _actors_inside() -> Array[Node3D]:
	var result: Array[Node3D] = []
	if not cooperative:
		if _inside: result.append(game.player)
		return result
	for member: CoopActor in party.values():
		if is_instance_valid(member.actor) and TofuFactory.contains(member.actor.global_position): result.append(member.actor)
	return result

func _enter() -> void:
	factory.ensure_interior()
	_inside = true
	_cooldown = 1.5
	state.enter()
	_teleport(TofuFactory.HALL_ARRIVAL)
	game.hud.announce("Tofu Dungeon · Wash → mill → add coagulant → chop → pack · [E] interact")

func _exit() -> void:
	_inside = false
	_carrying.erase(game.player)
	factory.show_cargo(cargo_positions())
	_cooldown = 2.0
	_teleport(TofuFactory.EAST_ENTRANCE + Vector3(-2.5, 0, 0))
	game.hud.announce("Tofu Factory · %s" % ("Refinement unlocked" if state.completed else "Return when ready"))

func _teleport(at: Vector3) -> void:
	_teleport_actor(game.player, at)

func _teleport_actor(actor: Player, at: Vector3) -> void:
	actor.relocate(at)
	actor.velocity = Vector3.ZERO
	if actor == game.player:
		game.camera.global_position = at + game.camera.offset
		game.combat.reset()

func _spawn_stage() -> void:
	var first_visit := _spawned_stage != state.stage
	_spawned_stage = state.stage
	var count := 3 if state.stage < 2 else 4
	if state.stage == 3 and not state.coagulant_added: count = 0
	for i in count:
		var enemy := FactoryBean.new()
		enemy.kind = FactoryBean.Kind.WARDEN if state.stage == 5 and i == 0 else (FactoryBean.Kind.DOFU if state.stage >= 3 else (FactoryBean.Kind.BRUISER if i % 2 == 1 else FactoryBean.Kind.SCOUT))
		enemy.position = TofuFactory.CENTERS[state.stage] + Vector3(-3 + float(i % 3) * 3, 0.1, -1 + float(i / 3) * 3)
		enemy.quarry = _nearest_actor(enemy.position)
		game.world.add_child(enemy)
		enemy.attacked.connect(_enemy_attack)
		enemy.defeated.connect(_enemy_defeated.bind(enemy))
		_register_target(enemy.target)
		_enemies.append(enemy)
	for i in (2 if first_visit else 0):
		var crate_index := state.stage * 2 + i
		if state.crate_broken(crate_index): continue
		var crate := FactoryCrate.new()
		crate.position = TofuFactory.CENTERS[state.stage] + Vector3(-8 if i == 0 else 8, 0, 6)
		game.world.add_child(crate)
		crate.broken.connect(_crate_broken.bind(crate, crate_index))
		_register_target(crate.target)
		_crates.append(crate)
	game.hud.announce("%d / 6 · %s · %s" % [state.stage + 1, TofuDungeonState.STATIONS[state.stage], "Add nigari at the kettle" if state.stage == 3 and not state.coagulant_added else "Secure the production room"])

func _enemy_attack(amount: float, source: Vector3) -> void:
	if cooperative:
		var victim := _nearest_member(source)
		if victim != null and victim.actor.global_position.distance_to(source) < 2.5: victim.hurt(amount, source)
		return
	if not _inside or game.health.current <= 0.0: return
	var push: Vector3 = (game.player.global_position - source).normalized() * 2.0
	game.health.damage(amount, push, Damageable.HitKind.SLIME)

func _enemy_defeated(_at: Vector3, enemy: FactoryBean) -> void:
	_enemies.erase(enemy)
	_unregister_target(enemy.target)
	enemy.queue_free()
	var experience := 65 if enemy.kind != FactoryBean.Kind.WARDEN else 250
	if cooperative:
		var winner := _nearest_member(enemy.global_position)
		if winner != null: winner.progression.progress.award_experience(experience)
	else: game.progression.progress.award_experience(experience)
	if _enemies.is_empty() and not state.completed:
		state.secured = true
		state.begin_process()
		game.hud.announce("Room secure · " + TofuFactory.INSTRUCTIONS[state.stage])

func _crate_broken(at: Vector3, crate: FactoryCrate, index: int) -> void:
	_crates.erase(crate)
	_unregister_target(crate.target)
	state.mark_crate(index)
	if index % 2 == 0:
		game.world_items.pool.spawn("soy_milk", 1, at, Vector2.RIGHT)

func _nearest_actor(at: Vector3) -> Node3D:
	var nearest: Node3D = null
	var distance := INF
	for actor: Node3D in _actors_inside():
		var candidate := actor.global_position.distance_to(at)
		if candidate < distance:
			distance = candidate
			nearest = actor
	return nearest

func _nearest_member(at: Vector3) -> CoopActor:
	var nearest: CoopActor = null
	var distance := INF
	for member: CoopActor in party.values():
		if not TofuFactory.contains(member.actor.global_position): continue
		var candidate := member.actor.global_position.distance_to(at)
		if candidate < distance:
			distance = candidate
			nearest = member
	return nearest

func _register_target(target: Damageable) -> void:
	if not cooperative:
		game.combat.targets.append(target)
		return
	for member: CoopActor in party.values():
		if target not in member.combat.targets: member.combat.targets.append(target)

func _unregister_target(target: Damageable) -> void:
	if not cooperative:
		game.combat.targets.erase(target)
		return
	for member: CoopActor in party.values(): member.combat.targets.erase(target)

func _sync_unlock() -> void:
	if game == null or game.inventory == null: return
	game.inventory.refining_unlocked = state.completed
	for member: CoopActor in party.values(): member.inventory.refining_unlocked = state.completed
	if game.inventory_window != null: game.inventory_window.refresh()

func capture() -> Dictionary:
	return state.capture()

func capture_world() -> Dictionary:
	return TofuDungeonReplica.capture(self)

func apply_world(data: Dictionary) -> void:
	TofuDungeonReplica.apply(self, data)

func restore(data: Dictionary) -> void:
	for enemy: FactoryBean in _enemies:
		_unregister_target(enemy.target)
		enemy.queue_free()
	for crate: FactoryCrate in _crates:
		_unregister_target(crate.target)
		crate.queue_free()
	_enemies.clear()
	_crates.clear()
	_carrying.clear()
	state.restore(data)
	var saved_at: Vector3 = game.player.global_position
	if saved_at.x > 210 and saved_at.x < 230 and saved_at.z > -104 and saved_at.z < 10:
		_teleport(TofuFactory.CENTERS[mini(state.stage, 5)] + Vector3(0,0.2,4))
	state.active = bool(data.get("active", false)) or TofuFactory.contains(game.player.global_position)
	factory.reset_gates(state.stage)
	_inside = TofuFactory.contains(game.player.global_position)
	_spawned_stage = -1
	_cooldown = 1.0

func _connect_actor(actor: Player) -> void:
	if not is_instance_valid(actor) or actor in _connected: return
	_connected.append(actor)
	actor.command_sampled.connect(_command.bind(actor))

func _command(command: PlayerCommand, _delta: float, actor: Player) -> void:
	if enabled and command.pickup_pressed: interact(actor)

func interact(actor: Player) -> bool:
	if not enabled or not TofuFactory.contains(actor.global_position) or state.completed or not state.active: return false
	if state.action_remaining > 0 or state.process_remaining > 0 or (not state.secured and state.stage != 3): return false
	if state.stage == 0 or state.stage == 2:
		if not _carrying.has(actor):
			for i in range(state.units, mini(3, state.units + 1)):
				if actor.global_position.distance_to(TofuFactory.bag(i, state.stage)) < 2.2:
					if i in _carrying.values(): return false
					_carrying[actor] = i
					game.hud.announce("Carrying soy sack · [E] at the hopper to deliver")
					return true
			return false
		if actor.global_position.distance_to(TofuFactory.station(state.stage)) > 2.8: return false
		_carrying.erase(actor)
	elif actor.global_position.distance_to(TofuFactory.station(state.stage)) > 2.8:
		return false
	var added := state.operate()
	if added: game.hud.announce("%s · %d / %d" % [TofuDungeonState.STATIONS[state.stage], state.units, state.required_units()])
	if added and state.stage == 3:
		# Adding nigari awakens the curds; production cannot finish until they fall.
		_spawn_stage()
		game.hud.announce("Nigari added! Dofu are climbing out of the milk!")
	return added

func cargo_positions() -> Array:
	var result: Array = []
	for actor: Player in _carrying:
		if not is_instance_valid(actor): continue
		var at := actor.global_position
		result.append([at.x,at.y,at.z])
	return result
