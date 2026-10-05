shader_type spatial;
render_mode cull_disabled;
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = world.xz * 0.55 + vec2(-TIME * 0.18, TIME * 0.24);
	float flow = sin(p.x + sin(p.y * 1.8)) * cos(p.y + sin(p.x * 1.6));
	float cracks = smoothstep(0.10, 0.25, abs(flow));
	float hot = (sin(p.y * 2.4 + TIME) + 1.0) * 0.5;
	vec3 molten = mix(vec3(1.0, 0.10, 0.005), vec3(1.0, 0.68, 0.08), hot);
	ALBEDO = mix(molten, vec3(0.10, 0.022, 0.015), cracks * 0.65);
	EMISSION = molten * (1.0 - cracks * 0.8) * 2.3;
	ROUGHNESS = 0.7;
}
