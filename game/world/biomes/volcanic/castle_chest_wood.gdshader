shader_type spatial;
uniform vec4 wood_color : source_color = vec4(0.23, 0.095, 0.045, 1.0);
void fragment() {
	vec2 grain_uv = UV * vec2(5.0, 1.0);
	float plank = floor(grain_uv.x);
	float seam = smoothstep(0.025, 0.07, fract(grain_uv.x)) * (1.0 - smoothstep(0.93, 0.975, fract(grain_uv.x)));
	float grain = sin(UV.y * 145.0 + sin(UV.x * 30.0 + plank) * 5.0) * 0.15;
	float wear = sin(plank * 37.0) * 0.17 + grain;
	ALBEDO = wood_color.rgb * (0.65 + seam * 0.65 + wear);
	ROUGHNESS = 0.86;
}
