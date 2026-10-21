class_name BattleWorldSetup
extends RefCounted
## Uses the authored exploration map and existing sprites/models without its quests.

static func actors(game: BattleRoyaleGame) -> void:
	var scene := load("res://game/player/player.tscn") as PackedScene
	var spawns: Array[Vector3] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = game.room.epoch.hash()
	var rotation := rng.randf_range(0, TAU)
	var count := BattleOptions.seats(game.room.options, game.room.members.size())
	for slot in count:
		var angle := rotation + slot * TAU / float(count)
		var spread := sqrt(maxf(1.0, count / 20.0))
		var radius := (58.0 + (slot % 3) * 10.0) * spread
		var at := game.world.ground_point(cos(angle) * radius, sin(angle) * radius, 1.0)
		var actor := scene.instantiate() as Player
		var source := BattleCommandSource.new()
		actor.add_child(source)
		actor.command_source = source
		(actor.get_node("LocalInput") as LocalPlayerInput).enabled = false
		actor.position = at
		game.add_child(actor)
		actor.set_physics_process(false)
		actor.get_node("LocalInput").queue_free()
		actor.get_node("GroundShadow").set_process(false)
		var skin := int(game.room.members[slot].skin) if slot < game.room.members.size() else slot % 8
		if skin > 0: actor.visuals.test_skin.select(TofufuTestArt.IDS[skin - 1])
		actor.visuals.present(PlayerCommand.new(), Vector3.ZERO, true, false, 0.0)
		if not game.room.authority():
			actor.collision_layer = 2 # Aim queries can target cosmetic replicas; they never simulate hits.
			actor.collision_mask = 0
		game.bodies.append(actor)
		spawns.append(at)
	game.match_state.initialize(spawns, game.room.members.size(), game.room.options)
	game.simulation.match_state = game.match_state
	game.simulation.bodies = game.bodies

static func place(game: BattleRoyaleGame) -> void:
	if not game.room.authority(): return
	for slot in game.bodies.size():
		var actor := game.bodies[slot]
		actor.placement_peers.assign(game.bodies)
		var origin := actor.position
		for attempt in 32:
			var angle := attempt * 2.4
			var radius := sqrt(float(attempt)) * 1.8
			var at := game.world.ground_point(origin.x + cos(angle) * radius, origin.z + sin(angle) * radius, 0.08)
			if game.world.is_water(at): continue
			if actor.relocate(at): break
		game.match_state.rows[slot][0] = actor.position.x
		game.match_state.rows[slot][1] = actor.position.y
		game.match_state.rows[slot][2] = actor.position.z
	if not BattlePlantLayout.populate(game):
		game.room.finish("Could not safely deploy at this plant. Please start a new match.")
		return
	BattleChestLayout.populate(game)
	BattleStormLayout.choose(game)
	BattleMobLayout.populate(game)

static func interiors(game: BattleRoyaleGame) -> void:
	var view := GigalopolisInteriorView.new()
	view.actor = game.bodies[game.local_slot]
	view.camera = game.camera
	view.rooms = game.world.city_rooms
	game.add_child(view)
