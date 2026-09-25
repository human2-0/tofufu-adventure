class_name OutfitEquipEffect
extends RefCounted
## Short world-space transformation flash; the old pose fades behind the new one.

static func spawn(source: Sprite3D, tint: Color) -> void:
	var parent := source.get_parent() as Node3D
	if parent == null: return
	var ghost := Sprite3D.new()
	ghost.texture = source.texture.duplicate() if source.texture is AtlasTexture else source.texture
	ghost.material_override = source.material_override
	ghost.hframes = source.hframes
	ghost.vframes = source.vframes
	ghost.frame = source.frame
	ghost.flip_h = source.flip_h
	ghost.offset = source.offset
	ghost.pixel_size = source.pixel_size
	ghost.billboard = source.billboard
	ghost.shaded = false
	ghost.no_depth_test = true
	ghost.modulate = source.modulate
	parent.add_child(ghost)
	ghost.transform = source.transform
	var fade := ghost.create_tween().set_parallel(true)
	fade.tween_property(ghost, "modulate:a", 0.0, 0.42)
	fade.tween_property(ghost, "scale", source.scale * 1.12, 0.42)
	fade.chain().tween_callback(ghost.queue_free)
	var mesh := SphereMesh.new()
	mesh.radius = 0.045
	mesh.height = 0.09
	mesh.radial_segments = 4
	mesh.rings = 2
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = tint
	mesh.material = material
	for index in 18:
		var spark := MeshInstance3D.new()
		spark.mesh = mesh
		parent.add_child(spark)
		var angle := index * TAU / 18.0
		var height := 0.25 + float(index % 4) * 0.22
		spark.position = Vector3(cos(angle) * 0.16, height, sin(angle) * 0.16)
		var target := spark.position + Vector3(cos(angle) * 0.62, 0.28 + float(index % 3) * 0.12, sin(angle) * 0.62)
		var burst := spark.create_tween().set_parallel(true)
		burst.tween_property(spark, "position", target, 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		burst.tween_property(spark, "scale", Vector3.ZERO, 0.62)
		burst.chain().tween_callback(spark.queue_free)
