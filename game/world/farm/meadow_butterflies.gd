class_name MeadowButterflies
extends Node3D
## Cosmetic bounded flutter around the floral beds.

var _time: float = 0.0
var _bodies: Array[Node3D] = []
var _wings: Array[MeshInstance3D] = []

func _ready() -> void:
	for i in 10:
		var body := Node3D.new()
		add_child(body)
		_bodies.append(body)
		for side in [-1.0, 1.0]:
			var wing := MeadowGeometry.box(body, Vector3(side * 0.13, 0, 0), Vector3(0.22, 0.025, 0.28), [Color("e7a8d1"), Color("f1c36c"), Color("9dceeb")][i % 3])
			_wings.append(wing)

func _process(delta: float) -> void:
	_time += delta
	for i in _bodies.size():
		var t := _time * 0.35 + i * 1.7
		_bodies[i].position = Vector3(sin(t) * 4.7, 1.4 + sin(t * 2.1) * 0.5, cos(t * 0.8) * 3.4)
		_bodies[i].rotation.y = -t
		_wings[i * 2].rotation.z = sin(_time * 15 + i) * 0.9
		_wings[i * 2 + 1].rotation.z = -sin(_time * 15 + i) * 0.9
