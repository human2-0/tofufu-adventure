shader_type spatial;
render_mode diffuse_burley;
// The submerged sand shares the offshore floor's lighting and subtle grain.
varying vec3 world;
void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float grain = sin(world.x * 7.7 + sin(world.z * 5.1)) * sin(world.z * 8.3 + world.x * 2.1);
	ALBEDO = COLOR.rgb * (1.0 + grain * 0.045);
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
}
