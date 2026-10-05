shader_type spatial;
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float depth = max(0.0, 1.8 - world.y);
	float sand_grain = sin(world.x * 7.3 + sin(world.z * 5.1)) * sin(world.z * 6.7 + sin(world.x * 4.3)) * 0.006;
	float sand = 1.0 - smoothstep(2.8, 4.0, world.y);
	float ridges = sin(world.x * 1.8 + sin(world.z * 0.46) * 1.5) * 0.018 * sand;
	vec3 dry = COLOR.rgb + sand_grain + ridges;
	vec3 wet = vec3(0.34, 0.51, 0.46) + sand_grain + ridges;
	ALBEDO = mix(dry, wet, (1.0 - smoothstep(1.3, 2.55, world.y)));
	ALBEDO = mix(ALBEDO, COLOR.rgb, smoothstep(2.5, 6.5, depth) * 0.48);
	float a = sin(world.x * 2.6 + sin(world.z * 1.5 + TIME * 0.5));
	float b = sin(world.z * 2.3 + sin(world.x * 1.4 - TIME * 0.6));
	float caustic = pow(1.0 - abs(a + b) * 0.5, 12.0);
	EMISSION = vec3(0.055, 0.14, 0.12) * caustic * smoothstep(0.1, 1.0, depth);
	ROUGHNESS = mix(0.95, 0.68, smoothstep(0.0, 2.0, depth));
}
