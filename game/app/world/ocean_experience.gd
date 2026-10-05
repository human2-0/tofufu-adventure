class_name OceanExperience
extends Node
## Local ocean atmosphere and breathing for visible actors, independent of authority.

var game: AdventureGame
var bubbles: OceanBubbles
var drift: OceanDrift
var surf: OceanSound
var _breaths: Dictionary[Player, float] = {}
var _underwater: Environment
var _previous: Environment
var _blend: float = 0.0
var _claimed: bool = false
var _surface: ShaderMaterial

func _ready() -> void:
	name = "OceanExperience"
	_surface = (game.world.ocean.get_node("AquaDepthsSurface") as MeshInstance3D).material_override as ShaderMaterial
	bubbles = OceanBubbles.new()
	game.world.add_child(bubbles)
	drift = OceanDrift.new()
	game.world.add_child(drift)
	surf = OceanSound.new()
	add_child(surf)
	_underwater = game.cycle.world_environment.environment.duplicate()

func _process(delta: float) -> void:
	var at := game.player.global_position
	game.world.ocean.wildlife.focus = at
	var depth := TerrainLocomotion.immersion(at + Vector3.UP * 0.6, game.world)
	if not game.player.is_visible_in_tree() or game.player.transport_active: depth = 0.0
	if game.opening != null and game.opening.active: depth = 0.0
	_blend = move_toward(_blend, depth, delta * 2.0)
	_atmosphere()
	_surface.set_shader_parameter("dive_view", _blend)
	drift.focus = at + Vector3.UP
	drift.active = _blend > 0.2
	surf.present(at, _blend, game.player.is_visible_in_tree() and (game.opening == null or not game.opening.active))
	var actors: Array[Player] = [game.player]
	for peer in game.player.placement_peers:
		if is_instance_valid(peer) and peer is Player and peer not in actors: actors.append(peer)
	for actor in _breaths.keys():
		if not is_instance_valid(actor) or actor not in actors: _breaths.erase(actor)
	for actor in actors:
		var feet := actor.get_node("PlayerFootsteps") as PlayerFootsteps
		feet.water_muffle = TerrainLocomotion.immersion(actor.global_position, game.world)
		if not actor.is_visible_in_tree() or TerrainLocomotion.immersion(actor.global_position, game.world) <= 0.0:
			_breaths.erase(actor)
			continue
		var wait := float(_breaths.get(actor, 0.0)) - delta
		if wait <= 0.0:
			bubbles.breathe(actor.global_position, Vector2(actor.velocity.x, actor.velocity.z).normalized())
			wait = 1.3
		_breaths[actor] = wait

func _atmosphere() -> void:
	var camera := game.camera
	if _blend <= 0.0:
		if _claimed:
			camera.environment = _previous
			_claimed = false
		return
	if not _claimed:
		_previous = camera.environment
		_claimed = true
	var base := game.cycle.world_environment.environment
	_underwater.sky = base.sky
	_underwater.ambient_light_color = base.ambient_light_color.lerp(Color("77ced7"), _blend * 0.65)
	_underwater.ambient_light_energy = base.ambient_light_energy
	_underwater.fog_enabled = true
	_underwater.fog_light_color = base.fog_light_color.lerp(Color("207d91"), _blend)
	_underwater.fog_density = lerpf(base.fog_density, 0.038, _blend)
	_underwater.fog_sky_affect = lerpf(base.fog_sky_affect, 0.9, _blend)
	camera.environment = _underwater

func _exit_tree() -> void:
	if _claimed and is_instance_valid(game.camera): game.camera.environment = _previous
	if is_instance_valid(bubbles): bubbles.queue_free()
	if is_instance_valid(drift): drift.queue_free()
