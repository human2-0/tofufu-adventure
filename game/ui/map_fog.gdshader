shader_type canvas_item;
render_mode unshaded;
uniform sampler2D explored : filter_linear, repeat_disable;
uniform vec2 view_origin = vec2(0.0);
uniform vec2 view_scale = vec2(1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 atlas = view_origin + UV * view_scale;
	vec2 space = atlas * vec2(342.0, 709.0);
	float cloud = sin(space.x * 0.12 + sin(space.y * 0.08)) * sin(space.y * 0.09 + space.x * 0.04);
	vec3 galaxy = mix(vec3(0.008, 0.01, 0.025), vec3(0.07, 0.035, 0.12), cloud * 0.5 + 0.5);
	vec2 cells = space * 0.6;
	float seed = hash(floor(cells));
	float star = (1.0 - smoothstep(0.025, 0.10, length(fract(cells) - vec2(0.5)))) * step(0.94, seed);
	galaxy += vec3(0.53, 0.65, 0.85) * star * (0.7 + 0.3 * sin(TIME * 0.7 + seed * 40.0));
	float inside = step(0.0, atlas.x) * step(atlas.x, 1.0) * step(0.0, atlas.y) * step(atlas.y, 1.0);
	float known = smoothstep(0.15, 0.85, texture(explored, atlas).r) * inside;
	COLOR = vec4(mix(galaxy, texture(TEXTURE, atlas).rgb, known), 1.0);
}
