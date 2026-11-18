extends Button
## Fila arcade: cursor y relieve, sin paneles explicativos.
const FUENTE = preload("res://scripts/ui/fuente_arcade.gd")
const ESTILO = preload("res://scripts/menu/estilo_arcade.gd")
var titulo: String
var detalle: String
var etiqueta: String
var icono := 0
var acento := Color("ffc34a")
var elegido := false
var tiempo := 0.0
func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
func _process(delta: float) -> void:
	if is_visible_in_tree() and elegido:
		tiempo += delta
		queue_redraw()
func _draw() -> void:
	var tinta := acento if elegido else Color("8291aa")
	ESTILO.marco(self, Rect2(Vector2.ZERO, size), Color("1c2f58") if elegido else Color("10172c"), tinta, elegido)
	var sello := "2P" if icono == 0 else ("CPU" if icono == 1 else str(icono - 1))
	FUENTE.dibujar_texto(self, sello, Vector2(80, 42), 4, tinta)
	FUENTE.dibujar_texto(self, titulo, Vector2(300, 42), 4, Color("fff0b5") if elegido else Color("b3bed0"))
	if elegido:
		FUENTE.dibujar_texto(self, ">", Vector2(32 + roundf(sin(tiempo * 5) * 5), 42), 4, acento)
		FUENTE.dibujar_texto(self, "<", Vector2(size.x - 70 - roundf(sin(tiempo * 5) * 5), 42), 4, acento)
