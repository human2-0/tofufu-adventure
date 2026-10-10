class_name MeleeContact
extends RefCounted
## One short-lived star at the actual swept blade contact, without an emitter per foe.

static func flash(parent: Node, at: Vector3, heavy: bool) -> void:
	var flash := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_color = Color("fff0bc")
	material.no_depth_test = false
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	for ray in 4:
		var angle := ray * PI * 0.5 + 0.3
		var axis := Vector3(cos(angle), sin(angle), 0)
		var side := Vector3(-axis.y, axis.x, 0) * 0.045
		mesh.surface_add_vertex(side)
		mesh.surface_add_vertex(axis * (0.25 if heavy else 0.17))
		mesh.surface_add_vertex(-side)
	mesh.surface_end()
	flash.mesh = mesh
	parent.add_child(flash)
	flash.global_position = at
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector3.ZERO, 0.14).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(flash.queue_free)
