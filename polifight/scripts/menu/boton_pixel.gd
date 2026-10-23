extends Button

const FUENTE_PIXEL = preload("res://scripts/ui/fuente_pixel.gd")

@export var texto: String = "JUGAR"
@export_range(2, 12, 1) var tamano_pixel: int = 7
@export var color_normal: Color = Color(0.32, 0.72, 1.0)
@export var color_seleccionado: Color = Color(1.0, 0.72, 0.05)
@export var color_presionado: Color = Color(1.0, 0.24, 0.02)
@export var color_sombra: Color = Color(0.02, 0.03, 0.08, 0.95)
@export_group("Marco opcional")
@export var dibujar_marco: bool = false
@export var color_fondo: Color = Color(0.035, 0.075, 0.14, 0.96)
@export var color_fondo_seleccionado: Color = Color(0.075, 0.16, 0.28, 1.0)
@export var color_fondo_presionado: Color = Color(0.23, 0.055, 0.06, 1.0)
@export var color_borde: Color = Color(0.35, 0.48, 0.6, 1.0)
@export var color_borde_seleccionado: Color = Color(1.0, 0.72, 0.12, 1.0)
@export_range(1, 8, 1) var grosor_borde: int = 3
@export_range(2, 16, 1) var ancho_acento: int = 6

# El menú de dos jugadores necesita dos focos independientes del foco único de Godot.
var foco_jugadores: int = 0:
	set(valor):
		foco_jugadores = valor
		queue_redraw()

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
	var esta_seleccionado := has_focus() or is_hovered() or foco_jugadores != 0
	if dibujar_marco:
		_dibujar_marco(esta_seleccionado)

	var texto_mayuscula := texto.to_upper()
	var ancho := FUENTE_PIXEL.calcular_ancho(texto_mayuscula, tamano_pixel)
	var alto := FUENTE_PIXEL.ALTO_GLIFO * tamano_pixel
	var origen := Vector2(
		floor((size.x - ancho) * 0.5),
		floor((size.y - alto) * 0.5)
	)
	var color := color_normal
	if _presionado:
		color = color_presionado
	elif esta_seleccionado:
		color = Color("52b8ff") if foco_jugadores == 1 else color_seleccionado

	FUENTE_PIXEL.dibujar_texto(
		self,
		texto_mayuscula,
		origen + Vector2(tamano_pixel, tamano_pixel),
		tamano_pixel,
		color_sombra
	)
	FUENTE_PIXEL.dibujar_texto(self, texto_mayuscula, origen, tamano_pixel, color)


func _dibujar_marco(esta_seleccionado: bool) -> void:
	var fondo := color_fondo
	var borde := color_borde
	if _presionado:
		fondo = color_fondo_presionado
		borde = color_presionado
	elif esta_seleccionado:
		fondo = color_fondo_seleccionado
		borde = Color("52b8ff") if foco_jugadores == 1 else color_borde_seleccionado

	draw_rect(Rect2(Vector2.ZERO, size), fondo, true)
	draw_rect(Rect2(Vector2.ZERO, size), borde, false, grosor_borde)
	if foco_jugadores & 1:
		draw_rect(Rect2(0, 0, size.x * 0.5, 6), Color("52b8ff"))
	if foco_jugadores & 2:
		draw_rect(Rect2(size.x * 0.5, 0, size.x * 0.5, 6), Color("ffb80d"))

	# Dos marcas laterales dan lectura de selector arcade sin agrandar el texto.
	if esta_seleccionado or _presionado:
		var alto_marca := maxf(8.0, size.y - grosor_borde * 4.0)
		var origen_y := floorf((size.y - alto_marca) * 0.5)
		draw_rect(
			Rect2(grosor_borde * 2.0, origen_y, ancho_acento, alto_marca),
			borde,
			true
		)
		draw_rect(
			Rect2(
				size.x - grosor_borde * 2.0 - ancho_acento,
				origen_y,
				ancho_acento,
				alto_marca
			),
			borde,
			true
		)


func _al_presionar() -> void:
	_presionado = true
	queue_redraw()


func _al_soltar() -> void:
	_presionado = false
	queue_redraw()
