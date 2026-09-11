shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform sampler2D branch_atlas : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D branch_normal : hint_normal, filter_linear_mipmap;
uniform vec3 tint = vec3(0.78, 0.84, 0.72);
varying float exposure;
void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	VERTEX.x += sin(TIME*0.8+world.x*0.6+world.z*0.3)*0.025*(1.0-UV.y);
	exposure = COLOR.r;
}
void fragment() {
	// Cutout is packed into the atlas alpha (tools/pack_twig_atlas.gd) and roughness is
	// constant: canopy cards are the scene's most overdrawn surface, so every extra
	// texture fetch here is paid once per overlapping layer per pixel.
	vec4 branch = texture(branch_atlas,UV);
	// Cards deep in the crown receive less sky light; approximates canopy occlusion
	// that no lightmap or SSAO pass would otherwise capture on alpha-scissored cards.
	ALBEDO = branch.rgb * tint * mix(0.42, 1.12, exposure);
	ALPHA = branch.a;
	ALPHA_SCISSOR_THRESHOLD = 0.45;
	NORMAL_MAP = texture(branch_normal,UV).rgb;
	NORMAL_MAP_DEPTH = 0.7;
	ROUGHNESS = 0.82;
	BACKLIGHT = branch.rgb * tint * 0.16 * exposure;
}
