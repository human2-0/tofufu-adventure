shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D atlas : source_color, filter_linear;
uniform bool keyed = false;
void vertex() {
	vec3 s = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s.x, INV_VIEW_MATRIX[1] * s.y, INV_VIEW_MATRIX[2] * s.z, MODEL_MATRIX[3]);
}
void fragment() {
	vec4 p = texture(atlas, UV);
	float matte = keyed ? smoothstep(0.25, 0.55, min(p.r, p.b) - p.g) : 0.0;
	ALBEDO = p.rgb * COLOR.rgb;
	ALPHA = p.a * COLOR.a * (1.0 - matte);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
