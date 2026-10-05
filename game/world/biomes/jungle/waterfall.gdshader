shader_type spatial;
render_mode cull_disabled;
uniform bool cascade = false;
uniform vec3 deep_color : source_color = vec3(0.025, 0.30, 0.37);
uniform vec3 shallow_color : source_color = vec3(0.19, 0.72, 0.72);
varying vec3 local_position;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1,0)), f.x), mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x), f.y);
}
void vertex() {
	local_position = VERTEX;
	if (cascade) {
		VERTEX.z += sin(VERTEX.y * 2.2 + TIME * 7.0 + VERTEX.x * 3.0) * 0.09;
	} else {
		VERTEX.y += sin(VERTEX.x * 1.3 + TIME * 1.7) * cos(VERTEX.z * 1.8 - TIME * 1.2) * 0.035;
	}
}
void fragment() {
	vec2 p = cascade ? local_position.xy : local_position.xz;
	vec2 flow = cascade ? vec2(p.x * 4.5, p.y * 0.6 + TIME * 4.2) : p * 0.7 + vec2(TIME * 0.16, -TIME * 0.12);
	float turbulence = noise(flow) * 0.65 + noise(flow * 2.7) * 0.35;
	float foam;
	if (cascade) {
		float streak = pow(noise(vec2(p.x * 8.0, p.y * 0.25 + TIME * 3.0)), 2.0);
		foam = smoothstep(0.39, 0.85, turbulence + streak * 0.4);
		ALBEDO = mix(vec3(0.25, 0.65, 0.70), vec3(0.91, 0.98, 0.98), foam);
		ROUGHNESS = 0.22;
		ALPHA = 0.97;
	} else {
		float shore = length(p / vec2(14.0, 10.0));
		float impact = length((p - vec2(0.0, 6.2)) / vec2(4.8, 3.0));
		float rings = sin(length(p - vec2(0.0, 6.2)) * 5.5 - TIME * 4.0);
		foam = (1.0 - smoothstep(0.35, 1.3, impact)) * smoothstep(0.40, 0.72, turbulence + rings * 0.10);
		foam += smoothstep(0.90, 1.0, shore) * smoothstep(0.48, 0.70, turbulence) * 0.5;
		ALBEDO = mix(deep_color, shallow_color, clamp(shore * 0.65 + turbulence * 0.38, 0.0, 1.0));
		ALBEDO = mix(ALBEDO, vec3(0.87, 0.98, 0.96), clamp(foam, 0.0, 1.0));
		ROUGHNESS = 0.16 + foam * 0.4;
		ALPHA = 0.82 + foam * 0.18;
	}
	float dx = dFdx(turbulence); float dy = dFdy(turbulence);
	NORMAL_MAP = normalize(vec3(-dx * 4.0, -dy * 4.0, 1.0)) * 0.5 + 0.5;
	METALLIC = 0.08;
	SPECULAR = 0.8;
}
