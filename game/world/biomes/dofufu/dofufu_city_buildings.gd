class_name DofufuCityBuildings
extends RefCounted
## Chinese-inspired curved tiled roofs, red timber, lanterns and generous street gaps.

static func build(parent: Node3D, terrain: DofufuTerrain) -> void:
	for z in [-52, 52]:
		for span in [Vector2(-883, 66), Vector2(-951, 34)] if z == -52 else [Vector2(-909, 118)]:
			_wall(parent, terrain.point(span.x, z), Vector3(span.y, 4, 1.4))
	_wall(parent, terrain.point(-968, 0), Vector3(1.4, 4, 104))
	for z in [-31, 31]: _wall(parent, terrain.point(-850, z), Vector3(1.4, 4, 42))
	_gate(parent, terrain.point(-850, 0), true)
	_gate(parent, terrain.point(-925, -52), false)
	for x in [-864, -886, -912, -945]:
		for z in [-41, 41]: _house(parent, terrain.point(x, z), Vector3(12, 4, 9), false)
	_house(parent, terrain.point(-952, 0), Vector3(20, 7, 24), true)
	_house(parent, terrain.point(-914, 34), Vector3(16, 4, 9), false)
	for x in [-859, -884, -912, -937]:
		for z in [-17, 17]: _lantern(parent, terrain.point(x, z))
	for z in [-24, 24]:
		MeadowGeometry.box(parent, terrain.point(-880, z, 0.7), Vector3(5, 1.4, 2), Color("713f32"), true)
		for i in 5:
			MeadowGeometry.box(parent, terrain.point(-882 + i, z, 1.5), Vector3(0.6, 0.3, 0.6), Color("f5e4b8"))
	# Central contest court: open floor, four posts and boundary paving.
	for z in [-13, 13]:
		MeadowGeometry.box(parent, terrain.point(-914, z, 0.025), Vector3(30, 0.05, 0.4), Color("aa7950"))
	for x in [-929, -899]:
		MeadowGeometry.box(parent, terrain.point(x, 0, 0.025), Vector3(0.4, 0.05, 26), Color("aa7950"))

static func _wall(parent: Node3D, at: Vector3, size: Vector3) -> void:
	MeadowGeometry.box(parent, at + Vector3.UP * 2, size, Color("787c72"), true)
	MeadowGeometry.box(parent, at + Vector3.UP * 4.2, Vector3(size.x + 0.4, 0.4, size.z + 0.4), Color("353e40"))

static func _gate(parent: Node3D, at: Vector3, east: bool) -> void:
	var gate := Node3D.new()
	gate.position = at
	gate.rotation.y = PI / 2 if east else 0
	parent.add_child(gate)
	for side in [-1, 1]:
		MeadowGeometry.box(gate, Vector3(side * 9, 3.4, 0), Vector3(1.2, 6.8, 1.2), Color("933d32"), true)
		_lantern(gate, Vector3(side * 6, 1.3, 0))
	MeadowGeometry.box(gate, Vector3(0, 6.4, 0), Vector3(20, 1.0, 2.5), Color("793c32"))
	_roof(gate, Vector3(0, 7.3, 0), Vector3(23, 1, 5))

static func _house(parent: Node3D, at: Vector3, size: Vector3, palace: bool) -> void:
	var house := Node3D.new()
	house.position = at
	parent.add_child(house)
	MeadowGeometry.box(house, Vector3(0, size.y / 2, 0), size, Color("dec69c"), true)
	for side in [-1, 1]:
		for end in [-1, 1]:
			MeadowGeometry.box(house, Vector3(side * size.x * 0.48, size.y / 2, end * size.z * 0.51), Vector3(0.4, size.y, 0.4), Color("923d31"))
	for side in [-1, 1]:
		MeadowGeometry.box(house, Vector3(0, 1.6, side * (size.z / 2 + 0.03)), Vector3(2.2, 3.2, 0.08), Color("573e31"))
	for side in [-1, 1]:
		for x in [-size.x * 0.3, size.x * 0.3]:
			_window(house, Vector3(x, size.y * 0.55, side * (size.z * 0.5 + 0.08)))
		MeadowGeometry.box(house, Vector3(0, size.y * 0.9, side * size.z * 0.52), Vector3(size.x, 0.25, 0.2), Color("9b4831"))
	_roof(house, Vector3(0, size.y, 0), Vector3(size.x + 3, 1, size.z + 3))
	if palace: _roof(house, Vector3(0, size.y + 2, 0), Vector3(size.x * 0.7, 1, size.z * 0.7))

static func _roof(parent: Node3D, at: Vector3, size: Vector3) -> void:
	# Repeated sloped tile bands culminate in raised eaves and a golden ridge.
	for side in [-1, 1]:
		for band in 5:
			var z: float = side * size.z * band / 10.0
			var y: float = 1.5 - band * 0.24 + (0.28 if band == 4 else 0)
			var tile := MeadowGeometry.box(parent, at + Vector3(0, y, z), Vector3(size.x + band * 0.15, 0.32, size.z / 9), Color("3c5554"))
			tile.rotation.x = side * 0.3 if band < 4 else -side * 0.25
	for x in range(-int(size.x / 2), int(size.x / 2), 1):
		for side in [-1, 1]:
			var rib := MeadowGeometry.box(parent, at + Vector3(x, 1.14, side * size.z * 0.22), Vector3(0.06, 0.07, size.z * 0.48), Color("5c7370"))
			rib.rotation.x = side * 0.3
	MeadowGeometry.box(parent, at + Vector3.UP * 1.72, Vector3(size.x, 0.18, 0.2), Color("c5a15c"))

static func _lantern(parent: Node3D, at: Vector3) -> void:
	MeadowGeometry.box(parent, at + Vector3.UP * 1.8, Vector3(0.14, 3.6, 0.14), Color("554633"), true)
	MeadowGeometry.box(parent, at + Vector3(0.5, 3.6, 0), Vector3(1.1, 0.13, 0.13), Color("554633"))
	var lamp := MeadowGeometry.box(parent, at + Vector3(0.9, 3.05, 0), Vector3(0.6, 0.85, 0.6), Color("d45136"))
	var material := lamp.mesh.material as StandardMaterial3D
	material.emission_enabled = true
	material.emission = Color("9e3620")
	material.emission_energy_multiplier = 0.45
	MeadowGeometry.box(parent, at + Vector3(0.9, 2.57, 0), Vector3(0.25, 0.14, 0.25), Color("efc66c"))

static func _window(parent: Node3D, at: Vector3) -> void:
	MeadowGeometry.box(parent, at, Vector3(2.6, 1.9, 0.07), Color("6d4330"))
	MeadowGeometry.box(parent, at + Vector3(0, 0, 0.05 * signf(at.z)), Vector3(2.3, 1.6, 0.04), Color("d4b16c"))
	for i in 5:
		MeadowGeometry.box(parent, at + Vector3(-1 + i * 0.5, 0, 0.08 * signf(at.z)), Vector3(0.08, 1.9, 0.04), Color("633e2b"))
	for y in [-0.55, 0.0, 0.55]:
		MeadowGeometry.box(parent, at + Vector3(0, y, 0.09 * signf(at.z)), Vector3(2.6, 0.08, 0.04), Color("633e2b"))
