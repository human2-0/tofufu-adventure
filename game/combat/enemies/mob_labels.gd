class_name MobLabels
extends RefCounted
## Shared snail nameplate and telegraph construction.

static func make(parent: Node3D, text: String, size: int, pixels: float, tint: Color, height: float) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = pixels
	label.modulate = tint
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.ignore_occlusion_culling = true
	label.render_priority = 127
	label.position.y = height
	parent.add_child(label)
	return label
