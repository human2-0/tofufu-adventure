shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D surfaces : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
varying vec3 world_at;
varying vec3 world_normal;
varying float path_mask;
float hash(vec3 p) { p=fract(p*0.1031); p+=dot(p,p.yzx+33.33); return fract((p.x+p.y)*p.z); }
float noise(vec3 p) {
 vec3 i=floor(p); vec3 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
vec3 tile(vec2 uv, vec2 cell) {
 vec2 mirrored=1.0-abs(mod(uv,2.0)-1.0);
 return texture(surfaces,cell*0.5+vec2(0.002)+mirrored*0.496).rgb;
}
void vertex() {
 world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
 path_mask=COLOR.a;
}
void fragment() {
 float mottles=noise(world_at*0.16);
 float stone=clamp((1.0-world_normal.y)*3.0+smoothstep(38.0,66.0,world_at.y)*0.45,0.0,1.0);
 vec3 weights=pow(abs(world_normal),vec3(4.0));
 weights/=max(dot(weights,vec3(1.0)),0.001);
 vec3 rock=tile(world_at.zy*0.17,vec2(0))*weights.x;
 rock+=tile(world_at.xz*0.17,vec2(0))*weights.y;
 rock+=tile(world_at.xy*0.17,vec2(0))*weights.z;
 vec3 moss=tile(world_at.xz*0.35,vec2(1,0))*(0.82+mottles*0.32);
 vec3 gravel=tile(world_at.xz*0.48,vec2(0,1));
 vec3 ground=mix(moss,rock,stone);
 ground=mix(ground,gravel,smoothstep(0.15,0.9,path_mask));
 if(world_at.x < -850.0 && abs(world_at.z)<55.0) {
  vec2 paving=abs(fract(world_at.xz/vec2(2.0,1.4))-0.5);
  ground=mix(vec3(0.35,0.33,0.28),vec3(0.55,0.48,0.36),step(max(paving.x,paving.y),0.47))*(0.92+0.1*mottles);
 }
 float edge = min(min(world_at.x + 980.0, -110.0 - world_at.x), 180.0 - abs(world_at.z));
 ALBEDO=mix(COLOR.rgb, ground*(0.92+mottles*0.16), smoothstep(0.0, 32.0, edge));
 ROUGHNESS=0.92;
 AO=0.9+dot(ground,vec3(0.04));
}
