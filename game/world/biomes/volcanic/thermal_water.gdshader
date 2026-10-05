shader_type spatial;
render_mode cull_disabled;
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float a = sin(world.x * 2.3 + world.z * 1.7 - TIME * 0.5);
	float b = sin(world.x * 1.1 - world.z * 2.5 + TIME * 0.7);
	NORMAL = normalize(NORMAL + vec3(a, b, 0.0) * 0.055);
	ALBEDO = mix(vec3(0.12, 0.39, 0.34), vec3(0.38, 0.67, 0.54), (a * b + 1.0) * 0.5);
	ROUGHNESS = 0.18;
	METALLIC = 0.12;
	SPECULAR = 0.7;
}
