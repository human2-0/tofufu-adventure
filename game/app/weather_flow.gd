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

func _ready() -> void:
	weather.changed.connect(_changed)
	_changed(weather.condition)

func _changed(condition: int) -> void:
	var rain := condition == WeatherCycle.Condition.RAIN
	var windy := condition == WeatherCycle.Condition.WINDY
	encounters.set_rain(rain)
	cycle.cloud_cover = 1.0 if rain else (0.72 if windy else (0.6 if condition == WeatherCycle.Condition.OVERCAST else 0.0))
	ground.present(rain)
	view.present(["CLEAR", "OVERCAST", "RAIN", "WINDY"][condition], rain, windy)

func _physics_process(delta: float) -> void:
	wind.step(weather.phase, weather.condition == WeatherCycle.Condition.WINDY, delta)
	grass.set_shader_parameter("wind_direction", wind.direction)
	grass.set_shader_parameter("wind_strength", wind.strength)
	view.present_wind(wind.direction, wind.strength)
