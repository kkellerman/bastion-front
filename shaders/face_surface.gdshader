shader_type spatial;

uniform vec3 skin_tone : source_color = vec3(0.49, 0.355, 0.265);
uniform float eye_height = 1.646;
uniform float mouth_height = 1.584;
uniform float stubble_strength : hint_range(0.0, 0.5) = 0.18;
uniform float freckle_strength : hint_range(0.0, 0.3) = 0.1;

varying vec3 local;

void vertex() { local = VERTEX; }

float spot(vec2 p, vec2 c, vec2 r) {
	vec2 d = (p - c) / r;
	return exp(-dot(d, d));
}

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float fbm(vec3 p) {
	vec3 i = floor(p);
	vec3 f = smoothstep(vec3(0.0), vec3(1.0), fract(p));
	return mix(
		mix(mix(hash3(i), hash3(i + vec3(1,0,0)), f.x), mix(hash3(i + vec3(0,1,0)), hash3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash3(i + vec3(0,0,1)), hash3(i + vec3(1,0,1)), f.x), mix(hash3(i + vec3(0,1,1)), hash3(i + vec3(1,1,1)), f.x), f.y),
		f.z
	);
}

void fragment() {
	vec2 mirrored = vec2(abs(local.x), local.y);
	float front = 1.0 - smoothstep(-0.045, -0.018, local.z);
	float sockets = spot(mirrored, vec2(0.032, eye_height), vec2(0.023, 0.014)) * front;
	float brows = spot(mirrored, vec2(0.032, eye_height + 0.016), vec2(0.020, 0.0035)) * front;
	float lips = spot(mirrored, vec2(0.0, mouth_height), vec2(0.023, 0.0045)) * front;
	float mouth = spot(mirrored, vec2(0.0, mouth_height), vec2(0.015, 0.0007)) * front;
	float mouth_corners = spot(mirrored, vec2(0.021, mouth_height - 0.0005), vec2(0.004, 0.0022)) * front;
	float nostrils = spot(mirrored, vec2(0.013, 1.598), vec2(0.0042, 0.0017)) * front;
	float beard_mask = (1.0 - smoothstep(1.570, 1.620, local.y)) * front;
	float pores = hash3(floor(local * 1850.0));
	float freckles = smoothstep(0.91, 0.99, hash3(floor(local * 520.0) + vec3(13.0, 7.0, 3.0))) * front;

	vec3 skin = skin_tone * (0.94 + pores * 0.10);
	skin *= 1.0 - sockets * 0.10 - beard_mask * stubble_strength;
	skin = mix(skin, vec3(0.17, 0.055, 0.040), lips * 0.15);
	skin = mix(skin, vec3(0.045, 0.030, 0.022), brows * 0.30);
	skin = mix(skin, vec3(0.15, 0.075, 0.050), clamp(mouth * 0.17 + mouth_corners * 0.12 + nostrils * 0.20, 0.0, 1.0));
	skin *= 1.0 - freckles * freckle_strength;
	ALBEDO = skin;
	ROUGHNESS = mix(0.72, 0.57, sockets + lips * 0.25);

	float coarse = fbm(local * 145.0);
	float fine = fbm(local * 540.0);
	NORMAL_MAP = vec3(
		0.5 + (coarse - 0.5) * 0.022 + (fine - 0.5) * 0.010,
		0.5 + (fbm(local * 145.0 + 17.0) - 0.5) * 0.022 + (fbm(local * 540.0 + 31.0) - 0.5) * 0.010,
		1.0
	);
}
