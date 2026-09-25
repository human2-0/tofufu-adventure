class_name WeatherCycle
extends Node
## Authority advances this clock; replicas only receive a normalized phase.

signal changed(condition: int)
enum Condition { CLEAR, OVERCAST, RAIN, WINDY }
@export var cycle_seconds: float = 180.0
var phase: float = 0.0
var condition: Condition = Condition.CLEAR

func _physics_process(delta: float) -> void:
	set_phase(fposmod(phase + delta / maxf(1.0, cycle_seconds), 1.0))

func set_phase(value: float) -> void:
	phase = clampf(value, 0.0, 1.0)
	var next := Condition.CLEAR
	if phase >= 1.0 / 3.0 and phase < 2.0 / 3.0:
		next = Condition.RAIN
	elif phase >= 0.08 and phase < 0.22:
		next = Condition.WINDY
	elif phase >= 0.25 and phase < 0.75:
		next = Condition.OVERCAST
	if condition != next:
		condition = next
		changed.emit(condition)
