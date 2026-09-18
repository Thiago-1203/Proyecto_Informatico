shader_type canvas_item;
render_mode unshaded;

uniform sampler2D textura_nubes : source_color, filter_nearest, repeat_enable;
uniform sampler2D mascara_cielo : filter_nearest, repeat_disable;
uniform float desplazamiento_px = 0.0;
uniform float ancho_textura = 640.0;

void fragment() {
	vec4 fondo = texture(TEXTURE, UV);
	vec2 uv_nubes = vec2(fract(UV.x - desplazamiento_px / ancho_textura), UV.y);
	vec4 nube = texture(textura_nubes, uv_nubes);
	float puede_mostrar_nube = texture(mascara_cielo, UV).r * nube.a;
	COLOR = vec4(mix(fondo.rgb, nube.rgb, puede_mostrar_nube), fondo.a);
}
