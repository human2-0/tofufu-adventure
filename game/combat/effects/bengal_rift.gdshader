shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D art : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float age = 0.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv = UV;
	float ripple = sin(uv.y * 32.0 - age * 24.0) * sin(uv.y * 9.0 + age * 11.0);
	uv.x += ripple * 0.008 * sin(clamp(age * 5.0, 0.0, 1.0) * 1.5708);
	vec4 source = texture(art, uv);
	float split = 0.0025 * sin(age * 19.0);
	vec3 color = vec3(texture(art, uv + vec2(split, 0.0)).r, source.g,
		texture(art, uv - vec2(split, 0.0)).b);
	float pulse = 1.0 + 0.12 * sin(age * 31.0 + UV.y * 14.0);
	ALBEDO = color * tint.rgb * pulse;
	EMISSION = color * tint.rgb * (0.25 + 0.25 * pulse);
	ALPHA = source.a * tint.a * opacity;
}
