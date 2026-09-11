shader_type sky;
uniform vec3 sun_direction = vec3(-0.45, 0.53, 0.72);
uniform vec4 horizon_color : source_color = vec4(0.49, 0.55, 0.56, 1.0);
// Avoid amplifying trigonometric rounding into visible cloud-cell boundaries.
float hash(vec2 p) {
 vec3 q = fract(vec3(p.xyx) * 0.1031);
 q += dot(q, q.yzx + 33.33);
 return fract((q.x + q.y) * q.z);
}
float noise(vec2 p) {
 vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
float cloud(vec2 p) {
 return noise(p)*0.5 + noise(p*2.03+7.0)*0.27 + noise(p*4.11-11.0)*0.15 + noise(p*8.21)*0.08;
}
void sky() {
 vec3 d = normalize(EYEDIR);
 // Two fixed cloud decks; no seam, time or operation-seed dependency.
 vec2 p = d.xz / max(0.22, d.y + 0.32) * 2.8;
 float low_deck = cloud(p + vec2(21.0, 9.0));
 float upper = cloud(p * vec2(0.5, 1.8) + vec2(8.0));
 float glow = pow(max(dot(d, sun_direction),0.0),9.0);
 float relief = cloud(p + sun_direction.xz * 0.25 + vec2(21.0,9.0)) - low_deck;
 vec3 cloud_tone = mix(vec3(0.31,0.37,0.42),vec3(0.72,0.76,0.77),clamp(low_deck*0.85+relief*2.0,0.0,1.0));
 vec3 upper_tone = mix(vec3(0.36,0.44,0.51),vec3(0.66,0.71,0.74),upper);
 COLOR = mix(upper_tone, cloud_tone, smoothstep(0.25,0.65,low_deck));
 COLOR += vec3(0.14,0.13,0.10) * glow * (1.0-low_deck*0.6);
 COLOR = mix(COLOR,horizon_color.rgb,pow(1.0-max(d.y,0.0),5.0)*0.75);
 if (d.y < 0.0) COLOR = mix(horizon_color.rgb,vec3(0.12,0.15,0.13),smoothstep(0.0,0.25,-d.y));
}
