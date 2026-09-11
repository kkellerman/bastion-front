shader_type spatial;
uniform sampler2D ground_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ground_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ground_rough : filter_linear_mipmap, repeat_enable;
uniform float trail_strength = 1.0;
uniform bool rear_trail = false;
varying vec3 world;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=smoothstep(vec2(0),vec2(1),fract(p));
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 vec2 uv = world.xz * 0.32;
 float patch = noise(world.xz*0.18);
 float fine = noise(world.xz*2.7);
 float center = rear_trail ? pow(max(0.0,-world.z-87.0)*0.12,1.6) : 0.0;
 float edge = (rear_trail ? 1.25 : 2.25) + (noise(vec2(world.z*0.36,7.0))-0.5)*0.9;
 float trail = (1.0-smoothstep(edge-0.25,edge+0.55,abs(world.x-center))) * trail_strength;
 if (rear_trail) trail *= (1.0-smoothstep(-87.0,-85.0,world.z))*smoothstep(-119.0,-114.0,world.z);
 float rut_center = 1.25 + sin(world.z*0.31)*0.08;
 float rut = exp(-pow((abs(world.x-center)-rut_center)*5.0,2.0))*trail;
 vec3 primary = texture(ground_color,uv).rgb;
 vec3 secondary = texture(ground_color,uv*0.73+vec2(0.31,0.67)).rgb;
 vec3 soil = mix(primary,secondary,smoothstep(0.23,0.77,patch));
 float moss = smoothstep(0.52,0.75,patch)*(1.0-trail);
 float gravel = smoothstep(0.44,0.66,fine)*trail*(1.0-rut);
 soil = mix(soil,soil*vec3(0.59,0.77,0.39),moss*0.6);
 ALBEDO = soil*mix(vec3(0.64,0.65,0.52),vec3(0.46,0.39,0.29),trail)*(0.86+patch*0.25-rut*0.19);
 ALBEDO = mix(ALBEDO,secondary*vec3(0.55,0.54,0.48),gravel*0.35);
 ROUGHNESS = clamp(mix(texture(ground_rough,uv).r,0.35,rut*0.65) - patch*0.08,0.3,1.0);
 vec3 normal = texture(ground_normal,uv).rgb;
 vec3 detail = texture(ground_normal,uv*3.1).rgb;
 NORMAL_MAP = vec3(clamp(normal.xy+(detail.xy-0.5)*0.28,vec2(0),vec2(1)),normal.z);
 NORMAL_MAP_DEPTH = 0.75;
}
