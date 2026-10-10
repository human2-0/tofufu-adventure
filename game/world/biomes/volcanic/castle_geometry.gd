class_name CastleGeometry
extends RefCounted
## Presentation and static bodies are siblings, so cutaways never change collision.

static func solid(parent: Node3D, at: Vector3, size: Vector3, color: Color, slope: float = 0.0) -> MeshInstance3D:
	var visual := MeadowGeometry.box(parent, at, size, color)
	visual.material_override = CastleMaterials.stone(color, size.y <= 0.6)
	visual.rotation.x = slope
	SolidOcclusion.box(visual)
	var body := StaticBody3D.new()
	body.transform = visual.transform
	body.collision_layer = 1
	body.collision_mask = 0
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	parent.add_child(body)
	return visual

static func title(parent: Node3D, at: Vector3, text: String, size: int = 34) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.double_sided = false
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.position = at
	label.modulate = Color("ffe0a5")
	label.font_size = size
	label.pixel_size = 0.017
	parent.add_child(label)
	return label

static func ramp(parent: Node3D, start: Vector3, finish: Vector3, width: float) -> void:
	var delta := finish - start
	var slope := -atan(delta.y / delta.z)
	var normal := Basis(Vector3.RIGHT, slope) * Vector3.UP
	var center := (start + finish) * 0.5 - normal * 0.15
	var size := Vector3(width, 0.3, delta.length())
	var visual := MeadowGeometry.box(parent, center, size, Color("987762"))
	visual.material_override = CastleMaterials.stone(Color("987762"), true)
	visual.rotation.x = slope
	SolidOcclusion.box(visual)
	var body := StaticBody3D.new()
	body.transform = visual.transform
	body.collision_layer = 1
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collider.shape = box
	body.add_child(collider)
	parent.add_child(body)
	# Visible transverse treads sit just above the continuous physical ramp.
	for i in 40:
		var at := start.lerp(finish, (i + 0.5) / 40.0)
		var tread := MeadowGeometry.box(parent, at, Vector3(width, 0.04, 0.18), Color("c0a084"))
		tread.material_override = CastleMaterials.stone(Color("c0a084"), true)
		tread.rotation.x = visual.rotation.x
	for side in [-1.0, 1.0]:
		solid(parent, center + Vector3(side * (width * 0.5 + 0.2), 1.5, 0), Vector3(0.35, 3, delta.length()), Color("453740"), visual.rotation.x)
