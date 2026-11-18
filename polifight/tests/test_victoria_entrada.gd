extends SceneTree
## Resultado interactivo y puerta en JUGAR: ejercita escenas y entradas reales.
var fallos := 0
var comprobaciones := 0

func _initialize() -> void:
	call_deferred("_probar")

func exigir(condicion: bool, mensaje: String) -> void:
	comprobaciones += 1
	if not condicion:
		fallos += 1
		push_error(mensaje)

func boton(indice: JoyButton, pulsado: bool) -> void:
	var evento := InputEventJoypadButton.new()
	evento.device = 7
	evento.button_index = indice
	evento.pressed = pulsado
	Input.parse_input_event(evento)
	Input.flush_buffered_events()
	await process_frame

func toque(indice: JoyButton) -> void:
	await boton(indice, true)
	await create_timer(0.06, true, false, true).timeout
	await boton(indice, false)
	await create_timer(0.05, true, false, true).timeout

func _probar() -> void:
	var nivel = load("res://escenas/juego/nivelI.tscn").instantiate()
	root.add_child(nivel)
	current_scene = nivel
	await create_timer(0.2).timeout
	# El golpe final no puede confirmar accidentalmente REVANCHA.
	await boton(JOY_BUTTON_A, true)
	nivel.hud.mostrar_ganador(1)
	var pantalla = nivel.hud.anuncio_ganador
	await pantalla.aparicion_finalizada
	await process_frame
	exigir(pantalla.revancha.disabled, "El resultado espera a soltar A")
	await boton(JOY_BUTTON_A, false)
	await process_frame
	await process_frame
	exigir(root.gui_get_focus_owner() == pantalla.revancha, "REVANCHA recibe el foco")
	exigir(nivel.hud.texto_ganador.texto == "JUGADOR 1 GANA!", "Identifica al ganador humano")
	exigir(pantalla.vista.animacion.is_playing(), "El ganador tiene celebración animada")
	# Disposición final en tamaños lógicos de 720p, ultrawide, 4:3 y vertical.
	for tamano in [Vector2(1920,1080), Vector2(2560,1080), Vector2(1920,1440), Vector2(1920,4160)]:
		pantalla.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		pantalla.size = tamano
		pantalla._ajustar()
		var area := Rect2(Vector2.ZERO, tamano).grow(1)
		for control in [pantalla.revancha, pantalla.menu, pantalla.nombre, pantalla.titulo, pantalla.vista]:
			exigir(area.encloses(control.get_global_rect()), "Resultado dentro de %s: %s" % [tamano, control.name])
	pantalla.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await toque(JOY_BUTTON_START)
	exigir(not paused and not nivel.get_node("MenuPausa").interfaz.visible, "START no superpone la pausa a la victoria")
	await toque(JOY_BUTTON_A)
	await process_frame
	await process_frame
	exigir(current_scene != nivel and current_scene.scene_file_path == "res://escenas/juego/nivelI.tscn", "A en REVANCHA reinicia el combate")
	nivel = current_scene
	exigir(nivel.jugador1.vida_actual == nivel.jugador1.vida_maxima and not nivel.hud.anuncio_ganador.visible, "La revancha comienza sin resultado anterior")
	nivel.hud.rival_es_ia = true
	nivel.hud.mostrar_ganador(2)
	pantalla = nivel.hud.anuncio_ganador
	await pantalla.aparicion_finalizada
	await process_frame
	await process_frame
	exigir(nivel.hud.texto_ganador.texto == "LA IA GANA!", "Identifica una victoria de la IA")
	await toque(JOY_BUTTON_B)
	exigir(root.gui_get_focus_owner() == pantalla.menu, "B selecciona MENU PRINCIPAL")
	await toque(JOY_BUTTON_A)
	await process_frame
	exigir(current_scene.scene_file_path == "res://escenas/menu/menu.tscn", "A confirma volver al menú")
	var menu = current_scene
	await create_timer(2.8).timeout
	await toque(JOY_BUTTON_A)
	await create_timer(0.25).timeout
	exigir(is_instance_valid(menu.entrada_puerta) and menu._abriendo_selector, "JUGAR reproduce la entrada al colegio")
	exigir(not is_instance_valid(menu.selector_modos), "Los modos esperan a la puerta")
	await toque(JOY_BUTTON_A)
	exigir(menu.find_children("EntradaColegio", "CanvasLayer", true, false).size() == 1, "Pulsar A repetidamente no duplica la puerta")
	await create_timer(1.2).timeout
	exigir(menu.puerta_finalizada and is_instance_valid(menu.selector_modos), "Después de entrar aparecen los modos")
	var modos = menu.selector_modos
	await toque(JOY_BUTTON_A)
	await create_timer(0.3).timeout
	exigir(is_instance_valid(modos.selector_combate), "1 VS 1 abre el selector sin otra cinemática")
	exigir(menu.find_children("EntradaColegio", "CanvasLayer", true, false).is_empty(), "La puerta no se repite al elegir modo")
	modos.selector_combate.volver_solicitado.emit()
	await process_frame
	modos.volver_solicitado.emit()
	await process_frame
	exigir(root.gui_get_focus_owner() == menu.boton_jugar, "Volver al inicio restaura el foco")
	print("VICTORIA / ENTRADA: %d comprobaciones, %d fallos" % [comprobaciones, fallos])
	quit(1 if fallos else 0)
