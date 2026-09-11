shader_type canvas_item;
uniform float strength = 0.0;
void fragment() {
	float edge = smoothstep(0.25, 0.72, length(UV - vec2(0.5)));
	COLOR = vec4(0.24, 0.075, 0.045, edge * strength);
}
