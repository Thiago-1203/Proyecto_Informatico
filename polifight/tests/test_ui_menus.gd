extends SceneTree
## Regresión de las nuevas acciones de mouse y del estado visual de preparación.
var fallos := 0
func _initialize() -> void:
	call_deferred("_probar")
func exigir(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos += 1
		push_error(mensaje)
func click(control: Control) -> void:
	var posicion := root.get_final_transform() * control.get_global_rect().get_center()
	for presionada in [true, false]:
		var evento := InputEventMouseButton.new()
		evento.button_index = MOUSE_BUTTON_LEFT
		evento.position = posicion
		evento.global_position = posicion
		evento.pressed = presionada
		Input.parse_input_event(evento)
		Input.flush_buffered_events()
		await process_frame

func _probar() -> void:
	var modos = load("res://escenas/menu/selector_modos.tscn").instantiate()
	root.add_child(modos)
	await create_timer(0.8).timeout
	await click(modos._tarjetas[0])
	exigir(modos.indice_seleccionado == 0 and modos.boton_jugar.disabled, "El modo futuro se identifica y no permite continuar")
	await click(modos._tarjetas[1])
	exigir(modos.indice_seleccionado == 1 and not modos.boton_jugar.disabled, "El duelo se selecciona con mouse")
	modos.free()
	var selector = load("res://escenas/menu/selector_combate.tscn").instantiate()
	root.add_child(selector)
	await selector.aparicion_finalizada
	await process_frame
	await click(selector.opciones_configuracion[1])
	exigir(selector.paso == selector.Paso.RIVAL and selector.opcion_configuracion == 1, "El click selecciona rival sin avanzar accidentalmente")
	exigir(selector.opciones_configuracion[1].elegido, "La tarjeta muestra qué rival está seleccionado")
	selector._confirmar_opcion_actual()
	exigir(selector.paso == selector.Paso.DIFICULTAD, "Continuar con IA abre la dificultad")
	await click(selector.opciones_configuracion[2])
	selector._confirmar_opcion_actual()
	exigir(selector.seleccion.dificultad_ia == 2, "La dificultad elegida por mouse persiste")
	exigir(selector.boton_continuar.disabled, "Se requieren ambos luchadores confirmados")
	selector.botones_listo[0].pressed.emit()
	exigir(selector._cursor_humano(0) == 1, "Después de J1 el cursor elige a la IA")
	selector.botones_listo[1].pressed.emit()
	exigir(not selector.boton_continuar.disabled, "El avance se habilita al confirmar ambos luchadores")
	selector._volver()
	selector._volver()
	selector._confirmar_configuracion(0)
	selector._seleccionar_cursor_mouse(1)
	selector.tarjetas[1].pressed.emit()
	exigir(selector.indices == [0, 1], "La pestaña Jugador 2 dirige el mouse a J2")
	selector.tarjetas[0].pressed.emit()
	selector._seleccionar_cursor_mouse(0)
	selector.tarjetas[1].pressed.emit()
	exigir(selector.indices == [1, 0], "La pestaña Jugador 1 dirige el mouse a J1")
	selector.tarjetas[0].pressed.emit()
	for resolucion in [Vector2(1280, 720), Vector2(1024, 768), Vector2(2560, 1080)]:
		selector.size = resolucion
		selector._ajustar_escala()
		var origen: Vector2 = selector.lienzo.position
		var fin: Vector2 = origen + selector.RESOLUCION * selector.lienzo.scale
		exigir(origen.x >= -0.01 and origen.y >= -0.01 and fin.x <= resolucion.x + 0.01 and fin.y <= resolucion.y + 0.01, "El lienzo debe caber en " + str(resolucion))
	for jugador in [1, 2]:
		exigir(selector.contenido.get_node("DanioJ%d" % jugador).is_visible_in_tree() and selector.contenido.get_node("StaminaJ%d" % jugador).is_visible_in_tree(), "Ambos jugadores deben tener las stats visibles")
	selector.queue_free()
	await process_frame
	print("UI MENUS: %d fallos" % fallos)
	quit(1 if fallos else 0)
