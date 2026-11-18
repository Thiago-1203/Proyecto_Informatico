extends Control
const FUENTE = preload("res://scripts/ui/fuente_arcade.gd")
const LOGO = preload("res://assets/ui/PoliFight_LOGO.png")
var paso: int = 0:
	set(valor):
		paso = valor
		queue_redraw()
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	draw_texture_rect(LOGO, Rect2(100, 18, 190, 104), false)
	var texto: String = ["MODO", "RIVAL", "LUCHADORES", "ARENA"][paso]
	FUENTE.dibujar_texto(self, "%02d / 04  %s" % [paso + 1, texto], Vector2(1390, 64), 3, Color("e5b766"))
	draw_line(Vector2(100, 140), Vector2(1820, 140), Color("56482f"), 2)
