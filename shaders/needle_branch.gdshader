shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform sampler2D branch_atlas : source_color, filter_linear_mipmap_anisotropic;
varying float shade;
void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	VERTEX.x += sin(TIME*0.8+world.x*0.6+world.z*0.3)*0.025*(1.0-UV.y);
	shade = COLOR.r;
}
void fragment() {
	vec4 branch = texture(branch_atlas,UV);
	ALBEDO = branch.rgb * mix(0.75,1.15,shade);
	ALPHA = branch.a;
	ALPHA_SCISSOR_THRESHOLD = 0.32;
	ROUGHNESS = 0.82;
	BACKLIGHT = branch.rgb * 0.12;
}
