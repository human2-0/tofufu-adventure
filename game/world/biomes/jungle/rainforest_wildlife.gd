class_name RainforestWildlife
extends Node3D
## Small local population: perch/flight cycles, hovering, wandering and proximity response.

const BIRDS: int = 6
const BUTTERFLIES: int = 12
const FROGS: int = 5
var active: bool = false
var daylight: float = 1.0
var raining: bool = false
var observer := Vector3(1000, 0, 0)
var birds: Array[Node3D] = []
var butterflies: Array[Node3D] = []
var frogs: Array[Node3D] = []
var fish: Array[MeshInstance3D] = []
var elapsed: float = 0.0
var _alarm: Array[float] = []
var _retreat: Array[float] = []

func _ready() -> void:
	for i in BIRDS:
		var bird := RainforestArt.bird(i < 3)
		bird.scale = Vector3.ONE * (1.6 if i < 3 else 0.85)
		add_child(bird)
		birds.append(bird)
		_alarm.append(0.0)
	for i in BUTTERFLIES:
		var butterfly := RainforestArt.butterfly()
		butterfly.scale *= 1.6
		add_child(butterfly)
		butterflies.append(butterfly)
	for i in FROGS:
		var frog := RainforestArt.frog()
		frog.scale *= 1.8
		frog.position = Vector3(-6.5 - i * 1.2, 0.1, 4.5 - i * 1.7)
		add_child(frog)
		frogs.append(frog)
		_retreat.append(0.0)
	var mesh := RiverFishArt.build()
	for i in 8:
		var swimmer := MeshInstance3D.new()
		swimmer.mesh = mesh
		add_child(swimmer)
		fish.append(swimmer)

func _process(delta: float) -> void:
	visible = active
	if not active: return
	elapsed += delta
	for i in BIRDS:
		var at := bird_position(i, elapsed)
		var heading := bird_position(i, elapsed + 0.05) - at
		var scared := Vector2(at.x - observer.x, at.z - observer.z).length_squared() < 36.0
		_alarm[i] = move_toward(_alarm[i], 1.0 if scared else 0.0, delta * 1.3)
		var age := fposmod(elapsed + i * 5.7, 23.0)
		var flying := (i >= 3 or age < 9.0 or _alarm[i] > 0.1) and not raining and daylight > 0.15
		at.y += _alarm[i] * 2.5
		birds[i].position = at
		birds[i].rotation.y = atan2(-heading.x, -heading.z) if Vector2(heading.x, heading.z).length_squared() > 0.0001 else sin(elapsed * 0.35 + i) * 0.25
		var flap := sin(elapsed * (14.0 if i < 3 else 65.0) + i) * (0.65 if i < 3 else 0.9) if flying else 0.85
		birds[i].get_node("LeftWing").rotation.z = flap
		birds[i].get_node("RightWing").rotation.z = -flap
	for i in BUTTERFLIES:
		butterflies[i].visible = daylight > 0.18 and not raining
		var angle := elapsed * 0.21 + i * 2.39996
		butterflies[i].position = Vector3(cos(angle) * (13 + i % 3), 1.5 + sin(elapsed * 1.6 + i) * 0.5, sin(angle) * 8 - 2)
		butterflies[i].rotation.y = PI - angle
		var flap := sin(elapsed * 12 + i) * 0.85
		butterflies[i].get_node("LeftWing").rotation.z = flap
		butterflies[i].get_node("RightWing").rotation.z = -flap
	for i in FROGS:
		var age := fposmod(elapsed + i * 3.3, 14.0)
		var home := Vector3(-6.5 - i * 1.2, 0.1, 4.5 - i * 1.7)
		var scared := home.distance_squared_to(observer) < 9.0
		_retreat[i] = move_toward(_retreat[i], 1.0 if scared else 0.0, delta * 1.8)
		frogs[i].position = home + Vector3(-_retreat[i] * 0.4, sin(_retreat[i] * PI) * 0.4, _retreat[i] * 0.3)
		frogs[i].position.y += sin(age * PI / 0.8) * 0.25 if age < 0.8 else 0.0
	for i in fish.size():
		var angle := elapsed * 0.24 + i * TAU / 8.0
		fish[i].position = Vector3(cos(angle) * (4.5 + i * 0.4), -0.17, sin(angle) * 3.4 - 1.8)
		fish[i].rotation.y = PI - angle

func bird_position(index: int, time: float) -> Vector3:
	var side := -1.0 if index % 2 else 1.0
	var perch := Vector3(side * (10.0 + index), 5.5 + index * 0.55, 4.0 + index * 0.3)
	if raining or daylight < 0.15: return perch
	var age := fposmod(time + index * 5.7, 23.0)
	if index < 3 and age >= 9.0: return perch
	if index >= 3:
		return Vector3(side * (13.0 + sin(time * 0.55 + index) * 1.5), 1.7 + sin(time * 2.0 + index) * 0.15, -4.5 + cos(time * 0.45 + index) * 4.0)
	var progress := age / 9.0
	return perch + Vector3(sin(progress * TAU) * 8.0, sin(progress * PI) * 3.0, -sin(progress * PI) * 12.0)
