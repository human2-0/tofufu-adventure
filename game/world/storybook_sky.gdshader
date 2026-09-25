shader_type sky;
render_mode use_quarter_res_pass;

uniform vec3 zenith : source_color = vec3(0.45, 0.72, 0.85);
uniform vec3 horizon : source_color = vec3(1.0, 0.86, 0.72);
uniform vec3 cloud_light : source_color = vec3(1.0);
uniform vec3 cloud_shadow : source_color = vec3(0.65, 0.76, 0.83);
uniform float cover = 0.0;
uniform float night = 0.0;
uniform float clock = 0.0;
uniform float flash = 0.0;
uniform float strike_offset = -0.36;
uniform vec3 sun_direction = vec3(0.0, 0.4, -0.9);

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.37, 0.71));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}
float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x),
		mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
		mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void sky() {
	vec3 d = normalize(EYEDIR);
	float height = max(d.y, 0.0);
	vec3 color = mix(horizon, zenith, pow(height, 0.55));
	float sun_dot = dot(d, sun_direction);
	color += vec3(1.0, 0.68, 0.36) * pow(max(sun_dot, 0.0), 24.0) * (1.0 - cover) * 0.25;
	color = mix(color, vec3(1.0, 0.91, 0.69), smoothstep(0.9985, 0.9992, sun_dot) * (1.0 - night));
	float moon = smoothstep(0.9990, 0.9995, dot(d, normalize(vec3(-0.45, 0.42, -0.78))));
	color = mix(color, vec3(0.94, 0.94, 0.77), moon * night);
	vec3 stars = d * 210.0;
	float star = pow(max(0.0, 1.0 - length(fract(stars) - 0.5) * 2.0), 10.0);
	color += vec3(0.85, 0.96, 0.77) * star * step(0.965, hash(floor(stars))) * night * smoothstep(0.0, 0.2, height);
	vec3 p = d * vec3(6.0, 11.0, 6.0) + vec3(clock * 0.008, 0.0, clock * 0.004);
	float billow = noise(p) * 0.65 + noise(p * 2.1) * 0.25 + noise(p * 4.2) * 0.1;
	float threshold = mix(0.58, 0.27, cover);
	float clouds = smoothstep(threshold, threshold + 0.14, billow) * smoothstep(-0.04, 0.14, d.y);
	vec3 cloud_color = mix(cloud_shadow, cloud_light, smoothstep(0.35, 0.78, billow) * 0.75 + height * 0.25);
	color = mix(color, cloud_color, clouds * 0.96);
	// Distant forked lightning sits behind the storm's cloud bank.
	float segment = d.y * 32.0;
	float jag = mix(hash(vec3(floor(segment), 2.0, 7.0)), hash(vec3(floor(segment) + 1.0, 2.0, 7.0)), fract(segment));
	float bolt_x = strike_offset + 0.065 * (jag - 0.5) + d.y * 0.12;
	float bolt = (1.0 - smoothstep(0.001, 0.004, abs(d.x - bolt_x))) * step(0.04, d.y) * step(d.y, 0.36) * step(d.z, -0.2);
	float branch = (1.0 - smoothstep(0.001, 0.003, abs(d.x - bolt_x - (0.22 - d.y) * 0.55))) * step(0.12, d.y) * step(d.y, 0.22) * step(d.z, -0.2);
	bolt = max(bolt, branch * 0.6);
	color += flash * (vec3(0.22, 0.25, 0.33) * clouds + vec3(0.65, 0.72, 0.85) * bolt);
	COLOR = color;
}
