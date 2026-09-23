shader_type spatial;
varying vec3 local;
void vertex() { local = VERTEX; }
float spot(vec2 p, vec2 c, vec2 r) { vec2 d=(p-c)/r; return exp(-dot(d,d)); }
float hash2(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float fbm(vec3 p) {
	// Two octaves of value noise: a coarse pass for soft cheek/forehead undulation,
	// a fine pass for pore-scale grain. The previous normal map varied by 0.015 in a
	// single axis, which is invisible under most lighting; skin needs real relief.
	vec3 i = floor(p); vec3 f = smoothstep(vec3(0),vec3(1),fract(p));
	return mix(mix(mix(hash2(i),hash2(i+vec3(1,0,0)),f.x),mix(hash2(i+vec3(0,1,0)),hash2(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash2(i+vec3(0,0,1)),hash2(i+vec3(1,0,1)),f.x),mix(hash2(i+vec3(0,1,1)),hash2(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void fragment() {
	vec2 p=vec2(abs(local.x),local.y);
	float front=1.0-smoothstep(-0.045,-0.02,local.z);
	float sockets=spot(p,vec2(0.031,1.646),vec2(0.020,0.012))*front;
	float eyes=spot(p,vec2(0.031,1.646),vec2(0.010,0.0035))*front;
	float iris=spot(p,vec2(0.031,1.646),vec2(0.003,0.003))*front;
	float brows=spot(p,vec2(0.032,1.657),vec2(0.018,0.003))*front;
	float lips=spot(p,vec2(0.0,1.585),vec2(0.022,0.004))*front;
	float mouth=spot(p,vec2(0.0,1.585),vec2(0.020,0.0009))*front;
	float stubble=(1.0-smoothstep(1.575,1.617,local.y))*front;
	float pores=fract(sin(dot(floor(local*1800.0),vec3(12.1,67.7,32.3)))*43758.5);
	// Shader literals are linear; match the sRGB hand material after conversion.
	vec3 skin=vec3(0.17,0.085,0.052)*(0.96+pores*0.08);
	skin*=1.0-sockets*0.24-stubble*0.15;
	skin=mix(skin,vec3(0.38,0.32,0.26),eyes*0.7);
	skin=mix(skin,vec3(0.045,0.035,0.025),clamp(iris*0.8+brows*0.7+mouth*0.6,0.,1.));
	skin=mix(skin,vec3(0.12,0.042,0.029),lips*0.35);
	ALBEDO=skin;
	ROUGHNESS=0.64;
	float coarse = fbm(local*140.0);
	float fine = fbm(local*520.0);
	NORMAL_MAP=vec3(0.5+(coarse-0.5)*0.025+(fine-0.5)*0.012,0.5+(fbm(local*140.0+17.0)-0.5)*0.025+(fbm(local*520.0+31.0)-0.5)*0.012,1.0);
}
