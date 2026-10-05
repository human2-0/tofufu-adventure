class_name MeadowBirds
extends Node3D
## Bounded local wildlife: forage, relocate, then scatter from nearby actors.

const COUNT: int = 16
var ground_point: Callable
var habitat: Callable
var observers: Array[Node3D] = []
var birds: Array[MeadowBirdArt] = []
var flights: Array[BirdFlight] = []
var daylight: float = 1.0
var raining: bool = false
var _random := RandomNumberGenerator.new()
var _time: float = 0.0

func _ready() -> void:
	name = "MeadowBirds"
	_random.randomize()
	for i in COUNT:
		var flight := BirdFlight.new()
		var center := Vector3(-10, 0, -7) if i < 8 else Vector3(-26, 0, 18)
		flight.at = _destination(center, 2.0, 9.0)
		flight.resting = _random.randf_range(1.0, 9.0)
		flights.append(flight)
		var bird := MeadowBirdArt.new()
		add_child(bird)
		bird.build(i)
		bird.position = flight.at
		birds.append(bird)

func _process(delta: float) -> void:
	_time += delta
	for i in birds.size():
		var flight := flights[i]
		if not flight.airborne:
			for observer in observers:
				if not is_instance_valid(observer) or not observer.is_visible_in_tree(): continue
				var body := observer as CharacterBody3D
				var radius := 7.5 if body != null and body.velocity.length() > 9.0 else 3.2
				if flight.at.distance_squared_to(observer.global_position) < radius * radius:
					_flee(flight, observer.global_position)
					break
			if not flight.airborne and flight.resting <= 0.0:
				flight.launch(_destination(flight.at, 5, 18), _random.randf_range(2.4, 4.5), _random.randf_range(2.0, 5.0))
		var before := flight.at
		flight.step(delta)
		if not flight.airborne and flight.resting <= 0.0:
			flight.resting = _random.randf_range(4.0, 14.0) * (2.0 if raining or daylight < 0.2 else 1.0)
		birds[i].position = flight.at
		birds[i].present(_time, flight.airborne, (flight.at - before).normalized())

func scatter(at: Vector3, radius: float) -> void:
	for flight in flights:
		if not flight.airborne and flight.at.distance_squared_to(at) < radius * radius:
			_flee(flight, at)

func _flee(flight: BirdFlight, threat: Vector3) -> void:
	var away := Vector2(flight.at.x - threat.x, flight.at.z - threat.z).normalized()
	if away.is_zero_approx(): away = Vector2.RIGHT
	var center := flight.at + Vector3(away.x, 0, away.y) * 13.0
	center.x = clampf(center.x, -72.0, 72.0)
	center.z = clampf(center.z, -60.0, 60.0)
	flight.launch(_destination(center, 0, 4), _random.randf_range(1.8, 2.6), _random.randf_range(3.0, 5.0))

func _destination(center: Vector3, minimum: float, maximum: float) -> Vector3:
	for attempt in 24:
		var offset := Vector2.from_angle(_random.randf_range(0, TAU)) * _random.randf_range(minimum, maximum)
		var at := center + Vector3(offset.x, 0, offset.y)
		if not habitat.call(at): continue
		return ground_point.call(at.x, at.z, 0.035)
	return ground_point.call(-12.0, -8.0, 0.035)
