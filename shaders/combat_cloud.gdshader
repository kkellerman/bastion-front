shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(0.25, 0.23, 0.20, 0.6);
uniform bool fire = false;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i), hash(i+vec2(1,0)), f.x), mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), f.x), f.y);
}
void vertex() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0]*scale.x, INV_VIEW_MATRIX[1]*scale.y, INV_VIEW_MATRIX[2]*scale.z, MODEL_MATRIX[3]);
}
void fragment() {
	float n = noise(UV*7.0)*0.65 + noise(UV*17.0)*0.35;
	float edge = smoothstep(0.5, 0.12, length(UV-vec2(0.5)) + (n-0.5)*0.17);
	ALBEDO = tint.rgb * (0.65 + n*0.6);
	ALPHA = tint.a * COLOR.a * edge * (0.4+n*0.6);
	if (fire) EMISSION = vec3(1.0, 0.38, 0.07)*edge*(0.7+n);
}
