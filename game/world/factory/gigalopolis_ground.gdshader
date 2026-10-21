shader_type spatial;
uniform sampler2D paving : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world;
void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec3 grain = texture(paving, world.xz * 0.24).rgb;
	ALBEDO = COLOR.rgb * mix(vec3(1.0), grain * 1.7, 0.35);
	ROUGHNESS = 0.95;
	SPECULAR = 0.12;
}
