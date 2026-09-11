shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform sampler2D plant_atlas : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D plant_normal : hint_normal, filter_linear_mipmap;
uniform vec3 tint = vec3(0.72, 0.8, 0.62);
uniform float wind_strength = 0.045;
varying float exposure;
void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	// Sway scales with height up the card so the rooted base stays planted.
	VERTEX.x += sin(TIME*1.1+world.x*0.7+world.z*0.35)*wind_strength*(1.0-UV.y);
	exposure = COLOR.r;
}
void fragment() {
	// Cutout is packed into the atlas alpha by tools/pack_foliage_atlases.gd.
	vec4 plant = texture(plant_atlas,UV);
	ALBEDO = plant.rgb * tint * mix(0.55, 1.1, exposure);
	ALPHA = plant.a;
	ALPHA_SCISSOR_THRESHOLD = 0.45;
	NORMAL_MAP = texture(plant_normal,UV).rgb;
	NORMAL_MAP_DEPTH = 0.6;
	ROUGHNESS = 0.86;
	BACKLIGHT = plant.rgb * tint * 0.14;
}
