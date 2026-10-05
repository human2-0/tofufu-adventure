shader_type spatial;
render_mode unshaded, cull_disabled;

uniform bool leaves = false;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 wind = vec2(1.0, 0.0);

void vertex() {
	float seed = INSTANCE_CUSTOM.r;
	float speed = 0.7 + INSTANCE_CUSTOM.g * 0.35;
	if (leaves) {
		float phase = fract(seed + TIME * 0.22 * speed);
		float spin = TIME * 4.0 + seed * 6.28318;
		VERTEX.xz = mat2(vec2(cos(spin), sin(spin)), vec2(-sin(spin), cos(spin))) * VERTEX.xz;
		VERTEX *= strength * sin(phase * 3.14159);
		VERTEX.xz += wind * (phase - 0.5) * 6.0;
		VERTEX.y += 0.35 + INSTANCE_CUSTOM.b * 2.0 + sin(spin) * 0.2;
	} else {
		float phase = fract(seed + TIME * speed);
		VERTEX *= strength;
		VERTEX.y += 0.2 + (1.0 - phase) * 12.0;
		VERTEX.xz += wind * (phase - 0.5) * 0.7;
	}
}

void fragment() {
	ALBEDO = leaves ? vec3(0.55, 0.66, 0.28) : vec3(0.63, 0.78, 0.84);
}
