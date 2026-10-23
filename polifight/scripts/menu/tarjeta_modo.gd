extends Control
## Ilustración independiente y texto editable; el marco responde al foco del carrusel.

const FUENTE_PIXEL = preload("res://scripts/ui/fuente_pixel.gd")
const AZUL := Color("52b8ff")
const DORADO := Color("ffb80d")

@export var ilustracion: Texture2D
@export var titulo: String = "1 VS 1"
@export var subtitulo: String = "DUELO LOCAL"
@export var descripcion: String = "DOS JUGADORES. UN SOLO GANADOR."
var seleccionado: bool = false:
	set(valor):
		seleccionado = valor
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)


func _draw() -> void:
	var borde := DORADO if seleccionado else AZUL
	_marco(Rect2(8, 12, 640, 520), 16, Color(0.01, 0.02, 0.05, 0.8))
	_marco(Rect2(0, 0, 640, 520), 16, Color("020711"))
	_marco(Rect2(5, 5, 630, 510), 14, borde.darkened(0.45))
	_marco(Rect2(9, 9, 622, 502), 12, borde)
	_marco(Rect2(15, 15, 610, 490), 9, Color("061225"))
	if ilustracion != null:
		var espacio := Rect2(21, 21, 598, 310)
		var factor := minf(espacio.size.x / ilustracion.get_width(), espacio.size.y / ilustracion.get_height())
		var tamano := ilustracion.get_size() * factor
		var origen := (espacio.position + (espacio.size - tamano) * 0.5).floor()
		draw_texture_rect(ilustracion, Rect2(origen, tamano.floor()), false)
	draw_rect(Rect2(24, 335, 592, 3), borde.darkened(0.45))
	var pixel_titulo := 11 if titulo.length() < 8 else 8
	_texto(titulo, 350, pixel_titulo, Color("fff2d5"))
	if "VS" in titulo:
		var ancho := FUENTE_PIXEL.calcular_ancho(titulo, pixel_titulo)
		var inicio_vs := Vector2(floorf((640.0 - ancho) * 0.5) + titulo.find("VS") * 6 * pixel_titulo, 350)
		_glifos_gruesos("VS", inicio_vs, pixel_titulo, DORADO if seleccionado else AZUL)
	draw_rect(Rect2(62, 433, 516, 36), AZUL)
	_texto(subtitulo, 440, 3, Color("031020"))
	if seleccionado:
		_texto(descripcion, 482, 3 if titulo == "1 VS 1" else 2, Color("dceaff"))
	if seleccionado:
		for esquina in [Vector2(4, 4), Vector2(608, 4), Vector2(4, 492), Vector2(608, 492)]:
			draw_rect(Rect2(esquina, Vector2(28, 8)), Color("ff5a05"))
			draw_rect(Rect2(esquina + Vector2(8, 0), Vector2(12, 12)), Color("ffe173"))


func _marco(rectangulo: Rect2, corte: float, color: Color) -> void:
	var a := rectangulo.position
	var b := rectangulo.end
	draw_colored_polygon(PackedVector2Array([
		Vector2(a.x + corte, a.y), Vector2(b.x - corte, a.y),
		Vector2(b.x - corte, a.y + corte), Vector2(b.x, a.y + corte),
		Vector2(b.x, b.y - corte), Vector2(b.x - corte, b.y - corte),
		Vector2(b.x - corte, b.y), Vector2(a.x + corte, b.y),
		Vector2(a.x + corte, b.y - corte), Vector2(a.x, b.y - corte),
		Vector2(a.x, a.y + corte), Vector2(a.x + corte, a.y + corte),
	]), color)


func _texto(contenido: String, y: float, pixel: int, color: Color) -> void:
	var ancho := FUENTE_PIXEL.calcular_ancho(contenido, pixel)
	var origen := Vector2(floorf((640.0 - ancho) * 0.5), y)
	if color.get_luminance() > 0.2:
		FUENTE_PIXEL.dibujar_texto(self, contenido, origen + Vector2(2, 3), pixel, Color("020711"))
	FUENTE_PIXEL.dibujar_texto(self, contenido, origen, pixel, color)
	if pixel >= 8:
		# Refuerza el peso del alfabeto del juego en los títulos grandes.
		_glifos_gruesos(contenido, origen, pixel, color)


func _glifos_gruesos(contenido: String, origen: Vector2, pixel: int, color: Color) -> void:
	for desplazamiento in [Vector2.ZERO, Vector2(pixel * 0.45, 0), Vector2(0, pixel * 0.2), Vector2(pixel * 0.45, pixel * 0.2)]:
		FUENTE_PIXEL.dibujar_texto(self, contenido, origen + desplazamiento.floor(), pixel, color)
