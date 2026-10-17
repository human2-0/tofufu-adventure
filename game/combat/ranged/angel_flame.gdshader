shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float fade = 1.0;
uniform sampler2D flames : source_color, repeat_enable, filter_linear_mipmap;
void fragment() {
	vec3 flame = texture(flames, UV * vec2(2.0, 1.0) + vec2(0.0, TIME * 0.25)).rgb;
	float rim = pow(1.0 - abs(dot(NORMAL, VIEW)), 1.8);
	ALBEDO = flame;
	EMISSION = ALBEDO * 1.8;
	ALPHA = smoothstep(0.08, 0.6, flame.r) * (0.25 + rim * 0.65) * fade;
}
