shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D atlas : source_color, filter_linear;

void vertex() {
	vec3 s = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s.x, INV_VIEW_MATRIX[1] * s.y, INV_VIEW_MATRIX[2] * s.z, MODEL_MATRIX[3]);
}
void fragment() {
	vec4 pixel = texture(atlas, UV);
	// Generated source uses a saturated magenta matte, never present in the weapon.
	float key = smoothstep(0.15, 0.35, min(pixel.r, pixel.b) - pixel.g);
	ALBEDO = pixel.rgb * COLOR.rgb;
	ALPHA = pixel.a * COLOR.a * (1.0 - key);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
