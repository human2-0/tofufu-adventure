class_name DofufuVFX
extends RefCounted
## Short-lived jade afterimages and gong shock rings; presentation only.

static func wave(parent: Node3D, at: Vector3, radius: float) -> void:
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.8
	mesh.outer_radius = 1.0
	mesh.rings = 24
	mesh.ring_segments = 8
	ring.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color("f8cc6a")
	ring.material_override = material
	parent.add_child(ring)
	ring.top_level = true
	ring.global_position = at + Vector3.UP * 0.12
	ring.scale = Vector3(0.2, 0.15, 0.2)
	var tween := ring.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(radius, 0.03, radius), 0.3)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.35)
	tween.chain().tween_callback(ring.queue_free)

static func echo(art: Sprite3D) -> void:
	var ghost := Sprite3D.new()
	ghost.texture = art.texture
	ghost.hframes = art.hframes
	ghost.vframes = art.vframes
	ghost.frame = art.frame
	ghost.offset = art.offset
	ghost.pixel_size = art.pixel_size
	ghost.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ghost.modulate = Color(0.3, 1.0, 0.75, 0.4)
	art.get_parent().add_child(ghost)
	ghost.top_level = true
	ghost.global_position = art.global_position
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ghost.queue_free)
