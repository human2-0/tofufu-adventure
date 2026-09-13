class_name MeadowGeometry
extends RefCounted
## Small construction helpers for authored 3D environment pieces.

static func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.next_pass = preload("res://game/world/ink_outline.tres")
	result.roughness = 1.0
	result.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	result.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	result.rim_enabled = true
	result.rim = 0.18
	result.rim_tint = 0.65
	return result

static func box(parent: Node3D, at: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material(color)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		parent.add_child(body)
		body.position = at
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		shape.shape = bounds
		body.add_child(shape)
	return instance

static func rock(parent: Node3D, at: Vector3, size: Vector3, color: Color, solid: bool = false) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	mesh.material = material(color)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.scale = size
	parent.add_child(instance)
	if solid:
		instance.create_convex_collision()

static func signpost(parent: Node3D, at: Vector3, title: String) -> void:
	box(parent, at + Vector3.UP * 0.65, Vector3(0.12, 1.3, 0.12), Color("675442"))
	box(parent, at + Vector3.UP * 1.3, Vector3(2.6, 0.65, 0.15), Color("403f36"))
	var label := Label3D.new()
	label.text = title
	label.font_size = 30
	label.pixel_size = 0.007
	label.position = at + Vector3(0, 1.3, 0.09)
	label.modulate = Color("f9e6af")
	parent.add_child(label)
