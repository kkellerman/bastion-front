shader_type spatial;
uniform vec4 cloth_color : source_color = vec4(0.25,0.28,0.23,1.0);
// Same CC0 linen set used on the torso in soldier_surface.gdshader; the sleeves are a
// separate mesh built here and previously kept the fully procedural weave/wear look
// after that change, so the arms still read flat next to the now-textured torso.
uniform sampler2D fabric_albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D fabric_normal : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D fabric_rough : hint_default_white, filter_linear_mipmap;
uniform float fabric_scale = 26.0;
varying vec3 local;
varying vec3 local_normal;
void vertex() { local = VERTEX; local_normal = NORMAL; }
float hash(vec3 p) { return fract(sin(dot(p,vec3(12.9898,78.233,34.12)))*43758.5453); }
void fragment() {
	float wear = hash(floor(local*50.0));
	float damp = smoothstep(0.45,0.05,local.y);
	vec3 blend = pow(abs(normalize(local_normal)), vec3(4.0));
	blend /= max(blend.x + blend.y + blend.z, 0.0001);
	vec2 uv_x = local.zy * fabric_scale;
	vec2 uv_y = local.xz * fabric_scale;
	vec2 uv_z = local.xy * fabric_scale;
	vec3 cloth = texture(fabric_albedo,uv_x).rgb * blend.x
		+ texture(fabric_albedo,uv_y).rgb * blend.y
		+ texture(fabric_albedo,uv_z).rgb * blend.z;
	float luma = dot(cloth, vec3(0.299,0.587,0.114));
	vec3 toned = mix(vec3(luma), cloth, 0.35);
	ALBEDO = toned * cloth_color.rgb * 2.3 * (0.92+wear*0.1) * (1.0-damp*0.22);
	vec3 cloth_normal = texture(fabric_normal,uv_x).rgb * blend.x
		+ texture(fabric_normal,uv_y).rgb * blend.y
		+ texture(fabric_normal,uv_z).rgb * blend.z;
	NORMAL_MAP = cloth_normal;
	NORMAL_MAP_DEPTH = 0.5;
	float rough_sample = texture(fabric_rough,uv_x).r * blend.x
		+ texture(fabric_rough,uv_y).r * blend.y
		+ texture(fabric_rough,uv_z).r * blend.z;
	ROUGHNESS = clamp(rough_sample + 0.15, 0.5, 1.0);
}
