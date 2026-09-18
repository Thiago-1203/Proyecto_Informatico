extends Button

@export var texto: String = "JUGAR"
@export_range(2, 12, 1) var tamano_pixel: int = 7
@export var color_normal: Color = Color(0.32, 0.72, 1.0)
@export var color_seleccionado: Color = Color(1.0, 0.72, 0.05)
@export var color_presionado: Color = Color(1.0, 0.24, 0.02)
@export var color_sombra: Color = Color(0.02, 0.03, 0.08, 0.95)

const GLIFOS := {
	"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
	"G": ["01110", "10001", "10000", "10111", "10001", "10001", "01110"],
	"I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
	"J": ["00111", "00010", "00010", "00010", "10010", "10010", "01100"],
	"L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
	"R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
	"S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
	"U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
}

var _presionado: bool = false


func _ready() -> void:
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(_al_presionar)
	button_up.connect(_al_soltar)


func _draw() -> void:
	var texto_mayuscula := texto.to_upper()
	var ancho := _calcular_ancho(texto_mayuscula)
	var alto := 7 * tamano_pixel
	var origen := Vector2(
		floor((size.x - ancho) * 0.5),
		floor((size.y - alto) * 0.5)
	)
	var color := color_normal
	if _presionado:
		color = color_presionado
	elif has_focus() or is_hovered():
		color = color_seleccionado

	_dibujar_texto(texto_mayuscula, origen + Vector2(tamano_pixel, tamano_pixel), color_sombra)
	_dibujar_texto(texto_mayuscula, origen, color)


func _calcular_ancho(contenido: String) -> int:
	if contenido.is_empty():
		return 0
	return (contenido.length() * 5 + contenido.length() - 1) * tamano_pixel


func _dibujar_texto(contenido: String, origen: Vector2, color: Color) -> void:
	var cursor_x := origen.x
	for caracter in contenido:
		if not GLIFOS.has(caracter):
			cursor_x += 6 * tamano_pixel
			continue

		var filas: Array = GLIFOS[caracter]
		for fila in filas.size():
			for columna in 5:
				if filas[fila][columna] == "1":
					draw_rect(
						Rect2(
							cursor_x + columna * tamano_pixel,
							origen.y + fila * tamano_pixel,
							tamano_pixel,
							tamano_pixel
						),
						color,
						true
					)
		cursor_x += 6 * tamano_pixel


func _al_presionar() -> void:
	_presionado = true
	queue_redraw()


func _al_soltar() -> void:
	_presionado = false
	queue_redraw()
