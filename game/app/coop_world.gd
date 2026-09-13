class_name CoopWorld
extends RefCounted
## World state composition. Replica application bypasses gameplay callbacks.

static func capture(game: Node3D) -> Dictionary:
	var encounters: SandboxEncounters = game.encounters
	var data := {"mobs": [], "props": [], "dummies": [], "pickups": [], "phase": game.cycle.phase,
		"weather_phase": game.weather.phase,
		"beans": encounters.beans, "kills": encounters.mobs, "harvests": encounters.props,
		"experience": encounters.experience, "places": game.exploration.found_places(), "next_pickup": encounters.next_pickup_id}
	for mob in encounters.mob_nodes: data.mobs.append(EncounterState.mob(mob))
	for prop in encounters.prop_nodes: data.props.append(EncounterState.prop(prop))
	for dummy in encounters.dummy_nodes: data.dummies.append(EncounterState.dummy(dummy))
	for id: int in encounters.pickups:
		var bean := encounters.pickups[id]
		if not bean.is_queued_for_deletion() and not bean._collected: data.pickups.append(EncounterState.pickup(id, bean))
	return data

static func apply(game: Node3D, data: Dictionary, replica: bool) -> void:
	var encounters: SandboxEncounters = game.encounters
	game.weather.set_phase(float(data.get("weather_phase", 0.0)))
	for i in data.mobs.size(): EncounterState.apply_mob(encounters.mob_nodes[i], data.mobs[i])
	for i in encounters.prop_nodes.size(): EncounterState.apply_prop(encounters.prop_nodes[i], data.props[i])
	for i in encounters.dummy_nodes.size(): EncounterState.apply_dummy(encounters.dummy_nodes[i], data.dummies[i])
	if not replica:
		# Older checkpoints may place restored mobs on top of party members.
		for body in game.player.placement_peers:
			if is_instance_valid(body) and body is Player: body.relocate(body.global_position)
	var live: Array[int] = []
	for state: Array in data.pickups:
		var id := int(state[0])
		live.append(id)
		var bean: SoybeanPickup = encounters.pickups.get(id)
		if bean == null: bean = encounters.add_pickup(id, Vector3.ZERO)
		bean.set_physics_process(not replica)
		EncounterState.apply_pickup(bean, state)
	for id: int in encounters.pickups.keys():
		if id not in live: encounters.pickups[id].free()
	encounters.next_pickup_id = maxi(encounters.next_pickup_id, int(data.next_pickup))
	encounters.beans = int(data.beans)
	encounters.mobs = int(data.kills)
	encounters.props = int(data.harvests)
	encounters.experience = int(data.experience)
	game.cycle.phase = data.phase
	if game.exploration.found_places() != data.places: game.exploration.restore_places(data.places)
	game.hud.show_progress(encounters.beans, encounters.mobs, encounters.props)
	game.hud.show_experience(encounters.experience)

static func disable_simulation(game: Node3D) -> void:
	game.set_physics_process(false)
	game.weather.set_physics_process(false)
	game.exploration.set_physics_process(false)
	for entity: Node in game.encounters.mob_nodes + game.encounters.prop_nodes + game.encounters.dummy_nodes:
		entity.set_physics_process(false)
		entity.target.set_physics_process(false)
