shader_type spatial;
uniform vec4 cloth_color : source_color = vec4(0.25,0.28,0.23,1.0);
varying vec3 local;
void vertex() { local = VERTEX; }
float hash(vec3 p) { return fract(sin(dot(p,vec3(12.9898,78.233,34.12)))*43758.5453); }
void fragment() {
	float weave = sin(UV.x*850.0)*sin(UV.y*850.0);
	float wear = hash(floor(local*50.0));
	float damp = smoothstep(0.45,0.05,local.y);
	ALBEDO = cloth_color.rgb*(0.83+wear*0.16+weave*0.035)*(1.0-damp*0.22);
	ROUGHNESS = 0.89;
	NORMAL_MAP = vec3(0.5+weave*0.04,0.5+weave*0.04,1.0);
	NORMAL_MAP_DEPTH = 0.2;
}
