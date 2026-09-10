shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, blend_add;
void fragment() {
	vec2 point = UV * 2.0 - 1.0;
	float radius = length(point);
	float angle = atan(point.y, point.x);
	float rays = pow(abs(cos(angle * 3.0)), 8.0);
	float glow = exp(-radius * 7.0) + rays * exp(-radius * 3.5) * 0.7;
	ALBEDO = vec3(1.0, 0.55, 0.12);
	EMISSION = vec3(1.0, 0.68, 0.28) * glow * 3.0;
	ALPHA = glow * smoothstep(1.0, 0.7, radius);
}
