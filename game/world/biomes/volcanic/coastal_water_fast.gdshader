shader_type spatial;
render_mode cull_disabled;
// Vertex colour stores authored seabed height. No screen copies or ray marching.
uniform vec3 color_shallow : source_color = vec3(0.20, 0.56, 0.62);
uniform vec3 color_deep : source_color = vec3(0.027, 0.20, 0.31);
uniform float dive_view = 0.0;
varying vec3 world;
varying float bed;
varying float crest;
void vertex() {
	world = VERTEX;
	bed = COLOR.r * 128.0 - 64.0;
	float phase = world.z * 0.48 + world.x * 0.19 - TIME * 1.2;
	crest = sin(phase);
	VERTEX.y += crest * 0.16 + sin(world.x * 0.33 - world.z * 0.17 + TIME * 0.9) * 0.09;
	world.y = VERTEX.y;
}
void fragment() {
	float depth = max(0.0, world.y - bed);
	if (world.y - bed < 0.015) discard;
	vec2 p = world.xz;
	float slope_a = cos(p.y * 0.48 + p.x * 0.19 - TIME * 1.2) * 0.16;
	float slope_b = cos(p.x * 0.33 - p.y * 0.17 + TIME * 0.9) * 0.09;
	float ripple = sin(p.x * 2.3 + p.y * 1.7 + TIME * 1.8) * 0.016;
	vec3 normal = normalize(vec3(-slope_a * 0.19 - slope_b * 0.33 + ripple, 1.0, -slope_a * 0.48 + slope_b * 0.17 - ripple));
	NORMAL = normalize((VIEW_MATRIX * vec4(FRONT_FACING ? normal : -normal, 0.0)).xyz);
	float lace = sin(p.x * 2.7 + cos(p.y * 1.2) * 2.0 + TIME * 0.6);
	float foam = (1.0 - smoothstep(0.05, 0.8, depth)) * smoothstep(-0.6, 0.6, lace);
	foam += smoothstep(0.75, 0.98, crest) * (1.0 - smoothstep(0.8, 2.8, depth)) * 0.5;
	foam = clamp(foam, 0.0, 1.0);
	ALBEDO = mix(mix(color_shallow, color_deep, smoothstep(0.0, 9.0, depth)), vec3(0.91, 0.98, 0.96), foam);
	METALLIC = mix(0.35, 0.0, foam);
	ROUGHNESS = mix(0.16, 0.65, foam);
	SPECULAR = 0.8;
	float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 4.0);
	float shore_opacity = clamp(0.48 + depth * 0.035 + fresnel * 0.25 + foam * 0.5, 0.0, 0.97);
	// Deep water hides the finite seabed mesh; shallows retain shoreline transparency.
	float opacity = mix(shore_opacity, 1.0, smoothstep(2.0, 6.0, depth));
	ALPHA = FRONT_FACING ? mix(opacity, 0.2, dive_view) : 0.2;
}
