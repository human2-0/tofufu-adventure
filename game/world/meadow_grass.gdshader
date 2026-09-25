shader_type spatial;
render_mode cull_disabled;
uniform vec2 wind_direction = vec2(1.0, 0.0);
uniform float wind_strength : hint_range(0.0, 1.0) = 0.0;
varying float tip;
void vertex() {
	tip = UV.y;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float gust = sin(TIME * (1.7 + wind_strength * 2.6) + dot(world.xz, wind_direction) * 0.7);
	float bend = (1.0 - UV.y) * (0.12 + wind_strength * 0.34);
	VERTEX.x += (gust * 0.12 + wind_direction.x * wind_strength) * bend;
	VERTEX.z += wind_direction.y * wind_strength * bend;
}
void fragment() {
	ALBEDO = mix(vec3(0.73, 0.86, 0.52), vec3(0.32, 0.63, 0.46), tip);
	ROUGHNESS = 1.0;
}
