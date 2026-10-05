shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX[0].xyz *= length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX[1].xyz *= length(MODEL_MATRIX[1].xyz);
}
void fragment() {
	float radial = length(UV * 2.0 - 1.0);
	ALBEDO = vec3(0.83, 0.96, 0.97);
	ALPHA = (1.0 - smoothstep(0.2, 1.0, radial)) * COLOR.a * 0.13;
}
