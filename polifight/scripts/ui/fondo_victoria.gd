extends Control
## Rayos y medallón propios, dibujados con geometría nativa.
var tiempo := 0.0
var acento := Color("ffc34a")
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	if is_visible_in_tree():
		tiempo += delta
		queue_redraw()
func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0,0),Vector2(820,0),Vector2(640,1080),Vector2(0,1080)]),Color("102246cc"))
	var centro := Vector2(440, 540)
	for i in 12:
		var angulo := i * TAU / 12.0 + sin(tiempo * 0.25) * 0.025
		var rayo := PackedVector2Array([centro + Vector2.from_angle(angulo) * 110, centro + Vector2.from_angle(angulo - 0.055) * 650, centro + Vector2.from_angle(angulo + 0.055) * 650])
		draw_colored_polygon(rayo, Color(acento, 0.075))
	draw_circle(centro, 265, Color(acento, 0.12))
	draw_arc(centro, 275, -0.3, PI + 0.7, 64, acento.darkened(0.5), 3, false)
	draw_arc(centro, 292, PI + 0.8, TAU + 0.1, 64, acento.darkened(0.65), 3, false)
	draw_colored_polygon(PackedVector2Array([Vector2(200,835),Vector2(660,835),Vector2(720,865),Vector2(140,865)]),Color("263a57"))
	draw_line(Vector2(180, 835), Vector2(680, 835), acento, 4)
	draw_line(Vector2(110, 130), Vector2(1810, 130), Color("516078"), 2)
	draw_line(Vector2(110, 978), Vector2(1810, 978), Color("516078"), 2)
	for i in 5:
		draw_rect(Rect2(1700 + i * 22, 1005, 10, 30), Color(acento, 0.25 + sin(tiempo * 2 - i) * 0.1))
