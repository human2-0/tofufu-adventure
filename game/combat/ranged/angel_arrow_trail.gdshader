shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform sampler2D flames : source_color, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool billboard = false;
void vertex() {
	if (billboard) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	}
}
void fragment() {
	vec3 flame = texture(flames, UV).rgb;
	ALBEDO = tint.rgb * (0.6 + flame * 0.4);
	ALPHA = smoothstep(0.08, 0.65, flame.r) * COLOR.a;
}
