shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform sampler2D mist : source_color, repeat_enable, filter_linear_mipmap;
uniform float phase = 0.0;
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}
void fragment() {
	vec2 drift = vec2(phase * 0.012, -phase * 0.018);
	vec2 weight = pow(abs(normalize(world_normal).xz), vec2(3.0));
	weight /= max(0.001, weight.x + weight.y);
	vec3 cloud = texture(mist, world_position.zy / 24.0 + drift).rgb * weight.x;
	cloud += texture(mist, world_position.xy / 24.0 + drift).rgb * weight.y;
	vec3 detail = texture(mist, world_position.xz / 18.0 - drift * 0.7).rgb;
	float density = dot(cloud, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(vec3(0.32, 0.13, 0.55), cloud * vec3(1.3, 1.1, 1.7), 0.6);
	EMISSION = mix(vec3(0.2, 0.04, 0.4), detail * vec3(0.6, 0.4, 1.1), 0.65);
	float veil = smoothstep(0.0, 0.08, UV.y) * (1.0 - smoothstep(0.93, 1.0, UV.y));
	ALPHA = clamp(0.32 + density * 0.48, 0.32, 0.75) * veil;
}
