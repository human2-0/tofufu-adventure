class_name WeatherFlow
extends Node
## Composes the world clock, atmospheric view and explicit encounter modifiers.

var weather: WeatherCycle
var cycle: EnvironmentCycle
var encounters: SandboxEncounters
var view: WeatherView

func _ready() -> void:
	weather.changed.connect(_changed)
	_changed(weather.condition)

func _changed(condition: int) -> void:
	var rain := condition == WeatherCycle.Condition.RAIN
	encounters.set_rain(rain)
	cycle.cloud_cover = 1.0 if rain else (0.6 if condition == WeatherCycle.Condition.OVERCAST else 0.0)
	view.present(["CLEAR", "OVERCAST", "RAIN"][condition], rain)
