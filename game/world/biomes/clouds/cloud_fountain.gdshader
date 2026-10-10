shader_type spatial;
uniform sampler2D cloud_texture : source_color, filter_linear_mipmap, repeat_enable;
void fragment() {
	float ripple = sin(length(UV - vec2(0.5)) * 90.0 - TIME * 2.0) * 0.5 + 0.5;
	vec3 cloud = texture(cloud_texture, UV + vec2(TIME * 0.006)).rgb;
	ALBEDO = mix(vec3(0.25, 0.58, 0.66), vec3(0.63, 0.85, 0.9), ripple * 0.25 + cloud.r * 0.5);
	EMISSION = vec3(0.06, 0.12, 0.14);
	ROUGHNESS = 0.28;
	SPECULAR = 0.45;
}
