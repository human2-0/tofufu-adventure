shader_type spatial;
render_mode cull_disabled;
void vertex() {
	float tail = smoothstep(0.05, 0.54, VERTEX.z);
	VERTEX.x += sin(TIME * 13.0 + MODEL_MATRIX[3].z + VERTEX.z * 9.0) * tail * 0.07;
}
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.45;
}
