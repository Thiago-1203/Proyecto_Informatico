extends Control

@export_enum("Izquierda:-1", "Derecha:1") var direccion: int = 1
@export_range(2, 10, 1) var tamano_pixel: int = 7
@export var color: Color = Color(1.0, 0.72, 0.05)
@export var color_sombra: Color = Color(0.55, 0.06, 0.01, 0.9)

const PATRON := [
	"00100",
	"00110",
	"00111",
	"11111",
	"00111",
	"00110",
	"00100",
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var ancho := 5 * tamano_pixel
	var alto := 7 * tamano_pixel
	var origen := Vector2(
		floor((size.x - ancho) * 0.5),
		floor((size.y - alto) * 0.5)
	)
	_dibujar_flecha(origen + Vector2(3, 3), color_sombra)
	_dibujar_flecha(origen, color)


func _dibujar_flecha(origen: Vector2, color_dibujo: Color) -> void:
	for fila in PATRON.size():
		for columna in 5:
			var columna_dibujada := columna if direccion > 0 else 4 - columna
			if PATRON[fila][columna_dibujada] == "1":
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
