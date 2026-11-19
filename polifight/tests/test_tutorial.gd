extends SceneTree
## Entradas reales, objetivos de combate y aislamiento del modo de práctica.
var fallos := 0
var tutorial: Node2D

func _initialize() -> void:
	call_deferred("_probar")

func exigir(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos += 1
		push_error(mensaje)

func tecla(codigo: Key, pulsada: bool) -> void:
	var evento := InputEventKey.new()
	evento.physical_keycode = codigo
	evento.pressed = pulsada
	Input.parse_input_event(evento)
	Input.flush_buffered_events()
	await process_frame

func mantener(codigo: Key, tiempo: float) -> void:
	await tecla(codigo, true)
	await create_timer(tiempo).timeout
	await tecla(codigo, false)
	await physics_frame

func boton(codigo: JoyButton, pulsado: bool) -> void:
	var evento := InputEventJoypadButton.new()
	evento.device = 42
	evento.button_index = codigo
	evento.pressed = pulsado
	Input.parse_input_event(evento)
	Input.flush_buffered_events()
	await process_frame

func siguiente() -> void:
	await mantener(KEY_ENTER, 0.04)
	await create_timer(0.15).timeout

func _probar() -> void:
	var seleccion = root.get_node("SeleccionPartida")
	var fichas = seleccion.jugadores.duplicate()
	var contra_ia: bool = seleccion.contra_ia
	var escala_anterior := Engine.time_scale
	tutorial = load("res://escenas/juego/tutorial.tscn").instantiate()
	root.add_child(tutorial)
	current_scene = tutorial
	await create_timer(0.3).timeout
	exigir(tutorial._listo and tutorial.paso == 0, "El tutorial abre en movimiento sin pantalla extra")
	exigir(root.gui_get_focus_owner() != null, "La práctica mantiene un foco de GUI seguro")
	exigir(not tutorial.completado, "Un paso no se completa por esperar")
	await mantener(KEY_A, 0.45)
	exigir(not tutorial.completado, "Movimiento requiere ambas direcciones")
	await mantener(KEY_D, 0.45)
	exigir(tutorial.completado and tutorial.paso == 0, "Caminar completa el objetivo sin avanzar solo")
	await siguiente()
	exigir(tutorial.paso == 1 and not tutorial.completado, "Enter avanza una sola lección")
	# Un mando con ID arbitrario debe controlar al único aprendiz.
	root.get_node("EntradaMandos").asignar_principal(42)
	await boton(JOY_BUTTON_A, true)
	await boton(JOY_BUTTON_A, false)
	await create_timer(0.2).timeout
	exigir(tutorial._salto_iniciado and tutorial.paso == 1, "A salta sin actuar como confirmar o saltear paso")
	await create_timer(1.6).timeout
	exigir(tutorial.completado, "El salto se completa al aterrizar")
	await siguiente()
	await mantener(KEY_S, 0.7)
	exigir(tutorial.completado, "Agacharse usa el estado real del personaje")
	await siguiente()
	# Golpear lejos no debe aprobar el ejercicio.
	tutorial.rival.position.x += 600
	await mantener(KEY_J, 0.05)
	await create_timer(1.5).timeout
	exigir(not tutorial.completado, "Un puño al aire no completa la lección")
	tutorial.rival.position = Vector2(1450, 780)
	await mantener(KEY_J, 0.05)
	await create_timer(1.5).timeout
	exigir(tutorial.completado, "Conectar un puño completa la lección de ataque")
	await siguiente()
	await mantener(KEY_K, 0.05)
	await create_timer(1.0).timeout
	exigir(tutorial.completado, "Conectar una patada completa su propia lección")
	await siguiente()
	await mantener(KEY_H, 3.0)
	exigir(tutorial.completado and tutorial.jugador.stamina_actual < tutorial.jugador.stamina_maxima, "Bloquear un golpe real completa defensa y consume stamina")
	exigir(tutorial.jugador.vida_actual == tutorial.jugador.vida_maxima, "La práctica no daña al aprendiz")
	await siguiente()
	exigir(not tutorial.completado, "La recuperación requiere llenar la barra")
	await create_timer(2.6).timeout
	exigir(tutorial.completado, "Soltar defensa permite recuperar stamina de verdad")
	await siguiente()
	exigir(tutorial.paso == 7 and tutorial.jugador.carga_ulti == 0, "La ulti comienza enseñando su carga")
	for i in 5:
		tutorial.jugador.position = Vector2(1140, 780)
		tutorial.rival.position = Vector2(1450, 780)
		await mantener(KEY_J, 0.05)
		await create_timer(1.5).timeout
	exigir(tutorial.jugador.carga_ulti == 100 and tutorial._ulti_lista, "Cinco impactos reales cargan la ulti y cambian la ayuda")
	exigir(tutorial.texto_teclado.texto == "L" and not tutorial.completado, "Llenar la barra todavía requiere ejecutar la ulti")
	await mantener(KEY_L, 0.05)
	await create_timer(0.8).timeout
	# Pausa durante la ulti: detener también los proyectiles externos a Practica.
	await mantener(KEY_ESCAPE, 0.05)
	exigir(tutorial.pausado and tutorial.modal.visible and not paused, "La pausa del dojo congela su práctica sin alterar el árbol global")
	var posicion_pausa: Vector2 = tutorial.jugador.position
	var carga_pausa: float = tutorial.jugador.carga_ulti
	var proyectiles := tutorial.get_children().filter(func(child): return child is Node2D and child != tutorial.mundo)
	exigir(not proyectiles.is_empty(), "La ulti produce sus proyectiles reales")
	var posiciones: Array[Vector2] = []
	for proyectil in proyectiles:
		posiciones.append(proyectil.position)
	await create_timer(0.3).timeout
	exigir(tutorial.jugador.position == posicion_pausa and tutorial.jugador.carga_ulti == carga_pausa, "Pausa conserva el estado del aprendiz")
	for i in proyectiles.size():
		exigir(is_instance_valid(proyectiles[i]) and proyectiles[i].position == posiciones[i], "Pausa inmoviliza los proyectiles de ulti")
	await boton(JOY_BUTTON_DPAD_DOWN, true)
	await boton(JOY_BUTTON_DPAD_DOWN, false)
	await boton(JOY_BUTTON_A, true)
	await boton(JOY_BUTTON_A, false)
	exigir(tutorial.mostrando_controles and root.gui_get_focus_owner() != null, "La guía completa mantiene navegación con mando")
	await boton(JOY_BUTTON_B, true)
	await boton(JOY_BUTTON_B, false)
	exigir(tutorial.pausado and not tutorial.mostrando_controles, "B vuelve de controles al menú de pausa")
	await boton(JOY_BUTTON_B, true)
	await boton(JOY_BUTTON_B, false)
	exigir(not tutorial.pausado and not Input.is_action_pressed("j1_patada"), "B reanuda sin lanzar una patada")
	await create_timer(1.8).timeout
	exigir(tutorial.completado, "La lección termina cuando concluye la animación de ulti")
	await siguiente()
	exigir(tutorial.finalizado and tutorial.boton_siguiente.texto == "IR A MODOS >", "El final ofrece práctica libre y una salida clara")
	tutorial._alternar_pausa()
	tutorial._reiniciar()
	exigir(not tutorial.finalizado and tutorial.paso == 0 and not tutorial.pausado, "Reiniciar restaura las lecciones desde la pausa")
	exigir(seleccion.jugadores == fichas and seleccion.contra_ia == contra_ia and Engine.time_scale == escala_anterior, "Tutorial no modifica selección, IA ni ritmo de combate")
	# También debe poder completarse omitiendo cualquier ejercicio.
	for i in tutorial.LECCIONES.size():
		tutorial._siguiente()
	exigir(tutorial.finalizado, "Omitir permite avanzar sin quedar bloqueado")
	tutorial.jugador.carga_ulti = 100.0
	tutorial.jugador.ulti_cambiada.emit(100.0)
	exigir(tutorial.progreso.texto == "TUTORIAL COMPLETADO", "Cargar la ulti en práctica libre conserva la pantalla final")
	tutorial._salir()
	await create_timer(0.8).timeout
	var modos = current_scene
	exigir(modos.get_script() == load("res://scripts/menu/selector_modos.gd"), "Salir devuelve al selector de modos")
	modos._elegir_modo(3)
	modos._confirmar()
	await create_timer(0.6).timeout
	exigir(current_scene.get_script() == load("res://scripts/juego/tutorial.gd"), "Tutorial se abre desde su tarjeta del selector")
	current_scene.free()
	print("TUTORIAL: %d fallos" % fallos)
	quit(1 if fallos else 0)
