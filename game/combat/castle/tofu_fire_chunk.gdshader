shader_type spatial;
uniform float heat = 1.0;
void fragment() {
	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float pore = pow(abs(sin(UV.x * 47.0) * sin(UV.y * 59.0)), 18.0);
	float crust = 1.0 - smoothstep(0.03, 0.12, edge);
	ALBEDO = mix(vec3(0.92, 0.68, 0.28), vec3(0.16, 0.04, 0.025), crust * 0.8 + pore * 0.15);
	EMISSION = vec3(1.0, 0.22, 0.015) * (crust + pore * 0.8) * heat * 2.4;
	ROUGHNESS = 0.8;
}
