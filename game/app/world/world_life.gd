class_name WorldLife
extends Node
## Composes local wildlife and movement presentation without gameplay outcomes.

var game: AdventureGame
var birds: MeadowBirds
var particles: MotionParticles
var audio: OutdoorAudio
var grass: GrassResponse
var _skid_timer: float = 0.0
var _scare_timer: float = 0.0
var _last_velocity: Vector3

func _ready() -> void:
	name = "WorldLife"
	birds = MeadowBirds.new()
	birds.ground_point = game.world.ground_point
	birds.habitat = _habitat
	game.world.add_child(birds)
	particles = MotionParticles.new()
	game.world.add_child(particles)
	audio = OutdoorAudio.new()
	audio.flock = birds
	audio.focus = game.player
	game.world.add_child(audio)
	var ocean := OceanExperience.new()
	ocean.game = game
	add_child(ocean)
	grass = GrassResponse.new()
	grass.game = game
	add_child(grass)
	var feet := game.player.get_node("PlayerFootsteps") as PlayerFootsteps
	feet.stepped.connect(_step)
	feet.landed.connect(_land)
	game.player.dashed.connect(_dash)
	game.player.command_sampled.connect(_command)

func _physics_process(delta: float) -> void:
	var outdoor := _outdoor()
	particles.snow_context = TerrainLocomotion.winter(game.player.global_position)
	birds.observers.clear()
	for actor in game.player.placement_peers:
		if is_instance_valid(actor) and actor is Player: birds.observers.append(actor)
	birds.daylight = clampf(sin(game.cycle.phase * TAU - PI * 0.5) * 1.5, 0, 1)
	birds.raining = game.weather.condition == WeatherCycle.Condition.RAIN
	audio.enabled = outdoor
	audio.present(delta, game.wind.strength, birds.raining and not game.weather_particles.winter, maxf(0.0, RiverCourse.bank_distance(game.player.position.x, game.player.position.z)))
	game.world.jungle.waterfall.present(delta, game.player.global_position, birds.daylight, birds.raining, outdoor)
	var tropical := smoothstep(JungleTerrain.SOUTH_START, JungleTerrain.SOUTH_START + 24.0, game.player.global_position.z)
	game.cycle.sky_effects.tropical_blend = move_toward(game.cycle.sky_effects.tropical_blend, tropical, delta * 0.35)
	game.weather_particles.sheltered = not outdoor
	_skid_timer = maxf(0.0, _skid_timer - delta)
	_scare_timer = maxf(0.0, _scare_timer - delta)
	if outdoor and game.combat.active and _scare_timer <= 0.0:
		birds.scatter(game.player.global_position, 9.0)
		_scare_timer = 0.6
	var velocity := game.player.velocity
	var feet := game.player.get_node("PlayerFootsteps") as PlayerFootsteps
	if outdoor and game.player.motor.immersion < 0.8 and feet.grounded() and _skid_timer <= 0.0:
		if game.player.motor.is_dashing or Vector2(velocity.x - _last_velocity.x, velocity.z - _last_velocity.z).length() > 0.6:
			particles.burst(game.player.global_position, velocity, 3, _wet(), 0.7)
			_skid_timer = 0.09
	_last_velocity = velocity

func _step(at: Vector3, _speed: float) -> void:
	if _outdoor() and game.player.motor.immersion < 0.8: particles.burst(at, game.player.velocity, 4 if _wet() else 2, _wet(), 0.45)

func _land(at: Vector3, impact: float) -> void:
	if not _outdoor() or game.player.motor.immersion >= 0.8: return
	particles.burst(at, Vector3.ZERO, 14, _wet(), clampf(impact / 12.0, 0.5, 1.8))
	birds.scatter(at, 5.0)
	game.camera.shake(minf(0.06, impact * 0.002))

func _dash() -> void:
	if not _outdoor() or game.player.motor.immersion >= 0.8: return
	particles.burst(game.player.global_position, game.player.velocity, 10, _wet())
	birds.scatter(game.player.global_position, 8.0)

func _command(command: PlayerCommand, _delta: float) -> void:
	if (command.attack_held or command.punch_held) and _scare_timer <= 0.0 and _outdoor():
		birds.scatter(game.player.global_position, 9.0)
		_scare_timer = 0.6

func _outdoor() -> bool:
	if not game.player.is_visible_in_tree(): return false
	if game.opening != null and game.opening.active: return false
	if game.factory_dungeon != null and game.factory_dungeon.actor_in_run(game.player): return false
	for building in game.world.interiors:
		var size: Vector2 = building.get_meta("map_footprint")
		var at := building.to_local(game.player.global_position)
		if absf(at.x) < size.x / 2 and absf(at.z) < size.y / 2 and at.y > -0.5: return false
	return true

func _wet() -> bool:
	return game.player.surface_speed < 0.9 or (birds.raining and not game.weather_particles.winter)

func _habitat(at: Vector3) -> bool:
	if absf(at.x) > 76.0 or absf(at.z) > 64.0: return false
	if MeadowVillage.BOUNDS.grow(3).has_point(Vector2(at.x, at.z)): return false
	if RiverCourse.bank_distance(at.x, at.z) < 1.0: return false
	if Vector2(at.x + 22, at.z + 22).length() < 8.0: return false
	var ground := game.world.ground_point(at.x, at.z)
	var ray := PhysicsRayQueryParameters3D.create(ground + Vector3.UP * 8.0, ground + Vector3.DOWN, 1)
	var hit := game.world.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty() and hit.position.y > ground.y + 0.4: return false
	return true
