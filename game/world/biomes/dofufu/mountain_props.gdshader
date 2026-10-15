shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D surfaces : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform int tile = 0;
varying vec3 world_at;
varying vec3 normal_at;
vec3 sample_tile(vec2 uv) {
 vec2 mirrored = 1.0 - abs(mod(uv, 2.0) - 1.0);
 vec2 cell = vec2(float(tile % 2), float(tile / 2)) * 0.5;
 return texture(surfaces, cell + vec2(0.002) + mirrored * 0.496).rgb;
}
void vertex() {
 world_at = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
 normal_at = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
 vec3 weights = pow(abs(normal_at), vec3(4.0));
 weights /= max(dot(weights, vec3(1.0)), 0.001);
 vec3 color = sample_tile(world_at.zy * 0.32) * weights.x;
 color += sample_tile(world_at.xz * 0.32) * weights.y;
 color += sample_tile(world_at.xy * 0.32) * weights.z;
 ALBEDO = color;
 ROUGHNESS = 0.92;
 AO = 0.85 + dot(color, vec3(0.05));
}
