shader_type spatial;
uniform vec3 stone_color : source_color = vec3(0.22, 0.34, 0.30);
varying vec3 at;
varying vec3 normal_at;
void vertex() { at = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; normal_at = normalize(MODEL_NORMAL_MATRIX * NORMAL); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 cell = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1,0)), f.x), mix(hash(cell + vec2(0,1)), hash(cell + vec2(1,1)), f.x), f.y);
}
void fragment() {
	float grain = noise(at.xy * 2.6) * 0.7 + noise(at.zy * 7.0) * 0.3;
	float strata = smoothstep(0.02, 0.12, abs(sin(at.y * 3.8 + noise(at.xz) * 2.5)));
	float wet = smoothstep(0.38, 0.62, noise(vec2(at.x * 1.4, at.y * 0.13))) * 0.65;
	float moss = smoothstep(0.15, 0.65, normal_at.y + grain * 0.3);
	ALBEDO = stone_color * (0.7 + grain * 0.6) * mix(0.73, 1.0, strata) * (1.0 - wet * 0.27);
	ALBEDO = mix(ALBEDO, vec3(0.24, 0.40, 0.18), moss * 0.8);
	ROUGHNESS = mix(0.95, 0.22, wet);
	SPECULAR = 0.5;
}
