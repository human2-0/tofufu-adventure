shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D surface_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float tile_size = 5.0;
uniform float relief = 0.055;
uniform float roughness = 0.92;
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	// Fixed world scale also preserves masonry proportions during maze cutaways.
	vec3 axis = abs(world_normal);
	vec2 plane = world_position.xz;
	if (axis.x > axis.y && axis.x > axis.z) {
		plane = world_position.zy;
	} else if (axis.z > axis.y) {
		plane = world_position.xy;
	}
	vec3 stone = texture(surface_texture, plane / tile_size).rgb;
	ALBEDO = stone * tint.rgb;
	ROUGHNESS = roughness;
	SPECULAR = 0.15;
	// A small surface gradient gives grout relief without extra normal-map assets.
	float height = dot(stone, vec3(0.3, 0.5, 0.2));
	vec3 dx = dFdx(VERTEX);
	vec3 dy = dFdy(VERTEX);
	vec3 across_x = cross(dy, NORMAL);
	vec3 across_y = cross(NORMAL, dx);
	float area = dot(dx, across_x);
	if (abs(area) > 0.000001) {
		vec3 gradient = (across_x * dFdx(height) + across_y * dFdy(height)) / area;
		NORMAL = normalize(NORMAL - gradient * relief);
	}
}
