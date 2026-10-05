class_name ParrotTravel
extends Node
## Free outdoor mount: host/offline steering with collision-aware safe landings.

const SADDLE_HEIGHT: float = 1.04
var game: AdventureGame
var session: CoopSession
var perches := ParrotPerches.new()
var controls := ParrotControls.new()
var mounts := ParrotMountView.new()
var flights: Dictionary[Player, ParrotFlight] = {}

func _ready() -> void:
	name = "ParrotTravel"
	process_physics_priority = -20
	perches.ground_point = game.world.ground_point
	game.world.add_child(perches)
	for i in perches.stations.size():
		game.world.map_npcs["Parrot · " + ParrotPerches.TITLES[i]] = perches.stations[i]
	controls.travel = self
	add_child(controls)
	mounts.travel = self
	add_child(mounts)

func available(actor: Player) -> bool:
	if not eligible(actor) or actor.transport_active: return false
	return perches.nearest(actor.global_position) >= 0 or (actor.parrot_rest.is_finite() and actor.position.distance_to(actor.parrot_rest) <= 4.5)

func eligible(actor: Player) -> bool:
	if not is_instance_valid(actor): return false
	if session != null:
		var key := session.roster.actor_identity(actor)
		if not session.roster.party.has(key) or session.opening.active() or session.duel.is_participant(key): return false
		if session.roster.party[key].spectating or session.roster.party[key].health.current <= 0: return false
	elif (game.opening != null and game.opening.active) or game.health.current <= 0:
		return false
	return not game.factory_dungeon.actor_in_run(actor) and ParrotLanding.outdoor(game, actor.global_position)

func start(actor: Player) -> bool:
	if session != null and not session.authority: return false
	if not available(actor): return false
	var origin := actor.position
	var index := perches.nearest(actor.global_position)
	var at := perches.stations[index].global_position if index >= 0 else (actor.get_parent() as Node3D).to_global(actor.parrot_rest)
	if not actor.relocate(at + Vector3.UP * SADDLE_HEIGHT): return false
	actor.transport_origin = origin
	actor.transport_active = true
	actor.transport_step = step.bind(actor)
	actor.motor.cancel_jump()
	actor.motor.cancel_dash_charge()
	actor.motor.is_dashing = false
	actor.motor.is_super_dashing = false
	var combat := game.combat
	if session != null: combat = session.roster.party[session.roster.actor_identity(actor)].combat
	combat.reset()
	var callback := _release.bind(actor)
	if not actor.tree_exiting.is_connected(callback): actor.tree_exiting.connect(callback, CONNECT_ONE_SHOT)
	var placement_callback := _relocated.bind(actor)
	if not actor.relocated.is_connected(placement_callback): actor.relocated.connect(placement_callback)
	flights[actor] = ParrotFlight.new(actor.global_position)
	# A high perch or parked cloud bird must lift from its present elevation.
	flights[actor].altitude = clampf(actor.global_position.y - ParrotLanding.height(game, actor.global_position) + 7.0, 8.0, ParrotFlight.MAX_ALTITUDE)
	return true

func request_land(actor: Player) -> bool:
	if not flights.has(actor): return false
	var floor_at := ParrotLanding.surface(game, actor)
	if not floor_at.is_finite():
		_notice(actor, "No safe landing here / Fly over clear, dry ground and try again.")
		return false
	flights[actor].landing = not flights[actor].landing
	return true

func step(command: PlayerCommand, delta: float, actor: Player) -> void:
	if not flights.has(actor): return
	var flight := flights[actor]
	if actor.global_position.distance_to(flight.last_position) > 4.0:
		_finish(actor)
		return
	if command.cancel_actions:
		actor.velocity = Vector3.ZERO
		flight.planar = Vector2.ZERO
		return
	var base := ParrotLanding.height(game, actor.global_position)
	var floor_at := ParrotLanding.surface(game, actor) if flight.landing else Vector3.INF
	if flight.landing and not floor_at.is_finite(): flight.landing = false
	if floor_at.is_finite(): base = floor_at.y
	actor.velocity = flight.velocity(command.move, command.jump_held, command.dash_held, actor.global_position.y - base, delta)
	actor.collision_mask = 3
	var progression := game.progression
	if session != null: progression = session.roster.party[session.roster.actor_identity(actor)].progression
	actor.set_collision_mask_value(JungleWorld.GATE_LAYER, progression.progress.level() < JungleWorld.ENTRY_LEVEL)
	actor.move_and_slide()
	var local := game.world.to_local(actor.global_position)
	local.x = clampf(local.x, MapExploration.BOUNDS.position.x + 1, MapExploration.BOUNDS.end.x - 1)
	local.z = clampf(local.z, MapExploration.BOUNDS.position.y + 1, MapExploration.BOUNDS.end.y - 1)
	if progression.progress.level() < JungleWorld.ENTRY_LEVEL and flight.last_position.z < JungleTerrain.SOUTH_START:
		local.z = minf(local.z, JungleTerrain.SOUTH_START - 0.5)
	actor.global_position = game.world.to_global(local)
	flight.last_position = actor.global_position
	if flight.landing and actor.global_position.y - base <= SADDLE_HEIGHT + 0.16:
		if ParrotLanding.dismount(game, actor, floor_at):
			_finish(actor)
			_notice(actor, "Landed / Your parrot waits here. Press interact to ride again.")
		else:
			flight.landing = false
			_notice(actor, "Landing blocked / Move to a clear spot and try again.")

func _physics_process(_delta: float) -> void:
	for actor: Player in flights.keys():
		if actor.global_position.distance_to(flights[actor].last_position) > 4.0: _finish(actor)

func _finish(actor: Player) -> void:
	actor.transport_active = false
	actor.transport_step = Callable()
	actor.velocity = Vector3.ZERO
	actor.motor.cancel_jump()
	flights.erase(actor)

func _notice(actor: Player, message: String) -> void:
	if actor == game.player: game.hud.announce(message)

func saved_party(party: Dictionary) -> Dictionary:
	if session == null: return party
	for key: String in party:
		var actor: Player = session.roster.actors.get(key)
		if is_instance_valid(actor) and actor.transport_active:
			party[key].position = CoopValues.array3(actor.transport_origin)
			party[key].velocity = [0, 0, 0]
		party[key].erase("transport")
	return party

func _release(actor: Player) -> void:
	flights.erase(actor)

func _relocated(actor: Player) -> void:
	if flights.has(actor): _finish(actor)
