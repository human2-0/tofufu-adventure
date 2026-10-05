class_name WeatherFlow
extends Node
## Composes the world clock, atmospheric view and explicit encounter modifiers.

var weather: WeatherCycle
var cycle: EnvironmentCycle
var encounters: SandboxEncounters
var view: WeatherView
var ground: RainGroundEffects
var wind: WindField
var grass: ShaderMaterial
var atmosphere: WeatherParticles
var focus: Node3D
var _winter: bool = false

func _ready() -> void:
	weather.changed.connect(_changed)
	_changed(weather.condition)

func _changed(condition: int) -> void:
	var rain := condition == WeatherCycle.Condition.RAIN
	var windy := condition == WeatherCycle.Condition.WINDY
	grass.set_shader_parameter("wetness", 1.0 if rain and not _winter else 0.0)
	encounters.set_rain(rain)
	cycle.cloud_cover = 1.0 if rain else (0.72 if windy else (0.6 if condition == WeatherCycle.Condition.OVERCAST else 0.0))
	ground.present(rain and not _winter)
	atmosphere.raining = rain
	atmosphere.winter = _winter
	atmosphere.snow_strength = 1.0 if rain else (0.65 if windy else (0.25 if condition == WeatherCycle.Condition.OVERCAST else 0.0))
	if _winter:
		view.present_winter(rain, windy, condition == WeatherCycle.Condition.OVERCAST)
	else:
		view.present(["CLEAR", "OVERCAST", "RAIN", "WINDY"][condition], rain, windy)

func _physics_process(delta: float) -> void:
	var cold := TerrainLocomotion.winter(focus.global_position)
	if cold != _winter:
		_winter = cold
		_changed(weather.condition)
	wind.step(weather.phase, weather.condition == WeatherCycle.Condition.WINDY, delta)
	grass.set_shader_parameter("wind_direction", wind.direction)
	grass.set_shader_parameter("wind_strength", wind.strength)
	atmosphere.present_wind(wind.direction, wind.strength)
