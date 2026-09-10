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
	float rut = exp(-pow((abs(world.x) - 1.25) * 4.0, 2.0)) * trail;
	vec3 soil = texture(ground_color, uv).rgb;
	ALBEDO = soil * mix(vec3(0.58, 0.61, 0.48), vec3(0.3, 0.31, 0.25), trail) * (1.0 - rut * 0.25);
	ROUGHNESS = mix(texture(ground_rough, uv).r, 0.26, rut * 0.65);
	NORMAL_MAP = texture(ground_normal, uv).rgb;
	NORMAL_MAP_DEPTH = 0.65;
}
