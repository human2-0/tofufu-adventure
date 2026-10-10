shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D feather_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;

void fragment() {
	vec2 feather_uv = COLOR.a > 0.8 ? UV : UV * vec2(8.0, 6.0);
	vec3 markings = texture(feather_texture, feather_uv).rgb;
	float texture_amount = COLOR.a > 0.8 ? 0.8 : (COLOR.a > 0.2 ? 0.08 : 0.0);
	ALBEDO = COLOR.rgb * mix(vec3(1.0), markings, texture_amount);
	// An ink edge and broad lighting bands keep the manga silhouette readable.
	float edge = smoothstep(0.08, 0.24, abs(dot(NORMAL, VIEW)));
	ALBEDO *= mix(0.32, 1.0, edge);
	ROUGHNESS = 0.9;
}

void light() {
	float band = smoothstep(0.05, 0.15, dot(NORMAL, LIGHT));
	DIFFUSE_LIGHT += ALBEDO * (0.38 + band * 0.62) * LIGHT_COLOR * ATTENUATION / 3.14159265;
}
