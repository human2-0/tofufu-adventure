shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
uniform sampler2D cloud_texture : source_color, filter_linear_mipmap, repeat_enable;
varying float phase;
void vertex() {
	vec3 center = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	phase = dot(center.xz, vec2(0.13, 0.27));
	vec3 at = center + INV_VIEW_MATRIX[0].xyz * VERTEX.x * length(MODEL_MATRIX[0].xyz)
		+ INV_VIEW_MATRIX[1].xyz * VERTEX.y * length(MODEL_MATRIX[1].xyz);
	at.x += sin(TIME * 0.12 + phase) * 0.35;
	at.y += cos(TIME * 0.17 + phase) * 0.08;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(at, 1.0);
}
void fragment() {
	vec3 cloud = texture(cloud_texture, UV + vec2(TIME * 0.003 + phase, 0.0)).rgb;
	float feather = 1.0 - smoothstep(0.12, 1.0, length(UV * 2.0 - 1.0));
	ALBEDO = cloud;
	ALPHA = feather * 0.22;
}
