shader_type spatial;
varying vec3 world;
uniform float stem_height = 2.0;
void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float tip = clamp((VERTEX.y + stem_height * 0.5) / stem_height, 0.0, 1.0);
	VERTEX.x += sin(world.z * 0.6 + TIME * 1.1) * tip * tip * 0.28;
}
void fragment() {
	ALBEDO = mix(vec3(0.10, 0.32, 0.25), vec3(0.34, 0.58, 0.34), UV.y);
	ROUGHNESS = 0.65;
}
