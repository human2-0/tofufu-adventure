shader_type spatial;
render_mode unshaded, cull_front;
uniform float width = 0.03;
void vertex() {
	VERTEX += NORMAL * width;
}
void fragment() {
	ALBEDO = vec3(0.009, 0.022, 0.027);
}
