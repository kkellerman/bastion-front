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
	float clouds = noise(p+vec2(2,3))*0.50 + noise(p*2.1)*0.25 + noise(p*4.3)*0.13 + noise(p*8.7)*0.08+noise(p*17.4)*0.04;
	float horizon = pow(1.0-max(d.y,0.0),3.0);
	vec3 sky_color = mix(vec3(0.20,0.34,0.50),vec3(0.61,0.68,0.72),horizon);
	float lit_edge = clamp((noise(p+vec2(0.14,0.08))-noise(p))*3.0+0.5,0.0,1.0);
	vec3 cloud_color = mix(vec3(0.31,0.36,0.41),vec3(0.91,0.90,0.84),lit_edge);
	float upper_veil = noise(p*vec2(0.35,3.5)+vec2(8.0))*0.16;
	COLOR = mix(sky_color,cloud_color,clamp(smoothstep(0.36,0.62,clouds)+upper_veil,0.0,1.0));
	float sun = pow(max(dot(d,normalize(vec3(0.45,0.53,0.7))),0.0),20.0);
	COLOR += vec3(0.13,0.12,0.09)*sun*(1.0-clouds);
	if (d.y < 0.0) COLOR = mix(COLOR,vec3(0.13,0.15,0.13),min(-d.y*5.0,1.0));
}
