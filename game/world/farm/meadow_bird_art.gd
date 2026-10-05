class_name MeadowBirdArt
extends Node3D
## Small rounded songbirds with articulated wings and a pecking head.

var left: Node3D
var right: Node3D
var head: Node3D
var _phase: float = 0.0

func build(index: int) -> void:
	_phase = index * 2.39
	var colors := [Color("759ab4"), Color("bc896c"), Color("9bba79"), Color("d1b47a")]
	var coat: Color = colors[index % colors.size()]
	_oval(self, Vector3(0, 0.18, 0), Vector3(0.28, 0.28, 0.43), coat)
	_oval(self, Vector3(0, 0.16, -0.1), Vector3(0.22, 0.21, 0.23), Color("f7e8be"))
	head = Node3D.new()
	head.position = Vector3(0, 0.3, -0.16)
	add_child(head)
	_oval(head, Vector3.ZERO, Vector3.ONE * 0.25, coat)
	_oval(head, Vector3(0, -0.025, -0.15), Vector3(0.08, 0.06, 0.15), Color("ecb54e"))
	for side in [-1.0, 1.0]:
		_oval(head, Vector3(side * 0.1, 0.02, -0.075), Vector3.ONE * 0.04, Color("243448"))
		_oval(self, Vector3(side * 0.075, 0.025, -0.02), Vector3(0.04, 0.04, 0.12), Color("9d7346"))
	left = _wing(-1.0, coat.darkened(0.18))
	right = _wing(1.0, coat.darkened(0.18))
	_oval(self, Vector3(0, 0.21, 0.25), Vector3(0.13, 0.075, 0.3), coat.darkened(0.22))

func present(time: float, flying: bool, direction: Vector3) -> void:
	if Vector2(direction.x, direction.z).length_squared() > 0.01:
		rotation.y = atan2(-direction.x, -direction.z)
	var flap := sin(time * 24.0 + _phase) * 0.85 if flying else 1.25
	left.rotation.z = flap
	right.rotation.z = -flap
	head.rotation.x = maxf(0.0, sin(time * 3.4 + _phase)) * 0.7 if not flying else 0.0
	rotation.x = -0.12 if flying else 0.0

func _wing(side: float, color: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(side * 0.1, 0.23, 0)
	add_child(pivot)
	_oval(pivot, Vector3(side * 0.2, 0, 0.06), Vector3(0.46, 0.05, 0.24), color)
	return pivot

func _oval(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.material = MeadowGeometry.material(color)
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	part.scale = size
	parent.add_child(part)
