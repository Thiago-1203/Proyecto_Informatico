extends Button

const FUENTE_PIXEL = preload("res://scripts/ui/fuente_arcade.gd")

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
var _tiempo := 0.0

func _process(delta: float) -> void:
	if is_visible_in_tree() and (has_focus() or foco_jugadores != 0):
		_tiempo += delta
		queue_redraw()



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
	var esta_seleccionado := not disabled and (has_focus() or foco_jugadores != 0)
	if dibujar_marco:
		_dibujar_marco(esta_seleccionado)

	var texto_mayuscula := texto.to_upper()
	var escala := tamano_pixel
	while escala > 2 and FUENTE_PIXEL.calcular_ancho(texto_mayuscula, escala) > size.x - 36.0:
		escala -= 1
	var ancho := FUENTE_PIXEL.calcular_ancho(texto_mayuscula, escala)
	var alto := FUENTE_PIXEL.ALTO_GLIFO * escala
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
		origen + Vector2(2, 2),
		escala,
		color_sombra
	)
	FUENTE_PIXEL.dibujar_texto(self, texto_mayuscula, origen, escala, color)


func _dibujar_marco(esta_seleccionado: bool) -> void:
	var borde := color_borde_seleccionado if esta_seleccionado else color_borde
	if foco_jugadores == 1:
		borde = Color("52b8ff")
	var fondo := color_fondo_seleccionado if esta_seleccionado else color_fondo
	if _presionado:
		fondo = color_fondo_presionado
	preload("res://scripts/menu/estilo_arcade.gd").marco(self, Rect2(Vector2.ZERO, size), fondo, borde, esta_seleccionado)
	if esta_seleccionado:
		var x := 14.0 + roundf(sin(_tiempo * 5.0) * 3.0)
		FUENTE_PIXEL.dibujar_texto(self, ">", Vector2(x, floorf(size.y * 0.5 - 7)), 2, borde)


func _al_presionar() -> void:
	_presionado = true
	queue_redraw()


func _al_soltar() -> void:
	_presionado = false
	queue_redraw()
