shader_type spatial;
render_mode unshaded;
uniform vec4 tint : source_color = vec4(1.0, 0.94, 0.74, 1.0);
void fragment() {
	float rim = smoothstep(0.18, 0.38, abs(dot(normalize(NORMAL), normalize(VIEW))));
	ALBEDO = mix(vec3(0.09, 0.16, 0.08), tint.rgb, rim);
}
