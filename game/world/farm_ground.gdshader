shader_type spatial;
render_mode diffuse_toon;

uniform vec4 grass_low : source_color = vec4(0.50, 0.67, 0.35, 1.0);
uniform vec4 grass_high : source_color = vec4(0.68, 0.74, 0.43, 1.0);
uniform vec4 lane_color : source_color = vec4(0.85, 0.69, 0.45, 1.0);
uniform vec4 soil_color : source_color = vec4(0.58, 0.39, 0.23, 1.0);
uniform vec2 combat_centers[3];
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
varying vec3 ground;

void vertex() {
	ground = VERTEX;
}

float field(vec2 p, vec2 low, vec2 high) {
	vec2 edge = min(p - low, high - p);
	return smoothstep(-0.15, 0.15, min(edge.x, edge.y));
}

void fragment() {
	float x = ground.x;
	float z = ground.z;
	float fleck = sin(x * 3.2 + sin(z * 2.4)) * sin(z * 4.3 + x) * 0.035;
	vec3 color = mix(grass_low.rgb, grass_high.rgb, clamp(ground.y * 0.2 + fleck, 0.0, 1.0));
	float beds = max(field(ground.xz, vec2(-16.5, -11.0), vec2(-7.0, -1.3)), field(ground.xz, vec2(-6.5, -9.5), vec2(5.2, 1.2)));
	beds = max(beds, field(ground.xz, vec2(-17.0, 12.0), vec2(-5.0, 23.0)));
	float furrow = smoothstep(-0.5, 0.5, sin(x * 4.18879));
	color = mix(color, soil_color.rgb * (0.9 + furrow * 0.24 + fleck), beds);
	float east = length(vec2(max(0.0, abs(x - 5.0) - 25.0), z - (4.0 + sin(x * 0.23) * 0.8)));
	float nursery = length(vec2(x - (1.8 + sin(z * 0.16) * 2.0), max(0.0, abs(z - 3.0) - 18.0)));
	float bank = length(vec2(x - (-19.0 + sin(z * 0.13) * 2.0), max(0.0, abs(z + 9.5) - 14.5)));
	float village = length(vec2(x - (23.0 + sin(z * 0.17) * 1.5), max(0.0, abs(z - 2.5) - 17.5)));
	float mayor = length(vec2(max(0.0, abs(x - 27.0) - 4.0), z - (18.0 + sin(x * 0.3) * 0.3)));
	float road = min(mayor, min(min(east, nursery), min(bank, village)));
	float wear = 1.0 - smoothstep(1.0, 1.5, road + fleck * 3.0 + sin(x * 1.7 + z * 2.9) * 0.06);
	color = mix(color, lane_color.rgb * (1.0 + fleck), wear);
	float river = 11.0 + sin((z - 4.0) * 0.12) * 2.2 * smoothstep(5.0, 14.0, abs(z - 4.0));
	float shore = 1.0 - smoothstep(2.7, 3.45, abs(x - river));
	color = mix(color, lane_color.rgb * 0.83, shore);
	float clearing = 0.0;
	for (int i = 0; i < 3; i++) {
		float distance_to_pack = length(ground.xz - combat_centers[i]);
		clearing = max(clearing, 1.0 - smoothstep(5.2, 6.1, distance_to_pack + fleck * 7.0));
	}
	float practice = 1.0 - smoothstep(3.1, 3.7, length(ground.xz - vec2(19.3, 12.0)) + fleck * 3.0);
	color = mix(color, lane_color.rgb * (0.83 + fleck), clearing);
	color = mix(color, lane_color.rgb * (1.0 + fleck), practice);
	// Rain darkens every exposed surface before the discrete puddle meshes add pooling.
	ALBEDO = mix(color, color * vec3(0.57, 0.66, 0.70), wetness * 0.38);
	ROUGHNESS = mix(1.0, 0.46, wetness);
	SPECULAR = mix(0.0, 0.42, wetness);
}
