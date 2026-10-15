class_name MobLabels
extends RefCounted
## Shared snail nameplate and telegraph construction.

static func make(parent: Node3D, text: String, size: int, pixels: float, tint: Color, height: float) -> Label3D:
	var label := Label3D.new()
	label.visibility_range_end = 32.0
	label.visibility_range_end_margin = 2.0
	label.text = text
	label.font_size = size
	label.pixel_size = pixels
	label.modulate = tint
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	label.ignore_occlusion_culling = false
	label.render_priority = 127
	label.position.y = height
	parent.add_child(label)
	return label
