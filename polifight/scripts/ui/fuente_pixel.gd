extends RefCounted
## Tipografía vectorial compartida. Conserva la escala de las escenas existentes.

const ALTO_GLIFO: int = 7
static var fuente: FontFile = _crear_fuente()


static func _crear_fuente() -> FontFile:
	var archivo: FontFile = preload("res://assets/fonts/DejaVuSans-Bold.ttf")
	# MSDF mantiene los contornos suaves al escalar el lienzo de 1920 x 1080.
	archivo.multichannel_signed_distance_field = true
	return archivo


static func tamano_fuente(escala: int) -> int:
	return escala * 9


static func calcular_ancho(contenido: String, escala: int) -> int:
	return ceili(fuente.get_string_size(contenido, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano_fuente(escala)).x)


static func dibujar_texto(lienzo: CanvasItem, contenido: String, origen: Vector2, escala: int, color: Color) -> void:
	var tamano := tamano_fuente(escala)
	var linea_base := origen + Vector2(0, (ALTO_GLIFO * escala + fuente.get_ascent(tamano) - fuente.get_descent(tamano)) * 0.5)
	lienzo.draw_string(fuente, linea_base, contenido, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, color)
