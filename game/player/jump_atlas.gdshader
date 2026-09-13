shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D atlas : source_color, filter_linear;

void vertex() {
	vec3 sprite_scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sprite_scale.x, INV_VIEW_MATRIX[1] * sprite_scale.y, INV_VIEW_MATRIX[2] * sprite_scale.z, MODEL_MATRIX[3]);
}

void fragment() {
	vec4 pixel = texture(atlas, UV);
	// The generated source has a cool-neutral matte. Retain warm body colors,
	// green outlines/sprout and neutral white eye highlights without altering it.
	float high = max(pixel.r, max(pixel.g, pixel.b));
	float low = min(pixel.r, min(pixel.g, pixel.b));
	float matte = 1.0 - smoothstep(0.04, 0.12, high - low);
	matte *= 1.0 - smoothstep(0.82, 0.95, low);
	matte *= smoothstep(0.18, 0.35, high);
	ALBEDO = pixel.rgb * COLOR.rgb;
	ALPHA = pixel.a * COLOR.a * (1.0 - matte);
	ALPHA_SCISSOR_THRESHOLD = 0.45;
}
