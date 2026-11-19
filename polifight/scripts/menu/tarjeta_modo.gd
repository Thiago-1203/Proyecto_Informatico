extends Control
signal elegida
const FUENTE = preload("res://scripts/ui/fuente_arcade.gd")
const ESTILO = preload("res://scripts/menu/estilo_arcade.gd")
@export var ilustracion: Texture2D
@export var titulo: String = "1 VS 1"
@export var subtitulo: String
@export var descripcion: String
var disponible := false
var es_tutorial := false
var tiempo := 0.0
var seleccionado := false:
	set(valor):
		seleccionado = valor
		queue_redraw()
func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
func _process(delta: float) -> void:
	if is_visible_in_tree():
		tiempo += delta
		queue_redraw()
func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		accept_event()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		elegida.emit()
		accept_event()
func _draw() -> void:
	var acento := Color("ffc34a") if seleccionado else Color("68758f")
	ESTILO.marco(self, Rect2(Vector2.ZERO, size), Color("152347") if seleccionado else Color("10172c"), acento, seleccionado)
	if ilustracion != null:
		var espacio := Rect2(30, 76, size.x - 60, 300)
		var factor := minf(espacio.size.x / ilustracion.get_width(), espacio.size.y / ilustracion.get_height())
		var tamano := (ilustracion.get_size() * factor).floor()
		var flotacion := roundf(sin(tiempo * 2.2) * 5.0) if seleccionado else 0.0
		draw_texture_rect(ilustracion, Rect2((espacio.position + (espacio.size - tamano) * 0.5).floor() + Vector2(0, flotacion), tamano), false, Color.WHITE if disponible else Color("76829d"))
	elif es_tutorial:
		_dibujar_tutorial()
	_centrar(titulo, 425, 8, Color("fff0b5") if seleccionado else Color("9ca9bf"))
	_centrar(subtitulo if es_tutorial else ("AMIGO O IA" if disponible else "PROXIMAMENTE"), 515, 3, acento)
	if seleccionado:
		var salto := roundf(sin(tiempo * 5.0) * 4.0)
		FUENTE.dibujar_texto(self, ">", Vector2(22 + salto, 435), 3, acento)
		FUENTE.dibujar_texto(self, "<", Vector2(size.x - 40 - salto, 435), 3, acento)
func _centrar(valor: String, y: float, pixel: int, color: Color) -> void:
	while pixel > 2 and FUENTE.calcular_ancho(valor, pixel) > size.x - 100:
		pixel -= 1
	var origen := Vector2(floorf((size.x - FUENTE.calcular_ancho(valor, pixel)) * 0.5), y)
	FUENTE.dibujar_texto(self, valor, origen + Vector2(3, 3), pixel, Color("030611"))
	FUENTE.dibujar_texto(self, valor, origen, pixel, color)

func _dibujar_tutorial() -> void:
	var centro := size.x * 0.5
	var azul := Color("52b8ff")
	var oro := Color("ffb80d")
	# Teclas y mando dibujados con la misma geometría de la interfaz arcade.
	for tecla in [{"t": "W", "p": Vector2(-29, 102)}, {"t": "A", "p": Vector2(-95, 168)}, {"t": "S", "p": Vector2(-29, 168)}, {"t": "D", "p": Vector2(37, 168)}]:
		var rect := Rect2(Vector2(centro, 0) + tecla["p"], Vector2(58, 58))
		ESTILO.marco(self, rect, Color("1b3154"), azul, false)
		FUENTE.dibujar_texto(self, tecla["t"], rect.position + Vector2(19, 17), 4, azul)
	var cuerpo := Rect2(centro - 120, 266, 240, 85)
	ESTILO.marco(self, cuerpo, Color("1b3154"), oro, false)
	draw_rect(Rect2(centro - 92, 301, 54, 15), azul)
	draw_rect(Rect2(centro - 73, 282, 15, 54), azul)
	for punto in [Vector2(66, 285), Vector2(45, 306), Vector2(87, 306), Vector2(66, 327)]:
		draw_rect(Rect2(Vector2(centro, 0) + punto, Vector2(12, 12)), oro)
