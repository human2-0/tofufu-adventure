shader_type spatial;
render_mode cull_disabled;
uniform vec2 wind_direction = vec2(1.0, 0.0);
uniform float wind_strength : hint_range(0.0, 1.0) = 0.0;
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D bend_map : filter_linear, repeat_disable;
uniform vec2 bend_origin = vec2(-76.0, -64.0);
uniform vec2 bend_size = vec2(152.0, 128.0);
varying float blade_height;
varying float variation;
varying float vein;

void vertex() {
	blade_height = 1.0 - UV.y;
	variation = INSTANCE_CUSTOM.r;
	vein = UV.x;
	vec3 root = MODEL_MATRIX[3].xyz;
	vec2 map_uv = (root.xz - bend_origin) / bend_size;
	vec3 field = textureLod(bend_map, map_uv, 0.0).rgb;
	vec2 imprint = (field.rg * 255.0 - 128.0) / 127.0;
	float pressed = field.b;
	float phase = dot(root.xz, wind_direction) * 0.75;
	float gust = sin(TIME * (1.8 + wind_strength * 1.8) + phase);
	float flutter = sin(TIME * 4.2 + phase * 2.3 + INSTANCE_CUSTOM.g * 6.28);
	vec2 breeze = wind_direction * (0.025 * gust + wind_strength * (0.13 + 0.075 * gust));
	breeze += vec2(-wind_direction.y, wind_direction.x) * flutter * (0.006 + wind_strength * 0.018);
	// Root is fixed. Curvature and tip droop retain wind even in a flattened trail.
	float curve = blade_height * blade_height;
	float blade_scale = length(MODEL_MATRIX[1].xyz);
	vec2 offset = (imprint * 0.48 * blade_scale + breeze * (1.0 - pressed * 0.45)) * curve;
	float droop = -VERTEX.y * blade_scale * pressed * 0.78 * blade_height - wetness * curve * 0.035;
	VERTEX += inverse(mat3(MODEL_MATRIX)) * vec3(offset.x, droop, offset.y);
	float distance_to_camera = distance(root, CAMERA_POSITION_WORLD);
	VERTEX *= 1.0 - smoothstep(34.0, 44.0, distance_to_camera);
}

void fragment() {
	vec3 base = mix(vec3(0.19, 0.34, 0.105), vec3(0.29, 0.43, 0.15), variation);
	vec3 tips = mix(vec3(0.43, 0.58, 0.24), vec3(0.55, 0.63, 0.30), variation);
	float ridge = 1.0 - abs(vein * 2.0 - 1.0);
	ALBEDO = mix(base, tips, blade_height) * (0.90 + ridge * 0.10) * (1.0 - wetness * 0.12);
	ROUGHNESS = mix(0.88, 0.58, wetness);
	BACKLIGHT = ALBEDO * 0.22;
}
