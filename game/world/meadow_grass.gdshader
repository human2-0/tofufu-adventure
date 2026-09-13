shader_type spatial;
render_mode cull_disabled;
varying float tip;
void vertex() {
	tip = UV.y;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.x += sin(TIME * 1.7 + world.x * 0.5 + world.z * 0.7) * (1.0 - UV.y) * 0.12;
}
void fragment() {
	ALBEDO = mix(vec3(0.73, 0.86, 0.52), vec3(0.32, 0.63, 0.46), tip);
	ROUGHNESS = 1.0;
}
