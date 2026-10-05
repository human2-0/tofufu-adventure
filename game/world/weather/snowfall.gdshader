shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 wind = vec2(1.0, 0.0);
uniform float gust : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	float seed = INSTANCE_CUSTOM.r;
	float phase = fract(seed + TIME * (0.07 + INSTANCE_CUSTOM.g * 0.045));
	float spin = TIME * (0.9 + INSTANCE_CUSTOM.b) + seed * 6.28318;
	VERTEX.xy = mat2(vec2(cos(spin), sin(spin)), vec2(-sin(spin), cos(spin))) * VERTEX.xy;
	VERTEX *= (0.7 + INSTANCE_CUSTOM.b * 0.8) * strength;
	VERTEX.y += 0.14 + (1.0 - phase) * 12.0;
	VERTEX.xz += wind * (phase - 0.5) * (1.3 + gust * 4.0);
	VERTEX.x += sin(spin * 0.7) * 0.32;
	VERTEX.z += cos(spin * 0.6 + seed * 8.0) * 0.28;
}

void fragment() {
	ALBEDO = vec3(0.91, 0.96, 1.0);
}
