shader_type spatial;
render_mode cull_disabled;
uniform float wind_strength = 0.035;
void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.x += sin(TIME * 1.1 + world.x * 0.7 + world.z * 0.35) * wind_strength * min(VERTEX.y, 2.0);
}
void fragment() {
	ALBEDO = COLOR.rgb * 0.35;
	ROUGHNESS = 0.82;
	BACKLIGHT = COLOR.rgb * 0.08;
}
