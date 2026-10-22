shader_type canvas_item;
render_mode unshaded;
uniform vec2 safe_center = vec2(0.5);
uniform float safe_radius = 0.42;
uniform vec2 map_center = vec2(0.5);
uniform float map_span = 1.0;
void fragment() {
	vec2 world_uv = map_center + (UV - 0.5) * map_span;
	vec4 terrain = texture(TEXTURE, clamp(world_uv, vec2(0.0), vec2(1.0)));
	if (any(lessThan(world_uv, vec2(0.0))) || any(greaterThan(world_uv, vec2(1.0)))) terrain.rgb = vec3(0.06, 0.15, 0.13);
	float outside = smoothstep(safe_radius - 0.002, safe_radius + 0.002, distance(world_uv, safe_center));
	float stripes = step(0.5, fract((UV.x + UV.y) * 38.0));
	vec3 danger = mix(vec3(0.21, 0.12, 0.35), vec3(0.43, 0.26, 0.57), stripes * 0.26);
	COLOR = vec4(mix(terrain.rgb, mix(terrain.rgb * 0.7, danger, 0.45), outside), 1.0);
}
