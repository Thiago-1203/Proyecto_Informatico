extends RefCounted
## Relieve y esquinas compartidos: geometría nativa, sin texturas nuevas.
static func marco(lienzo: CanvasItem, rect: Rect2, fondo: Color, acento: Color, activo: bool) -> void:
	lienzo.draw_rect(Rect2(rect.position + Vector2(6, 7), rect.size), Color("02040bdd"))
	lienzo.draw_rect(rect, Color("050915"))
	lienzo.draw_rect(rect.grow(-3), fondo)
	var luz := acento if activo else Color("53627e")
	lienzo.draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), luz, 3)
	lienzo.draw_line(rect.position, rect.position + Vector2(0, rect.size.y), luz, 3)
	lienzo.draw_line(rect.end, rect.end - Vector2(rect.size.x, 0), acento.darkened(0.55), 3)
	lienzo.draw_line(rect.end, rect.end - Vector2(0, rect.size.y), acento.darkened(0.55), 3)
	if activo:
		lienzo.draw_rect(rect.grow(-7), acento, false, 2)
		for extremo in [rect.position, rect.end - Vector2(12, 12)]:
			lienzo.draw_rect(Rect2(extremo, Vector2(12, 12)), acento)
