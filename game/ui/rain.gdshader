shader_type canvas_item;
render_mode unshaded;

uniform float strength = 0.0;
uniform float age = 0.0;

float hash(float n) { return fract(sin(n * 127.1) * 43758.5453); }

float drops(vec2 uv, float scale, float speed) {
	vec2 p = uv * vec2(95.0, 12.0) * scale;
	p.x += uv.y * 22.0 * scale;
	float lane = floor(p.x);
	float x = fract(p.x) - 0.5;
	float y = fract(p.y - age * speed + hash(lane) * 10.0);
	float line = (1.0 - smoothstep(0.02, 0.10, abs(x))) * smoothstep(0.70, 0.86, y) * (1.0 - smoothstep(0.94, 1.0, y));
	return line * step(0.35, hash(lane + 7.0));
}

void fragment() {
	float rain = drops(UV, 1.0, 9.0) + drops(UV + vec2(0.17, 0.3), 1.65, 12.0) * 0.5;
	COLOR = vec4(mix(vec3(0.36, 0.49, 0.60), vec3(0.77, 0.89, 0.96), clamp(rain, 0.0, 1.0)), strength * (0.035 + rain * 0.53));
}
