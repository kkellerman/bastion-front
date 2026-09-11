shader_type spatial;
uniform sampler2D source_color_map : source_color, filter_linear_mipmap;
uniform vec4 uniform_color : source_color;
uniform vec4 gaiter_color : source_color;
uniform bool short_gaiters = false;
// Photographic wool/linen detail for the uniform fabric, the dominant surface area;
// the flat donor texture only ever supplied a solid colour per body region here.
uniform sampler2D fabric_albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D fabric_normal : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D fabric_rough : hint_default_white, filter_linear_mipmap;
uniform float fabric_scale = 26.0;
varying vec3 local;
varying vec3 world;
varying vec3 local_normal;
void vertex() {
	local = VERTEX;
	world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	local_normal = NORMAL;
}
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 p) {
	vec3 i = floor(p); vec3 f = smoothstep(vec3(0),vec3(1),fract(p));
	return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void fragment() {
	vec3 source = texture(source_color_map,UV).rgb;
	bool skin = source.r > source.g*1.3 && source.g > 0.08;
	bool leather = max(source.r,max(source.g,source.b)) < 0.001;
	vec3 base = uniform_color.rgb;
	if (skin) base = vec3(0.37,0.24,0.17)*mix(0.8,1.1,source.r);
	else if (leather) base = vec3(0.027,0.023,0.019);
	if (!skin && local.y < 0.3 && local.y > 0.12 && short_gaiters) base = gaiter_color.rgb;
	float weave = sin(UV.x*1100.0)*sin(UV.y*1100.0);
	float mottling=sin(local.x*71.0+sin(local.y*29.0))*sin(local.z*53.0+local.y*43.0);
	float dirt=(1.0-smoothstep(0.12,0.5,local.y))*0.3;
	ALBEDO = base*(0.90 + weave*0.025+mottling*0.055)*(1.0-dirt);
	ROUGHNESS = skin ? 0.67 : 0.88;
	NORMAL_MAP = normalize(vec3(0.5+mottling*0.05,0.5+weave*0.05,1));
	if (!skin && !leather) {
		// Triplanar so the weave reads correctly on both vertical torso panels and the
		// near-horizontal shoulders/cap, since this mesh has no dedicated cloth UVs.
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
		ALBEDO = toned * base * 2.3 * (1.0-dirt);
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
}
