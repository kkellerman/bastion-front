shader_type spatial;
uniform sampler2D ground_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ground_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ground_rough : filter_linear_mipmap, repeat_enable;
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 uv = world.xz * 0.32;
	float edge = 2.3 + sin(world.z * 0.7) * 0.2 + sin(world.z * 2.1) * 0.12;
	float trail = 1.0 - smoothstep(edge - 0.3, edge + 0.4, abs(world.x));
	float rut_center = 1.25 + sin(world.z*0.31)*0.08;
	float rut = exp(-pow((abs(world.x) - rut_center) * 5.0, 2.0)) * trail;
	float tread = smoothstep(0.50,0.68,sin(world.z*22.0+world.x*6.0))*rut;
	vec3 soil = texture(ground_color, uv).rgb;
	float moss = smoothstep(0.15,0.8,sin(world.x*0.52+sin(world.z*0.18))*sin(world.z*0.4))* (1.0-trail);
	soil = mix(soil,soil*vec3(0.58,0.72,0.40),moss*0.45);
	ALBEDO = soil * mix(vec3(0.58, 0.61, 0.48), vec3(0.38, 0.31, 0.23), trail) * (1.0 - rut * 0.30-tread*0.12);
	ROUGHNESS = mix(texture(ground_rough, uv).r, 0.21, rut * 0.72);
	NORMAL_MAP = texture(ground_normal, uv).rgb;
	NORMAL_MAP_DEPTH = 0.65;
}
