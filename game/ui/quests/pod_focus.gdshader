shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float reveal : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 offset = (SCREEN_UV - vec2(0.5, 0.43)) * vec2(1.4, 1.0);
	float edge = smoothstep(0.16, 0.58, length(offset)) * (1.0 - reveal);
	vec3 crisp = texture(screen_texture, SCREEN_UV).rgb;
	vec3 soft = textureLod(screen_texture, SCREEN_UV, 3.0).rgb;
	COLOR = vec4(mix(crisp, soft, edge) * (1.0 - edge * 0.48), 1.0);
}
