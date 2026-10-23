shader_type canvas_item;
render_mode unshaded;

uniform float intensidad : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// Mantiene el centro del escenario visible y reserva contraste para la interfaz.
	float bordes = pow(abs(UV.x - 0.5) * 2.0, 1.5);
	float superior = 1.0 - smoothstep(0.0, 0.38, UV.y);
	float inferior = smoothstep(0.48, 1.0, UV.y);
	float sombra = max(superior * 0.86, inferior * 0.96);
	sombra = max(sombra, bordes * 0.64);
	COLOR = vec4(vec3(0.008, 0.025, 0.055), sombra * intensidad);
}
