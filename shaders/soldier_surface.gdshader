shader_type spatial;
uniform sampler2D source_color_map : source_color, filter_linear_mipmap;
uniform vec4 uniform_color : source_color;
uniform vec4 gaiter_color : source_color;
uniform bool short_gaiters = false;
varying vec3 local;
void vertex() { local = VERTEX; }
void fragment() {
	vec3 source = texture(source_color_map,UV).rgb;
	bool skin = source.r > source.g*1.3 && source.g > 0.08;
	bool leather = max(source.r,max(source.g,source.b)) < 0.001;
	vec3 base = uniform_color.rgb;
	if (skin) base = vec3(0.37,0.24,0.17)*mix(0.8,1.1,source.r);
	else if (leather) base = vec3(0.027,0.023,0.019);
	if (!skin && local.y < 0.3 && local.y > 0.12 && short_gaiters) base = gaiter_color.rgb;
	float weave = sin(UV.x*1100.0)*sin(UV.y*1100.0);
	ALBEDO = base*(0.94 + weave*0.04);
	ROUGHNESS = skin ? 0.67 : 0.88;
}
