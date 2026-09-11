shader_type spatial;
uniform vec4 base_color : source_color = vec4(0.2,0.22,0.2,1);
uniform float metal = 0.0;
uniform bool wood = false;
varying vec3 local;
void vertex() { local = VERTEX; }
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 p) {
	vec3 i = floor(p); vec3 f = smoothstep(vec3(0),vec3(1),fract(p));
	return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void fragment() {
	float patina = noise(local*160.0);
	float broad = noise(local*17.0);
	float grain = sin(local.x*430.0 + noise(local*vec3(30,8,15))*8.0);
	ALBEDO = base_color.rgb*(0.72+patina*0.22+broad*0.16);
	if (wood) ALBEDO *= 0.88 + grain*0.12;
	METALLIC = metal;
	ROUGHNESS = wood ? 0.64+broad*0.18 : mix(0.86,0.43,metal)+patina*0.14;
	NORMAL_MAP = vec3(0.5+(patina-0.5)*0.06,0.5+(broad-0.5)*0.06,1);
}
