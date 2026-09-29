extends Node2D

const PATRON_TRIANGULO: Array[String] = [
	"1111111",
	"0111110",
	"0011100",
	"0001000",
]

@export_range(3, 12, 1) var tamano_pixel: int = 6
@export var color_jugador_1: Color = Color(1.0, 0.43, 0.04, 1.0)
@export var color_jugador_2: Color = Color(0.05, 0.48, 1.0, 1.0)
@export_range(0.0, 20.0, 1.0) var amplitud_movimiento: float = 5.0
@export_range(0.1, 10.0, 0.1) var velocidad_movimiento: float = 3.5

var color_triangulo: Color
var posicion_inicial: Vector2
var tiempo_movimiento: float = 0.0


func _ready() -> void:
	posicion_inicial = position
	var personaje: Personaje = get_parent() as Personaje
	if personaje == null:
		push_error("El indicador de jugador debe ser hijo de un Personaje")
		return

	color_triangulo = color_jugador_2 if personaje.numero_jugador == 2 else color_jugador_1
	queue_redraw()


func _process(delta: float) -> void:
	tiempo_movimiento += delta
	position.y = posicion_inicial.y + round(
		sin(tiempo_movimiento * velocidad_movimiento) * amplitud_movimiento
	)


func _draw() -> void:
	var origen: Vector2 = Vector2(
		-PATRON_TRIANGULO[0].length() * tamano_pixel * 0.5,
		-PATRON_TRIANGULO.size() * tamano_pixel * 0.5
	)
	_dibujar_contorno(origen, color_triangulo.darkened(0.72))
	_dibujar_patron(origen, PATRON_TRIANGULO, color_triangulo)


func _dibujar_contorno(origen: Vector2, color_contorno: Color) -> void:
	var fila: int = 0
	while fila < PATRON_TRIANGULO.size():
		var columna: int = 0
		while columna < PATRON_TRIANGULO[fila].length():
			if _es_pixel_triangulo(fila, columna):
				var desplazamiento_y: int = -1
				while desplazamiento_y <= 1:
					var desplazamiento_x: int = -1
					while desplazamiento_x <= 1:
						var fila_vecina: int = fila + desplazamiento_y
						var columna_vecina: int = columna + desplazamiento_x
						if not _es_pixel_triangulo(fila_vecina, columna_vecina):
							_dibujar_pixel(
								origen,
								fila_vecina,
								columna_vecina,
								color_contorno
							)
						desplazamiento_x += 1
					desplazamiento_y += 1
			columna += 1
		fila += 1


func _dibujar_patron(
	origen: Vector2,
	patron: Array[String],
	color_dibujo: Color
) -> void:
	var fila: int = 0
	while fila < patron.size():
		var columna: int = 0
		while columna < patron[fila].length():
			if patron[fila][columna] == "1":
				_dibujar_pixel(origen, fila, columna, color_dibujo)
			columna += 1
		fila += 1


func _dibujar_pixel(
	origen: Vector2,
	fila: int,
	columna: int,
	color_dibujo: Color
) -> void:
	draw_rect(
		Rect2(
			origen.x + columna * tamano_pixel,
			origen.y + fila * tamano_pixel,
			tamano_pixel,
			tamano_pixel
		),
		color_dibujo,
		true
	)


func _es_pixel_triangulo(fila: int, columna: int) -> bool:
	if fila < 0 or fila >= PATRON_TRIANGULO.size():
		return false
	if columna < 0 or columna >= PATRON_TRIANGULO[fila].length():
		return false

	return PATRON_TRIANGULO[fila][columna] == "1"
