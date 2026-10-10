class_name CloudOrnaments
extends RefCounted
## Amphorae, laurel, offerings and a golden lyre suggest a gentle Olympian court.

static func build(parent: Node3D) -> void:
	for at in [Vector2(-17, 263), Vector2(1, 263), Vector2(-4, 338), Vector2(12, 338), Vector2(39, 283), Vector2(48, 284), Vector2(-59, 293), Vector2(53, 333)]:
		amphora(parent, CloudTerrain.point(at.x, at.y), at.x > 20)
	for at in [Vector2(-60, 305), Vector2(-46, 302), Vector2(15, 337), Vector2(53, 338)]:
		_laurel_tree(parent, CloudTerrain.point(at.x, at.y))
	var shrine := Node3D.new()
	shrine.name = "LyreOffering"
	shrine.position = CloudTerrain.point(5, 336)
	parent.add_child(shrine)
	CloudCraft.cylinder(shrine, Vector3.UP * 0.6, 0.65, 1.2, CloudMaterials.marble())
	CloudCraft.body(shrine, Vector3.ZERO, 0.65, 1.2)
	CloudCraft.ring(shrine, Vector3.UP * 1.23, 0.68, 0.05, CloudMaterials.gold())
	_lyre(shrine, Vector3(0, 1.25, 0))
	for at in [Vector2(-20, 264), Vector2(3, 265), Vector2(-8, 338), Vector2(17, 338)]:
		var root := Node3D.new()
		root.position = CloudTerrain.point(at.x, at.y)
		parent.add_child(root)
		CloudCraft.cylinder(root, Vector3.UP * 0.35, 0.45, 0.7, CloudMaterials.marble())
		CloudCraft.body(root, Vector3.ZERO, 0.45, 0.85)
		CloudCraft.cylinder(root, Vector3.UP * 0.76, 0.52, 0.12, CloudMaterials.gold())
		for i in 5:
			var fruit := SphereMesh.new()
			fruit.radius = 0.09
			fruit.height = 0.18
			fruit.radial_segments = 8
			fruit.rings = 4
			CloudCraft.view(root, fruit, Vector3(cos(i * 2.4) * 0.2, 0.92, sin(i * 2.4) * 0.2), CloudMaterials.gold())

static func amphora(parent: Node3D, at: Vector3, blue: bool = false) -> void:
	var root := Node3D.new()
	root.position = at
	parent.add_child(root)
	var profile: Array[Vector2] = [Vector2(0.18, 0), Vector2(0.18, 0.08), Vector2(0.4, 0.4), Vector2(0.42, 0.78), Vector2(0.25, 1.03), Vector2(0.15, 1.1), Vector2(0.15, 1.3), Vector2(0.23, 1.33)]
	CloudCraft.lathe(root, Vector3.ZERO, profile, CloudMaterials.marble(Color("abc4db") if blue else Color("ebd5a9")))
	CloudCraft.body(root, Vector3.ZERO, 0.4, 1.33)
	for y in [0.16, 0.85, 1.31]:
		CloudCraft.ring(root, Vector3.UP * y, 0.25 if y > 1 else 0.4, 0.035, CloudMaterials.gold())
	for side in [-1, 1]:
		var handle := CloudCraft.ring(root, Vector3(side * 0.3, 1.03, 0), 0.2, 0.04, CloudMaterials.gold())
		handle.rotation.x = PI / 2

static func wreath(parent: Node3D, at: Vector3, radius: float, vertical: bool = false) -> void:
	var root := Node3D.new()
	root.position = at
	if vertical: root.rotation.x = PI / 2
	parent.add_child(root)
	CloudCraft.ring(root, Vector3.ZERO, radius, 0.025, CloudMaterials.gold())
	var leaf := SphereMesh.new()
	leaf.radius = 1
	leaf.height = 2
	leaf.radial_segments = 8
	leaf.rings = 4
	for i in 18:
		var angle: float = i * TAU / 18
		var view := CloudCraft.view(root, leaf, Vector3(cos(angle), 0, sin(angle)) * radius, CloudMaterials.gold())
		view.scale = Vector3(radius * 0.26, 0.035, radius * 0.11)
		view.rotation.y = -angle + 0.65

static func _lyre(parent: Node3D, at: Vector3) -> void:
	CloudCraft.box(parent, at + Vector3.UP * 0.12, Vector3(0.85, 0.22, 0.3), CloudMaterials.gold())
	for side in [-1, 1]:
		var arm := CloudCraft.cylinder(parent, at + Vector3(side * 0.43, 0.68, 0), 0.07, 1.2, CloudMaterials.gold())
		arm.rotation.z = -side * 0.16
	CloudCraft.box(parent, at + Vector3.UP * 1.22, Vector3(1.08, 0.13, 0.16), CloudMaterials.gold())
	for i in 7:
		CloudCraft.cylinder(parent, at + Vector3((i - 3) * 0.095, 0.68, 0), 0.009, 0.94, CloudMaterials.gold())

static func _laurel_tree(parent: Node3D, at: Vector3) -> void:
	CloudCraft.cylinder(parent, at + Vector3.UP * 1.3, 0.12, 2.6, CloudMaterials.marble(Color("a7957c")), 0.06)
	CloudCraft.body(parent, at, 0.12, 2.6)
	var leaf := SphereMesh.new()
	leaf.radius = 1
	leaf.height = 2
	leaf.radial_segments = 8
	leaf.rings = 4
	var material := MeadowGeometry.material(Color("93b5a0"))
	material.next_pass = null
	for i in 16:
		var angle: float = i * 2.4
		var view := CloudCraft.view(parent, leaf, at + Vector3(cos(angle) * 0.8, 2.2 + i % 4 * 0.24, sin(angle) * 0.8), material)
		view.scale = Vector3(0.68, 0.16, 0.3)
		view.rotation = Vector3(0.3, -angle, 0.2)
