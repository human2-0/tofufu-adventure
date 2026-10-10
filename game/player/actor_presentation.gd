class_name ActorPresentation
extends Node
## Interpolates the existing sprite; the capsule stays on authoritative physics ticks.

var actor: Player
var _previous: Vector3
var _current: Vector3
var _origin: Vector3
var ground_position: Vector3

func _ready() -> void:
	process_physics_priority = 200
	process_priority = -15 # After the camera, before replica hands and weapon views.
	_origin = actor.visuals.position
	reset()
	actor.relocated.connect(reset)
	if DisplayServer.get_name() == "headless":
		set_process(false)

func reset() -> void:
	_previous = actor.global_position
	_current = _previous
	ground_position = _current
	actor.visuals.position = _origin

func _physics_process(_delta: float) -> void:
	_previous = _current
	_current = actor.global_position
	ground_position = _current
	if _previous.distance_squared_to(_current) > 25.0: _previous = _current

func present(fraction: float) -> void:
	var at := _previous.lerp(_current, clampf(fraction, 0.0, 1.0))
	ground_position = at
	actor.visuals.position = _origin + actor.global_basis.inverse() * (at - actor.global_position)
	actor.visuals._present_hand()

func _process(_delta: float) -> void:
	present(Engine.get_physics_interpolation_fraction())
