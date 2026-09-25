shader_type canvas_item;
render_mode unshaded;

uniform vec2 direction = vec2(1.0, 0.0);
uniform float strength : hint_range(0.0, 1.0) = 0.0;

float streak(vec2 uv, float lane) {
	float offset = fract(lane * 17.13) * 6.0;
	float travel = fract(uv.x * 4.0 - TIME * (0.35 + strength) + offset);
	float line = smoothstep(0.0, 0.08, travel) * (1.0 - smoothstep(0.38, 0.72, travel));
	return line * step(0.46, fract(lane * 5.71));
}

void fragment() {
	vec2 axis = normalize(direction);
	vec2 perpendicular = vec2(-axis.y, axis.x);
	vec2 flow = vec2(dot(UV - vec2(0.5), axis), dot(UV - vec2(0.5), perpendicular));
	float lane = floor(flow.y * 19.0);
	float gust = streak(vec2(flow.x + 0.5, flow.y), lane);
	COLOR = vec4(0.74, 0.90, 0.87, gust * strength * 0.12);
}
