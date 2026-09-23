shader_type spatial;

uniform vec3 hair_color : source_color = vec3(0.06, 0.034, 0.02);
varying vec3 local;

void vertex() {
	local = VERTEX;
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float coarse = hash2(floor(local.xz * 430.0));
	float strands = sin(local.y * 920.0 + local.x * 1850.0 + coarse * 6.2831) * 0.5 + 0.5;
	float variation = 0.78 + coarse * 0.13 + strands * 0.09;
	ALBEDO = hair_color * variation;
	ROUGHNESS = 0.86;
	NORMAL_MAP = vec3(0.5 + (strands - 0.5) * 0.035, 0.5 + (coarse - 0.5) * 0.018, 1.0);
}
