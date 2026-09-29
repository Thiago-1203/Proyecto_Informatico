shader_type canvas_item;
render_mode unshaded;

uniform vec4 color_destello : source_color = vec4(1.0);
uniform float intensidad_destello : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 color_original = COLOR;
	vec3 color_final = mix(
		color_original.rgb,
		color_destello.rgb,
		intensidad_destello
	);
	COLOR = vec4(color_final, color_original.a);
}
