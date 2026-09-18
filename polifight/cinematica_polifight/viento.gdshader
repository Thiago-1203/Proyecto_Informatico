shader_type canvas_item;
render_mode unshaded;

// Fase proporcionada por GDScript: ciclo repetible y controlable desde el Inspector.
uniform float fase : hint_range(0.0, 1.0) = 0.0;
uniform float fuerza_pixeles : hint_range(0.0, 18.0) = 9.0;
uniform float movimiento_nubes : hint_range(0.0, 48.0) = 28.0;
uniform float bloque_pixel : hint_range(1.0, 4.0) = 2.0;

vec2 pixelar_uv(vec2 uv, vec2 tamano_texel) {
	vec2 bloque = tamano_texel * max(floor(bloque_pixel + 0.5), 1.0);
	vec2 centro_pixel = (floor(uv / bloque) + vec2(0.5)) * bloque;
	vec2 margen = bloque * 0.5;
	return clamp(centro_pixel, margen, vec2(1.0) - margen);
}

// Selección por color, ajustada al fondo incluido: follaje verde/oliva.
// Excluye cielo y ventanas azules, ladrillos y troncos marrones.
float follaje(vec3 c) {
	float verde_sobre_azul = smoothstep(0.015, 0.085, c.g - c.b);
	float verde_sobre_rojo = smoothstep(-0.025, 0.04, c.g - c.r);
	float luminosidad = smoothstep(0.10, 0.26, max(c.r, max(c.g, c.b)));
	return verde_sobre_azul * verde_sobre_rojo * luminosidad;
}

// El cielo se mueve como una capa aunque provenga de la misma imagen.
// La máscara cromática evita desplazar árboles, edificio y calle.
float cielo(vec3 c) {
	float azul = smoothstep(0.055, 0.15, c.b - c.r);
	float nube_clara = smoothstep(0.69, 0.88, dot(c, vec3(0.299, 0.587, 0.114)));
	float tono_frio = smoothstep(-0.035, 0.055, c.b - c.r);
	return max(azul, nube_clara * tono_frio) * (1.0 - follaje(c));
}

void fragment() {
	vec2 uv_base = pixelar_uv(UV, TEXTURE_PIXEL_SIZE);
	vec4 original = texture(TEXTURE, uv_base);
	float t = fase * TAU;

	// Deriva horizontal suave y cíclica de las nubes.
	float deriva_nubes = sin(t) + 0.22 * sin(t * 2.0 + 0.7);
	float desplazamiento_nube_px = round(deriva_nubes * movimiento_nubes);
	vec2 uv_nubes = pixelar_uv(
		uv_base - vec2(desplazamiento_nube_px * TEXTURE_PIXEL_SIZE.x, 0.0),
		TEXTURE_PIXEL_SIZE
	);
	vec4 cielo_movido = texture(TEXTURE, uv_nubes);
	float zona_cielo = 1.0 - smoothstep(0.34, 0.47, uv_base.y);
	// Exigir cielo en origen y destino impide arrastrar copas o techos al desplazarlo.
	float mascara_cielo = min(cielo(original.rgb), cielo(cielo_movido.rgb)) * zona_cielo;
	vec4 color_animado = mix(original, cielo_movido, mascara_cielo);

	// Ráfagas con dos frecuencias. El redondeo mantiene bordes de píxel nítidos.
	float altura_copa = 1.0 - smoothstep(0.58, 0.79, uv_base.y);
	float rafaga = 0.72 + 0.28 * sin(t * 2.0 - 0.65);
	float onda = sin(t + uv_base.y * 10.0 + uv_base.x * 5.0);
	onda += 0.52 * sin(t * 2.0 - uv_base.y * 22.0 + uv_base.x * 13.0);
	onda /= 1.52;
	vec2 viento_px = vec2(
		onda * fuerza_pixeles * rafaga,
		0.30 * sin(t * 2.0 + uv_base.x * 17.0) * fuerza_pixeles
	);
	vec2 desplazamiento_hojas = round(viento_px * altura_copa) * TEXTURE_PIXEL_SIZE;
	vec2 uv_hojas = pixelar_uv(uv_base + desplazamiento_hojas, TEXTURE_PIXEL_SIZE);
	vec4 hojas_movidas = texture(TEXTURE, uv_hojas);

	// Incluir origen y destino permite que también oscile el contorno de las copas.
	float mascara_hojas = max(follaje(original.rgb), follaje(hojas_movidas.rgb)) * altura_copa;
	COLOR = mix(color_animado, hojas_movidas, mascara_hojas);
}
