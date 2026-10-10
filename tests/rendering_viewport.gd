extends RefCounted
## Fixed render target: window/fullscreen transitions must never change a GPU sample.

static func create(window: Window) -> SubViewport:
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var viewport := SubViewport.new()
	viewport.size = Vector2i(2560, 1440)
	viewport.own_world_3d = true
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.screen_space_aa = window.screen_space_aa
	viewport.msaa_3d = window.msaa_3d
	viewport.use_occlusion_culling = window.use_occlusion_culling
	window.add_child(viewport)
	var display := TextureRect.new()
	display.texture = viewport.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window.add_child(display)
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return viewport

static func dimensions(viewport: SubViewport) -> Dictionary:
	var texture := viewport.get_texture()
	return {"render_width": texture.get_width(), "render_height": texture.get_height()}
