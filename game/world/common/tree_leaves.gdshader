shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float phase = world.x * 1.7 + world.z * 1.1;
	float breeze = sin(TIME * 1.25 + phase) * 0.018 + sin(TIME * 2.7 + phase * 2.0) * 0.007;
	VERTEX.x += breeze * smoothstep(1.4, 3.2, VERTEX.y);
	VERTEX.z += breeze * 0.55;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
}
