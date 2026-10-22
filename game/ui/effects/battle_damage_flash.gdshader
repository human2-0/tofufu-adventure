shader_type canvas_item;
render_mode unshaded;
uniform float strength = 0.0;
void fragment() {
	float edge = smoothstep(0.16, 0.75, length((UV - 0.5) * vec2(1.35, 1.0)));
	COLOR = vec4(1.0, 0.12, 0.18, edge * strength * 0.72);
}
