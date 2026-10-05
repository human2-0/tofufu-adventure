class_name VolcanicVisit
extends Node
## Local castle cutaways/greetings; existing authority health path owns lava burns.

var game: AdventureGame
var burn_clock: float = 0.0

func _ready() -> void:
	name = "VolcanicVisit"

func _process(_delta: float) -> void:
	game.world.volcanic.atmosphere.active = DisplayServer.get_name() != "headless" and Vector2(game.camera.global_position.x, game.camera.global_position.z).distance_to(VolcanicTerrain.CENTER) < 470.0
	var water := game.world.volcanic.ocean.material_override as ShaderMaterial
	water.set_shader_parameter("dive_view", TerrainLocomotion.immersion(game.camera.global_position, game.world))
	var castle := game.world.volcanic.castle
	castle.present(game.player.global_position, not game.shooting_view.shoulder)
	castle.king.greeting.visible = game.hud.visible and not game.player.transport_active and game.player.global_position.distance_to(castle.king.global_position) < 7.0

func _physics_process(delta: float) -> void:
	burn_clock += delta
	if burn_clock < 0.75: return
	burn_clock = fmod(burn_clock, 0.75)
	var roster := game.map.roster
	if is_instance_valid(roster):
		if not roster.authority: return
		for member: CoopActor in roster.party.values():
			if not member.spectating: _burn(member.actor, member.health)
	else:
		_burn(game.player, game.health)

func _burn(actor: Player, health: Damageable) -> void:
	if not actor.is_visible_in_tree() or actor.transport_active or health.current <= 0: return
	if VolcanicLava.molten(game.world.to_local(actor.global_position)):
		health.damage(12.0)
