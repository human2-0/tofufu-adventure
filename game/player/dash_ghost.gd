class_name DashGhost
extends RefCounted
## A short-lived visual attached to the world, independent of the moving actor.

static func spawn(source: Sprite3D) -> void:
	var ghost := Sprite3D.new()
	ghost.texture = source.texture.duplicate() if source.texture is AtlasTexture else source.texture
	ghost.material_override = source.material_override
	ghost.hframes = source.hframes
	ghost.vframes = source.vframes
	ghost.frame = source.frame
	ghost.flip_h = source.flip_h
	ghost.offset = source.offset
	ghost.billboard = source.billboard
	ghost.alpha_cut = Sprite3D.ALPHA_CUT_DISABLED
	ghost.shaded = false
	ghost.modulate = Color(1.0, 0.92, 0.45, 0.65)
	ghost.pixel_size = source.pixel_size
	source.get_parent().get_parent().add_child(ghost)
	ghost.global_transform = source.global_transform
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tween.parallel().tween_property(ghost, "scale", ghost.scale * 1.25, 0.22)
	tween.tween_callback(ghost.queue_free)
