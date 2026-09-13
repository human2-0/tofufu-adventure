shader_type spatial;
render_mode cull_disabled;
uniform vec4 water_color : source_color = vec4(0.24, 0.70, 0.76, 1.0);
varying vec3 world;
void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(world.z * 2.0 + TIME * 2.0 + world.x) * 0.025;
}
void fragment() {
	float wave = sin(world.z * 4.5 - TIME * 3.5 + sin(world.x * 6.0));
	float streak = smoothstep(0.91, 0.99, wave) * smoothstep(0.1, 0.8, sin(world.x * 11.0 + world.z));
	float bank = smoothstep(0.82, 1.0, abs(UV.x * 2.0 - 1.0));
	ALBEDO = mix(water_color.rgb, vec3(0.71, 0.92, 0.86), streak * 0.65 + bank * 0.45);
	ROUGHNESS = 0.85;
	METALLIC = 0.0;
	NORMAL_MAP = vec3(0.5 + sin(world.z * 5.0 - TIME * 3.0) * 0.1, 0.5, 1.0);
}
