class_name ParrotArt
extends Node3D
## Scarlet macaw with a hooked beak, rainbow flight feathers and long tail.

var wings: Array[Node3D] = []
var _time: float = 0.0
var airborne: bool = false
var heading := Vector3.FORWARD

func _ready() -> void:
	_oval(self, Vector3(0, 0.65, 0), Vector3(0.95, 1.25, 1.55), Color("e64b47"))
	_oval(self, Vector3(0, 0.55, -0.42), Vector3(0.7, 0.85, 0.6), Color("ffb85e"))
	_oval(self, Vector3(0, 1.28, -0.62), Vector3.ONE * 0.85, Color("f75b4e"))
	_oval(self, Vector3(0, 1.12, -1.03), Vector3(0.35, 0.5, 0.5), Color("edcf8d"))
	_oval(self, Vector3(0, 0.94, -1.18), Vector3(0.25, 0.32, 0.28), Color("334b51"))
	for side in [-1.0, 1.0]:
		_oval(self, Vector3(side * 0.37, 1.29, -0.76), Vector3(0.08, 0.38, 0.38), Color("fff3dd"))
		_oval(self, Vector3(side * 0.42, 1.32, -0.81), Vector3.ONE * 0.10, Color("263f47"))
		_oval(self, Vector3(side * 0.26, 0.07, -0.1), Vector3(0.17, 0.16, 0.5), Color("4b6267"))
		var wing := Node3D.new()
		wing.position = Vector3(side * 0.32, 0.93, 0.04)
		add_child(wing)
		wings.append(wing)
		_oval(wing, Vector3(side * 0.55, 0, 0), Vector3(1.25, 0.22, 0.85), Color("f1cb45"))
		for feather in 5:
			_oval(wing, Vector3(side * (1.0 + feather * 0.18), -0.02, 0.12 + feather * 0.14), Vector3(0.85, 0.14, 0.34), Color("31b997") if feather < 2 else Color("3588de"))
	for feather in 3:
		var tail := _oval(self, Vector3((feather - 1) * 0.19, 0.38, 1.32), Vector3(0.23, 0.16, 1.7), Color("268bc8") if feather != 1 else Color("ef6454"))
		tail.rotation.x = 0.28
	# Saddle cushions provide a clear place for billboard Fufu to sit.
	_oval(self, Vector3(0, 1.02, 0.22), Vector3(0.8, 0.16, 0.7), Color("674c72"))

func _process(delta: float) -> void:
	_time += delta
	if Vector2(heading.x, heading.z).length_squared() > 0.01:
		rotation.y = atan2(-heading.x, -heading.z)
	var flap := sin(_time * 16.0) * 0.6 if airborne else 1.12
	wings[0].rotation.z = flap
	wings[1].rotation.z = -flap

func _oval(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	mesh.material = MeadowGeometry.material(color)
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	part.scale = size
	parent.add_child(part)
	return part
