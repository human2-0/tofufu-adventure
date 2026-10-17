class_name GraphicsEffects
extends Node
## Explicit local presentation wiring, independent of weather simulation and saves.

var preferences := GraphicsPreferences.new()
var game: AdventureGame
var weather: WeatherFlow
var life: WorldLife

func setup(owner_game: AdventureGame, flow: WeatherFlow, world_life: WorldLife) -> void:
	game = owner_game
	weather = flow
	life = world_life

func configure(settings: GraphicsPreferences) -> void:
	if preferences.changed.is_connected(apply): preferences.changed.disconnect(apply)
	preferences = settings
	preferences.changed.connect(apply)
	apply()

func _exit_tree() -> void:
	if preferences.changed.is_connected(apply): preferences.changed.disconnect(apply)

func apply() -> void:
	if not game.is_inside_tree() or game.is_queued_for_deletion(): return
	var effects := game.weather_particles
	effects.rain_enabled = preferences.enabled("rain")
	effects.snow_enabled = preferences.enabled("snow")
	effects.wind_enabled = preferences.enabled("wind")
	weather.wind_effects = preferences.enabled("wind")
	game.cycle.sky_effects.lightning_enabled = preferences.enabled("lightning")
	game.cycle.sky_effects.thunder_enabled = preferences.enabled("thunder")
	game.cycle.fog_enabled = preferences.enabled("fog")
	game.cycle.motes_enabled = preferences.enabled("motes")
	life.audio.weather_enabled = preferences.enabled("audio")
	life.particles.visible = preferences.enabled("motes")
	life.particles.set_process(preferences.enabled("motes"))
	var puddles := game.world.rain_effects
	puddles.set_effects_enabled(preferences.enabled("puddles"))
	weather._physics_process(0.0)
	effects._process(0.0)
	game.cycle._process(0.0)
