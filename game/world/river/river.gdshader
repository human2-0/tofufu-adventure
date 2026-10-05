shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

uniform vec4 water_color : source_color = vec4(0.10, 0.47, 0.51, 1.0);
varying vec3 world;
varying float pond;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	pond = smoothstep(137.0, 147.0, world.z);
	float edge = 1.0 - pow(abs(UV.x * 2.0 - 1.0), 6.0);
	VERTEX.y += (sin(UV.y * 2.6 - TIME * 2.1) + sin(UV.x * 22.0 + UV.y * 1.2 - TIME * 1.5)) * 0.012 * edge;
}
float noise(vec2 p) {
	return sin(p.x * 1.7 + sin(p.y * 1.3)) * sin(p.y * 2.1 + cos(p.x * 0.8));
}
void fragment() {
	float across = abs(UV.x * 2.0 - 1.0);
	float speed = mix(1.45, 0.22, pond);
	vec2 flow = mix(vec2(UV.x * 8.0, UV.y - TIME * speed), vec2(world.x * 0.8, world.z * 0.8 - TIME * 0.22), pond);
	float ripple = sin(flow.y * 6.0 + sin(flow.x * 2.3) * 1.7);
	float secondary = sin(flow.y * 3.2 - flow.x * 4.0 + TIME * 0.35);
	float shore = smoothstep(0.65, 1.0, across);
	float foam = smoothstep(0.88, 0.98, ripple) * smoothstep(0.20, 0.8, noise(flow * vec2(2.0, 0.55))) * 0.20;
	foam += shore * smoothstep(0.1, 0.8, noise(flow * 1.7)) * 0.38;
	foam *= mix(1.0, 0.35, pond);
	float caustic = pow(0.5 + 0.5 * sin(flow.x * 4.0 + secondary + flow.y * 2.0), 8.0) * 0.06;
	vec3 shallow = vec3(0.37, 0.73, 0.65);
	vec3 water = mix(water_color.rgb, shallow, shore * 0.7 + caustic);
	float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 4.0);
	ALBEDO = mix(water, vec3(0.79, 0.91, 0.84), foam + fresnel * 0.18);
	ROUGHNESS = mix(0.22, 0.38, shore);
	SPECULAR = 0.65;
	NORMAL_MAP = normalize(vec3(ripple * 0.13, secondary * 0.10, 1.0)) * 0.5 + 0.5;
	ALPHA = mix(0.76, 0.52, shore) + foam * 0.12;
}
