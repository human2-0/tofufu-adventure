shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D ground_grain : source_color, repeat_enable, filter_linear_mipmap;
varying vec2 ground;
void vertex() { ground = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz; }
void fragment() {
	vec3 detail = texture(ground_grain, ground / 9.0).rgb;
	ALBEDO = COLOR.rgb * mix(vec3(0.94), vec3(1.06), detail);
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
}
