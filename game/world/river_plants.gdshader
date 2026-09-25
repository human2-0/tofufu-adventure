shader_type spatial;
render_mode cull_disabled;
void vertex() {
	VERTEX.x += sin(TIME * 1.6 + VERTEX.z * 0.9) * UV.y * 0.08;
	VERTEX.z += cos(TIME * 1.2 + VERTEX.x) * UV.y * 0.04;
}
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.9;
}
