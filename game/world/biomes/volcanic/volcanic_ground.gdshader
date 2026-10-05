shader_type spatial;
render_mode diffuse_burley;
// Small world-space grain and cooling fractures preserve the authored vertex palette.
varying vec3 world;
void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float grain = sin(world.x * 7.7 + sin(world.z * 5.1)) * sin(world.z * 8.3 + world.x * 2.1);
	float strata = sin(world.y * 2.8 + sin(world.x * 0.19) * 0.5);
	float line_a = abs(sin(world.x * 0.72 + sin(world.z * 0.43) * 1.9));
	float line_b = abs(sin(world.z * 0.65 + cos(world.x * 0.39) * 1.6));
	float fracture = 1.0 - smoothstep(0.015, 0.07, min(line_a, line_b));
	float rock = smoothstep(3.0, 9.0, world.y);
	float detail = 1.0 + grain * 0.045 + strata * rock * 0.045 - fracture * rock * 0.12;
	ALBEDO = COLOR.rgb * detail;
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
}
