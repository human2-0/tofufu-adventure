shader_type spatial;
render_mode cull_disabled;
uniform float dive_view = 0.0;
varying vec3 world;
varying float bed;
varying float crest;
void vertex() {
	world = VERTEX;
	bed = COLOR.r * 16.0 - 8.0;
	float shallow = 1.0 - smoothstep(0.0, 5.0, 1.8 - bed);
	float phase = world.z * 0.72 + sin(world.x * 0.09) * 0.8 - TIME * 1.55;
	crest = sin(phase);
	float wave = sin(world.z * 0.30 - TIME * 0.9 + world.x * 0.07) * 0.15;
	wave += crest * mix(0.08, 0.21, shallow);
	VERTEX.y += wave;
	world.y = VERTEX.y;
}
void fragment() {
	float depth = world.y - bed;
	if (depth < 0.025) discard;
	vec2 p = world.xz;
	float ripple = sin(p.x * 2.8 + sin(p.y * 1.7) * 1.5 + TIME * 1.6);
	float cross_ripple = cos(p.y * 2.1 + sin(p.x * 1.3) * 1.4 - TIME * 1.2);
	float long_swell = cos(p.y * 0.30 - TIME * 0.9 + p.x * 0.07);
	float short_swell = cos(p.y * 0.72 + sin(p.x * 0.09) * 0.8 - TIME * 1.55);
	float amplitude = mix(0.08, 0.21, 1.0 - smoothstep(0.0, 5.0, depth));
	vec3 normal = normalize(vec3(-long_swell * 0.0105 - short_swell * amplitude * cos(p.x * 0.09) * 0.072 + ripple * 0.018, 1.0, -long_swell * 0.045 - short_swell * amplitude * 0.72 + cross_ripple * 0.018));
	NORMAL = normalize((VIEW_MATRIX * vec4(FRONT_FACING ? normal : -normal, 0.0)).xyz);
	float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 4.0);
	float lace = sin(p.x * 2.7 + cos(p.y * 1.2) * 2.0 + TIME * 0.6) + sin(p.x * 4.1 - p.y * 3.4 + TIME) * 0.5;
	float foam = (1.0 - smoothstep(0.05, 0.7, depth)) * smoothstep(-0.8, 0.6, lace);
	foam += smoothstep(0.68, 0.97, crest) * (1.0 - smoothstep(0.8, 3.5, depth)) * 0.62;
	foam = clamp(foam, 0.0, 1.0);
	vec3 water = mix(vec3(0.20, 0.66, 0.65), vec3(0.025, 0.24, 0.38), smoothstep(0.0, 7.0, depth));
	ALBEDO = mix(water, vec3(0.92, 0.98, 0.90), foam);
	METALLIC = mix(0.42, 0.0, foam);
	SPECULAR = 0.95;
	ROUGHNESS = mix(0.12, 0.62, foam);
	float opacity = clamp(mix(0.36, 0.68, smoothstep(0.0, 4.0, depth)) + fresnel * 0.28 + foam * 0.6, 0.0, 0.96);
	ALPHA = FRONT_FACING ? mix(opacity, 0.16 + foam * 0.2, dive_view) : 0.18 + foam * 0.15;
}
