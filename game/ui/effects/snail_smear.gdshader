shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float age = 0.0;
uniform float slant = 0.0;

void fragment() {
	vec2 p = SCREEN_UV - vec2(0.5, 0.47 + age * 0.025);
	p.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float curve = p.y + p.x * (0.34 + slant) + 0.035 * sin(p.x * 9.0);
	float taper = sqrt(max(0.0, 1.0 - pow(p.x / 0.64, 2.0)));
	float width = 0.085 * taper * (1.0 + 0.13 * sin(p.x * 57.0));
	float mask = (1.0 - smoothstep(width * 0.76, width + 0.008, abs(curve))) * taper;
	float ridges = sin(curve * 190.0 + sin(p.x * 18.0) * 2.0);
	vec2 bend = vec2(cos(p.x * 21.0 + curve * 30.0), ridges) * 0.012 * mask * strength;
	vec3 refracted = texture(screen_texture, clamp(SCREEN_UV + bend, vec2(0.001), vec2(0.999))).rgb;
	float rim = smoothstep(width * 0.5, width * 0.85 + 0.001, abs(curve));
	vec3 slime = mix(vec3(0.67, 0.73, 0.37), vec3(1.0, 0.94, 0.71), rim * 0.7 + max(ridges, 0.0) * 0.2);
	COLOR = vec4(mix(refracted, slime, 0.23 + rim * 0.22), mask * strength * 0.92);
}
