shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, unshaded;

uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform float age = 0.0;
uniform float seed = 0.0;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float radius = length(centered) * 2.0;
	float wavy_edge = 1.0 - smoothstep(0.76, 1.03, radius + sin(atan(centered.y, centered.x) * 5.0 + seed * 19.0) * 0.065);
	float hit = fract(age * 1.35 + seed);
	float ring_radius = hit * 0.84;
	float ripple = exp(-pow((radius - ring_radius) * 24.0, 2.0));
	ripple += exp(-pow((radius - ring_radius * 0.58) * 31.0, 2.0)) * (1.0 - hit) * 0.45;
	vec3 water = mix(vec3(0.08, 0.20, 0.25), vec3(0.39, 0.73, 0.78), ripple * 0.72);
	ALBEDO = water;
	EMISSION = vec3(0.12, 0.34, 0.39) * ripple * wetness;
	ALPHA = wavy_edge * wetness * (0.38 + ripple * 0.35);
}
