shader_type sky;
render_mode use_half_res_pass;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void sky() {
	vec3 d = normalize(EYEDIR);
	vec2 p = d.xz / max(0.16, d.y + 0.22) * 2.2;
	float clouds = noise(p)*0.55 + noise(p*2.1)*0.26 + noise(p*4.3)*0.13 + noise(p*8.7)*0.06;
	float horizon = pow(1.0-max(d.y,0.0),3.0);
	vec3 sky_color = mix(vec3(0.29,0.36,0.43),vec3(0.61,0.65,0.66),horizon);
	vec3 cloud_color = mix(vec3(0.26,0.30,0.33),vec3(0.67,0.68,0.65),clouds);
	COLOR = mix(sky_color,cloud_color,smoothstep(0.26,0.66,clouds)*0.9);
	float sun = pow(max(dot(d,normalize(vec3(0.45,0.53,0.7))),0.0),20.0);
	COLOR += vec3(0.13,0.12,0.09)*sun*(1.0-clouds);
	if (d.y < 0.0) COLOR = mix(COLOR,vec3(0.13,0.15,0.13),min(-d.y*5.0,1.0));
}
