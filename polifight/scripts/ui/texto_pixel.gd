extends Control

const FUENTE_PIXEL = preload("res://scripts/ui/fuente_pixel.gd")

@export var texto: String = "TEXTO":
	set(valor):
		texto = valor
		update_minimum_size()
		queue_redraw()
@export_range(2, 24, 1) var tamano_pixel: int = 8
@export_enum("Izquierda", "Centro", "Derecha") var alineacion_horizontal: int = 1
@export var color: Color = Color(1.0, 0.82, 0.12)
@export var color_sombra: Color = Color(0.08, 0.02, 0.01, 0.95)
@export var desplazamiento_sombra: Vector2 = Vector2(5, 5)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _get_minimum_size() -> Vector2:
	return Vector2(
		FUENTE_PIXEL.calcular_ancho(texto.to_upper(), tamano_pixel) + absf(desplazamiento_sombra.x),
		FUENTE_PIXEL.ALTO_GLIFO * tamano_pixel + absf(desplazamiento_sombra.y)
	)


func _draw() -> void:
	var contenido := texto.to_upper()
	var ancho := FUENTE_PIXEL.calcular_ancho(contenido, tamano_pixel)
	var alto := FUENTE_PIXEL.ALTO_GLIFO * tamano_pixel
	var origen_x := 0.0

	match alineacion_horizontal:
		1:
			origen_x = floorf((size.x - ancho) * 0.5)
		2:
			origen_x = floorf(size.x - ancho)

	var origen := Vector2(origen_x, floorf((size.y - alto) * 0.5))
	FUENTE_PIXEL.dibujar_texto(
		self,
		contenido,
		origen + desplazamiento_sombra,
		tamano_pixel,
		color_sombra
	)
	FUENTE_PIXEL.dibujar_texto(self, contenido, origen, tamano_pixel, color)
