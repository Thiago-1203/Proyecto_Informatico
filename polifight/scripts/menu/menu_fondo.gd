extends Control
## Patio escolar y piso en perspectiva; movimiento ambiental de baja amplitud.
const COLEGIO = preload("res://cinematica_polifight/frames/frame_00.png")
var tiempo := 0.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	if is_visible_in_tree():
		tiempo += delta
		queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color("080b20"))
	draw_texture_rect(COLEGIO, Rect2(0, 0, 1920, 1080), false, Color("677898"))
	draw_rect(Rect2(0, 0, 1920, 1080), Color("090d26e8"))
	# Mampostería lateral: relaciona el marco arcade con el edificio del colegio.
	for lado in [0, 1848]:
		for y in range(0, 1080, 72):
			draw_rect(Rect2(lado, y, 72, 70), Color("172039"))
			draw_line(Vector2(lado + 4, y + 3), Vector2(lado + 68, y + 3), Color("34415a"), 3)
			draw_line(Vector2(lado + 68, y + 3), Vector2(lado + 68, y + 68), Color("050817"), 4)
	# El piso se desplaza lentamente; ni los botones ni los textos se mueven.
	draw_rect(Rect2(74, 830, 1772, 250), Color("080c20"))
	for x in range(-1200, 3200, 160):
		draw_line(Vector2(960 + (x - 960) * 0.3, 830), Vector2(x, 1080), Color("263054"), 2)
	for i in 7:
		var t := fmod(float(i) / 7.0 + tiempo * 0.018, 1.0)
		var y := 830.0 + t * t * 250.0
		draw_line(Vector2(74, y), Vector2(1846, y), Color("263054"), 2)
	for y in range(0, 1080, 6):
		draw_line(Vector2(74, y), Vector2(1846, y), Color(0, 0, 0, 0.09))
