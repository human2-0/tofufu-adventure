class_name AppleTreeVisuals
extends RefCounted
## Procedural mesh composition for the meadow apple tree.

static func build(parent: Node3D) -> Array[Node3D]:
	NaturalTreeVisuals.build(parent, true)
	return _build_apples(parent)

static func _build_apples(parent: Node3D) -> Array[Node3D]:
	var apples: Array[Node3D] = []
	for pos in NaturalTreeVisuals.FRUIT_ANCHORS:
		var apple := create_apple_model()
		apple.position = pos
		parent.add_child(apple)
		apples.append(apple)
	return apples

static func create_apple_model() -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.13
	sphere.height = 0.24
	sphere.radial_segments = 10
	sphere.rings = 5
	body.mesh = sphere
	body.material_override = MeadowGeometry.material(Color("dc2626"))
	body.position.y = 0.08
	root.add_child(body)
	var stem := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.015
	cylinder.bottom_radius = 0.015
	cylinder.height = 0.07
	stem.mesh = cylinder
	stem.material_override = MeadowGeometry.material(Color("4a3018"))
	stem.position = Vector3(0, 0.19, 0)
	stem.rotation.z = 0.2
	root.add_child(stem)
	var leaf := MeshInstance3D.new()
	var leaf_sphere := SphereMesh.new()
	leaf_sphere.radius = 0.03
	leaf_sphere.height = 0.07
	leaf.mesh = leaf_sphere
	leaf.material_override = MeadowGeometry.material(Color("4ca62b"))
	leaf.position = Vector3(0.04, 0.20, 0)
	leaf.rotation.z = 0.85
	leaf.scale = Vector3(0.6, 1.0, 0.3)
	root.add_child(leaf)
	return root
