shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

void vertex() {
	float phase = TIME * 3.6 + VERTEX.x * 3.0 + VERTEX.z * 4.7;
	VERTEX.x += sin(phase) * UV.y * 0.13;
	VERTEX.z += cos(phase * 1.3) * UV.y * 0.13;
}

void fragment() {
	float tongues = sin(UV.x * 43.0 + TIME * 4.0) * sin(UV.y * 17.0 - TIME * 7.0);
	float heat = clamp(1.0 - UV.y + tongues * 0.22, 0.0, 1.0);
	vec3 color = mix(vec3(0.9, 0.08, 0.015), vec3(1.0, 0.83, 0.24), heat);
	ALBEDO = color;
	EMISSION = color * (1.3 + heat);
	ALPHA = smoothstep(0.02, 0.35, heat) * 0.8;
}
