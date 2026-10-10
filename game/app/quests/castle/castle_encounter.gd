class_name CastleEncounter
extends RefCounted
## Composes bounded castle combat targets with world views and trial outcomes.

var flow: CastleAdventure
var guards: Array[CastleSentinel] = []
var king: LavaKingFighter
var empty_clock: float = 0.0
var entry_gates: Array[CastleGate] = []
var arena_gate: CastleGate

func build() -> void:
	for deck in 3:
		var floor_node := flow.castle.floors[deck]
		for slot in 3:
			var guard := CastleSentinel.new()
			guard.rank = deck
			var path := floor_node.layout.solution
			guard.home = [15, 28, path.size() - 12][slot]
			guard.waypoint = guard.home
			for cell in path: guard.route.append(floor_node.to_global(CastleMazeLayout.center(cell, 0)))
			floor_node.add_child(guard)
			guard.global_position = guard.route[guard.home]
			guard.attacked.connect(func(victim: Node3D, amount: float, source: Vector3) -> void: flow.party.hurt(victim, amount, source, false))
			guard.defeated.connect(_guard_defeated.bind(deck * 3 + slot))
			guard.spells.impacted.connect(flow.party.hurt)
			guards.append(guard)
			flow.game.combat.targets.append(guard.target)
	king = LavaKingFighter.new()
	flow.add_child(king)
	king.origin = flow.castle.to_global(Vector3(0, 24, 0))
	king.global_position = flow.castle.king.global_position
	king.spells.impacted.connect(flow.party.hurt)
	king.defeated.connect(_victory)
	king.enraged.connect(func() -> void: flow.state.message = "KING LAVA: Control is not stillness. Move with the fire!" )
	flow.game.combat.targets.append(king.target)
	for child in flow.castle.king.get_children():
		if child is StaticBody3D: child.collision_layer = 0
	for deck in 3:
		var gate := CastleGate.new()
		gate.position = Vector3(0, 0, -27 if deck % 2 == 0 else 27)
		var parent: Node3D = flow.castle.floors[deck + 1] if deck < 2 else flow.castle.plaza
		parent.add_child(gate)
		if deck < 2: flow.castle.floors[deck + 1].arrival_gate = gate
		entry_gates.append(gate)
	arena_gate = entry_gates[2]

func step(delta: float) -> void:
	_update_king_targets()
	var actors := flow.party.actors()
	for index in guards.size():
		var guard := guards[index]
		guard.quarry = null
		if guard.target.current <= 0: continue
		var best := INF
		for actor: Player in actors:
			var local := flow.castle.floors[index / 3].to_local(actor.global_position)
			if local.y < -0.2 or local.y > 3.0 or absf(local.x) > 26 or absf(local.z) > 26: continue
			var distance := guard.global_position.distance_to(actor.global_position)
			if distance < best and distance < 18: best = distance; guard.quarry = actor
		guard.ranged_threat = false
		if guard.quarry != null:
			var member := flow.party.member_for(guard.quarry)
			var combat: PlayerCombat = member.combat if member != null else flow.game.combat
			guard.ranged_threat = combat.ranged_selected()
	if not king.active: return
	king.spells.actors = flow.party.actors(true)
	king.quarry = null
	var nearest := INF
	for actor in king.spells.actors:
		var distance := actor.global_position.distance_to(king.global_position)
		if distance < nearest: nearest = distance; king.quarry = actor
	empty_clock = empty_clock + delta if king.spells.actors.is_empty() else 0.0
	if empty_clock >= 2.5:
		king.reset()
		arena_gate.set_open(true)
		flow.party.burns.clear()
		flow.party.release_fallen()
		flow.state.message = "KING LAVA: Gather your strength. The trial may be attempted again."

func begin() -> void:
	flow.state.participants.clear()
	for actor: Player in flow.party.actors():
		if flow.party.inside_arena(actor): flow.state.participants.append(flow.party.key(actor))
	king.begin(flow.state.participants.size())
	_update_king_targets()
	empty_clock = 0
	arena_gate.set_open(false)
	flow.state.revision += 1
	flow.state.message = "KING LAVA: Prove your fire has purpose! Cooling pools extinguish burning."

func _guard_defeated(index: int) -> void:
	if not flow.authoritative: return
	flow.state.guard_defeated(index)
	flow.present_state()

func _victory() -> void:
	if not flow.authoritative: return
	flow.state.completed = true
	flow.state.revision += 1
	flow.state.message = "KING LAVA: You cooled the flame without breaking the mountain. Accept my blessing, young Fufu."
	arena_gate.set_open(true)
	flow.party.burns.clear()
	flow.party.release_fallen()
	flow.present_state()

func authority(value: bool) -> void:
	king.authoritative = value
	king.set_physics_process(value)
	king.target.set_physics_process(value)
	king.spells.authoritative = value
	for guard in guards:
		guard.authoritative = value
		guard.spells.authoritative = value
		guard.spells.set_physics_process(value)
		guard.set_physics_process(value and guard.target.current > 0)
		guard.target.set_physics_process(value)

func _update_king_targets() -> void:
	if not king.active: return
	if flow.party.members.is_empty():
		_set_king_target(flow.game.combat, flow.party.inside_arena(flow.game.player))
	else:
		for member: CoopActor in flow.party.members.values():
			var eligible := flow.party.key(member.actor) in flow.state.participants and flow.party.inside_arena(member.actor)
			_set_king_target(member.combat, eligible)

func _set_king_target(combat: PlayerCombat, eligible: bool) -> void:
	if eligible and king.target not in combat.targets: combat.targets.append(king.target)
	elif not eligible and king.target in combat.targets: combat.targets.erase(king.target)
