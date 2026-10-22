shader_type canvas_item;
render_mode unshaded;
uniform sampler2D mist : source_color, repeat_enable, filter_linear_mipmap;
uniform float phase = 0.0;
uniform float danger = 0.0;
void fragment() {
	vec3 cloud = texture(mist, UV * vec2(2.0, 1.3) + vec2(phase * 0.01, -phase * 0.014)).rgb;
	float edge = pow(clamp(length((UV - 0.5) * vec2(1.3, 1.0)), 0.0, 1.0), 2.0);
	float pulse = 0.9 + sin(phase * 3.0) * 0.1;
	COLOR = vec4(mix(vec3(0.38, 0.12, 0.6), cloud, 0.45), edge * danger * pulse * 0.85);
}
