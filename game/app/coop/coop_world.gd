class_name CoopWorld
extends RefCounted
## World state composition. Replica application bypasses gameplay callbacks.

static func capture(game: Node3D) -> Dictionary:
	var encounters: SandboxEncounters = game.encounters
	var data := {"mobs": [], "props": [], "dummies": [], "apple_trees": [], "pickups": [], "phase": game.cycle.phase,
		"produce": game.meadow_harvest.capture(), "barn": game.seed_storage.barn.capture(), "weather_phase": game.weather.phase, "farming": game.farming.capture(), "seed_storage": game.seed_storage.barn.banks[0].capture(), "seed_satchel_claimed": game.seed_storage.free_satchel_claimed,
		"beans": encounters.beans, "kills": encounters.mobs, "harvests": encounters.props,
		"experience": encounters.experience, "places": game.exploration.found_places(), "next_pickup": encounters.next_pickup_id, "world_items": game.world_items.pool.capture(), "factory": game.factory_dungeon.capture_world()}
	for mob in encounters.mob_nodes: data.mobs.append(EncounterState.mob(mob))
	for prop in encounters.prop_nodes: data.props.append(EncounterState.prop(prop))
	for dummy in encounters.dummy_nodes: data.dummies.append(EncounterState.dummy(dummy))
	for index in game.world.apple_trees.size():
		data.apple_trees.append([game.apple_tree_targets[index].current, game.world.apple_trees[index].regrow_remaining])
	for id: int in encounters.pickups:
		var bean := encounters.pickups[id]
		if not bean.is_queued_for_deletion() and not bean._collected: data.pickups.append(EncounterState.pickup(id, bean))
	return data

static func apply(game: Node3D, data: Dictionary, replica: bool) -> void:
	if data.get("factory") is Dictionary and not DungeonSnapshotValidation.valid(data.factory, replica): return
	if data.has("barn") and not BarnProtocol.valid(data.barn, WorldProtocol.ITEM_LIMITS): return
	if data.has("produce") and not BarnProtocol.produce(data.produce): return
	var encounters: SandboxEncounters = game.encounters
	if data.has("farming"): game.farming.restore(data.farming)
	if data.has("seed_storage") and data.seed_storage != game.seed_storage.barn.banks[0].capture():
		game.seed_storage.barn.banks[0].restore(data.seed_storage)
	if not replica and not data.has("barn") and game.seed_storage.barn.banks[0].occupied_slots() > 0: game.seed_storage.barn.owners[0] = game.seed_storage.barn.key(game.player)
	if data.has("produce"): game.meadow_harvest.restore(data.produce, replica)
	if data.has("barn"): game.seed_storage.barn.restore(data.barn)
	if data.has("seed_satchel_claimed"): game.seed_storage.free_satchel_claimed = data.seed_satchel_claimed
	if data.has("world_items"): game.world_items.pool.restore(data.world_items)
	if data.has("factory"):
		if replica: game.factory_dungeon.apply_world(data.factory)
		else: game.factory_dungeon.restore(data.factory)
	game.weather.set_phase(float(data.get("weather_phase", 0.0)))
	for i in data.mobs.size(): EncounterState.apply_mob(encounters.mob_nodes[i], data.mobs[i], replica)
	for i in encounters.prop_nodes.size(): EncounterState.apply_prop(encounters.prop_nodes[i], data.props[i], replica)
	for i in encounters.dummy_nodes.size(): EncounterState.apply_dummy(encounters.dummy_nodes[i], data.dummies[i], replica)
	if data.has("apple_trees"):
		for i in mini(game.world.apple_trees.size(), data.apple_trees.size()):
			var tree: AppleTree = game.world.apple_trees[i]
			var target: Damageable = game.apple_tree_targets[i]
			target.current = data.apple_trees[i][0]
			tree.apply_world_state(data.apple_trees[i][1])
	if not replica:
		# Older checkpoints may place restored mobs on top of party members.
		for body in game.player.placement_peers:
			if is_instance_valid(body) and body is Player: body.relocate(body.global_position)
	var live: Array[int] = []
	for state: Array in data.pickups:
		var id := int(state[0])
		live.append(id)
		var bean: SoybeanPickup = encounters.pickups.get(id)
		if bean == null: bean = encounters.add_pickup(id, Vector3.ZERO, int(state[10]) if state.size() > 10 else 1)
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
	game.meadow_harvest.authoritative = false
	for plant: MeadowProduce in game.world.produce: plant.set_physics_process(false)
	game.factory_dungeon.enabled = false
	game.factory_dungeon.set_physics_process(false)
	game.world_items.pool.authoritative = false
	for drop: WorldItemDrop in game.world_items.pool.drops.values(): drop.authoritative = false
	game.set_physics_process(false)
	game.weather.set_physics_process(false)
	game.exploration.set_physics_process(false)
	for entity: Node in game.encounters.mob_nodes + game.encounters.prop_nodes + game.encounters.dummy_nodes:
		entity.set_physics_process(false)
		entity.target.set_physics_process(false)
	for index in game.world.apple_trees.size():
		var tree: AppleTree = game.world.apple_trees[index]
		tree.set_physics_process(false)
		game.apple_tree_targets[index].set_physics_process(false)
