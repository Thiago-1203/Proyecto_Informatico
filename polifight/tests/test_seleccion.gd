extends SceneTree
## Flujo real, entradas independientes, foco, animación y catálogos ampliados.

const MODOS = preload("res://escenas/menu/selector_modos.tscn")
var seleccion: EstadoSeleccionPartida
var capturar: bool = false
var fallos: int = 0
var ruta_personaje: String
var ruta_escenario: String


func _initialize() -> void:
	capturar = "--capturas" in OS.get_cmdline_user_args()
	ruta_personaje = "/tmp/polifight-personaje-%d.tscn" % OS.get_process_id()
	ruta_escenario = "/tmp/polifight-escenario-%d.tscn" % OS.get_process_id()
	call_deferred("_probar")


func _exigir(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos += 1
		push_error(mensaje)


func _captura(nombre: String) -> void:
	if capturar:
		await create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/polifight-" + nombre + ".png")


func _esperar_aparicion(selector: Control) -> void:
	if selector._entrando:
		await selector.aparicion_finalizada
	await process_frame
	await process_frame


func _tecla(selector: Control, tecla: Key) -> void:
	var evento := InputEventKey.new()
	evento.physical_keycode = tecla
	evento.pressed = true
	selector._input(evento)


func _probar() -> void:
	seleccion = root.get_node("SeleccionPartida")
	_exigir(seleccion.personajes.size() == 1, "Debe haber un único personaje real")
	_exigir(seleccion.escenarios[0].nombre == "LA TERRAZA", "El escenario debe llamarse La terraza")
	var modos := MODOS.instantiate()
	root.add_child(modos)
	current_scene = modos
	await create_timer(0.7).timeout
	modos._confirmar()
	_exigir(not is_instance_valid(modos.selector_combate), "No debe haber selección antes de abrir la puerta")
	await create_timer(0.25).timeout
	_exigir(is_instance_valid(modos.entrada_puerta), "Debe reproducirse la entrada a la puerta")
	_exigir(not is_instance_valid(modos.selector_combate), "Durante la apertura no debe aparecer el selector")
	for i in 40:
		if is_instance_valid(modos.selector_combate):
			break
		await create_timer(0.1).timeout
	var selector: Control = modos.selector_combate
	_exigir(is_instance_valid(selector) and modos.puerta_finalizada, "La selección debe aparecer después de la cinemática")
	if not is_instance_valid(selector):
		quit(1)
		return
	_exigir(selector._entrando and selector.lienzo.modulate.a < 1.0, "La interfaz debe aparecer gradualmente")
	await _esperar_aparicion(selector)
	_exigir(selector.fondo_escenario.texture == selector.OSCURIDAD_PUERTA and not selector.sombra_fondo.visible, "Personajes debe usar la oscuridad original de la puerta")
	_exigir(selector.estadisticas_visibles[0] == {"danio": 10, "stamina": 100.0}, "Las estadísticas deben venir de la escena real de Barbieri")
	_exigir(selector.contenido.get_node("DanioJ1").texto == "10" and selector.contenido.get_node("StaminaJ1").texto == "100", "Deben verse los números de daño y stamina")
	_exigir(selector.tarjetas[0].find_children("*", "AnimationPlayer", true, false).is_empty(), "La tarjeta central no debe reproducir idle")
	var retrato: TextureRect = selector.tarjetas[0].find_children("*", "TextureRect", true, false)[0]
	var textura_retrato := retrato.texture
	_exigir(selector.tarjetas.size() == 2, "Debe haber un personaje y una casilla vacía")
	_exigir(selector.vistas[0].animacion.is_playing() and selector.vistas[1].animacion.is_playing(), "Ambos personajes deben reproducir idle")
	var animacion: AnimationPlayer = selector.vistas[0].animacion
	animacion.seek(0.0, true)
	var sprite: Sprite2D = selector.vistas[0].visual.get_node("Sprite2D")
	var textura_inicial := sprite.texture
	await create_timer(0.65).timeout
	_exigir(sprite.texture != textura_inicial, "El idle debe cambiar de fotograma")
	_exigir(retrato.texture == textura_retrato, "El retrato central debe permanecer estático")
	var posicion_idle := animacion.current_animation_position
	_tecla(selector, KEY_D)
	_exigir(selector.indices == [1, 0], "D debe mover solamente a J1 a la casilla vacía")
	_exigir(selector.estadisticas_visibles[0].is_empty(), "La casilla vacía no debe mostrar estadísticas de otro luchador")
	_tecla(selector, KEY_F)
	_exigir(not selector.listos[0], "Una casilla vacía no puede confirmar un personaje")
	_tecla(selector, KEY_A)
	_tecla(selector, KEY_RIGHT)
	_exigir(selector.indices == [0, 1], "Flecha derecha debe mover solamente a J2")
	_exigir(selector.vistas[0].animacion == animacion and animacion.current_animation_position >= posicion_idle, "Navegar no debe reiniciar el idle del otro jugador")
	_tecla(selector, KEY_LEFT)
	await _captura("personajes")
	_tecla(selector, KEY_S)
	_tecla(selector, KEY_DOWN)
	_exigir(selector.botones_listo[0].foco_jugadores == 1, "WASD debe resaltar el botón Listo de J1")
	_exigir(selector.botones_listo[1].foco_jugadores == 2, "Las flechas deben resaltar el botón Listo de J2")
	await _captura("foco-listos")
	_tecla(selector, KEY_F)
	_exigir(selector.listos == [true, false], "F debe confirmar a J1 sin confirmar a J2")
	_exigir(selector.boton_continuar.disabled, "Se necesitan ambos jugadores listos")
	_tecla(selector, KEY_ENTER)
	_exigir(selector.listos == [true, true], "Enter debe confirmar a J2 independientemente")
	_exigir(selector.boton_continuar.foco_jugadores == 3, "Ambos cursores deben resaltar el avance")
	_tecla(selector, KEY_ENTER)
	_exigir(selector.paso == selector.Paso.ESCENARIO, "Ambos listos deben poder avanzar a escenarios")
	_exigir(selector._entrando and selector.fondo_escenario.modulate.a < 1.0, "El escenario debe aparecer desde negro")
	await _esperar_aparicion(selector)
	_exigir(selector.tarjetas.size() == 2, "Debe haber un escenario y una casilla vacía")
	_exigir(selector.fondo_escenario.texture == seleccion.escenario.imagen, "El escenario debe ocupar el fondo")
	_exigir(selector.fondo_escenario.size.is_equal_approx(selector.size), "El fondo debe cubrir la pantalla")
	await _captura("escenarios")
	_tecla(selector, KEY_RIGHT)
	_tecla(selector, KEY_DOWN)
	_exigir(selector.boton_continuar.disabled, "La casilla vacía no debe permitir iniciar combate")
	_tecla(selector, KEY_ENTER)
	_exigir(not selector._iniciando, "Confirmar un escenario vacío no debe iniciar combate")
	_tecla(selector, KEY_LEFT)
	_exigir(selector._boton_volver.foco_jugadores & 2, "Debe poder navegar hasta Volver con las flechas")
	_tecla(selector, KEY_ENTER)
	_exigir(selector.paso == selector.Paso.PERSONAJES and selector.listos == [false, false], "Cambiar luchadores debe devolver ambos cursores")
	await _esperar_aparicion(selector)
	_exigir(selector.fondo_escenario.texture == selector.OSCURIDAD_PUERTA, "Volver a personajes debe recuperar el negro de la puerta")
	# El catálogo adicional debe funcionar sin tocar la interfaz.
	var personaje_extra := seleccion.personajes[0].duplicate() as FichaSeleccion
	personaje_extra.id = &"prueba"
	personaje_extra.nombre = "PRUEBA"
	var archivo := FileAccess.open(ruta_personaje, FileAccess.WRITE)
	archivo.store_string('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://escenas/personajes/barbieri.tscn" id="1"]\n[node name="Prueba" instance=ExtResource("1")]\nvida_maxima = 137\ndanio = 23\nstamina_maxima = 145.0\n')
	archivo.close()
	personaje_extra.escena = ruta_personaje
	seleccion.personajes.append(personaje_extra)
	var escenario_extra := seleccion.escenarios[0].duplicate() as FichaSeleccion
	escenario_extra.id = &"prueba"
	escenario_extra.nombre = "OTRO NIVEL"
	escenario_extra.imagen = GradientTexture2D.new()
	archivo = FileAccess.open(ruta_escenario, FileAccess.WRITE)
	archivo.store_string('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://escenas/juego/nivelI.tscn" id="1"]\n[node name="OtroNivel" instance=ExtResource("1")]\n')
	archivo.close()
	escenario_extra.escena = ruta_escenario
	seleccion.escenarios.append(escenario_extra)
	selector._renderizar()
	_exigir(selector.tarjetas.size() == 3, "Las entradas nuevas deben aparecer junto a la casilla vacía")
	_tecla(selector, KEY_D)
	_exigir(selector.indices == [1, 0], "Debe poder elegir un nuevo personaje sin mover a J2")
	_exigir(selector.estadisticas_visibles[0] == {"danio": 23, "stamina": 145.0}, "Las stats deben actualizarse con el personaje seleccionado")
	_exigir(selector.contenido.get_node("DanioJ1").texto == "23" and selector.contenido.get_node("StaminaJ1").texto == "145", "Los números visibles deben actualizarse sin duplicar datos de combate")
	_exigir(selector.estadisticas_visibles[1]["danio"] == 10, "Las stats de J2 deben conservar su elección")
	_tecla(selector, KEY_F)
	_tecla(selector, KEY_ENTER)
	_tecla(selector, KEY_F)
	_exigir(selector.paso == selector.Paso.ESCENARIO, "El catálogo nuevo debe mantener el flujo simultáneo")
	await _esperar_aparicion(selector)
	selector.tarjetas[1].pressed.emit()
	_exigir(seleccion.escenario == escenario_extra, "El mouse debe elegir el nuevo escenario")
	_exigir(selector.fondo_escenario.texture == escenario_extra.imagen, "Cambiar de escenario debe cambiar el fondo")
	_tecla(selector, KEY_S)
	_exigir(selector.boton_continuar.foco_jugadores & 1, "WASD debe resaltar Iniciar combate")
	_tecla(selector, KEY_F)
	var transicion := root.get_node("TransicionCombate")
	_exigir(transicion.activo and paused, "Confirmar el mapa debe iniciar una transición que bloquee el combate")
	_exigir(not is_instance_valid(modos.entrada_puerta), "La puerta no debe repetirse al iniciar el combate")
	_exigir(current_scene == modos and not transicion.cartel.visible, "El fundido debe comenzar sobre la selección, antes de cargar la arena")
	await create_timer(0.08, true, false, true).timeout
	_exigir(transicion.velo.modulate.a > 0.0 and transicion.velo.modulate.a < 1.0, "El cambio de escena debe tener un fundido gradual")
	var inicio_presentacion := Time.get_ticks_msec()
	for i in 30:
		await create_timer(0.01, true, true).timeout
		if current_scene != null and current_scene != modos:
			break
	_exigir(current_scene != null and current_scene != modos, "Debe iniciar el nivel elegido")
	if current_scene != null and current_scene != modos:
		var nivel := current_scene
		_exigir(paused and not transicion.cartel.visible, "La arena debe cargarse inmóvil antes de mostrar FIGTH")
		_exigir(transicion.velo.modulate.a > 0.95, "La escena debe cargarse bajo la cobertura negra")
		for i in 30:
			if transicion.cartel.visible:
				break
			await create_timer(0.02, true, false, true).timeout
		_exigir(transicion.activo and paused and transicion.cartel.visible, "FIGTH debe aparecer sobre la arena antes de habilitar los controles")
		_exigir(transicion.cartel.texture != null, "Debe cargarse la imagen generada")
		_exigir(is_zero_approx(transicion.velo.modulate.a), "El fundido debe terminar antes de aparecer FIGTH")
		var posicion_inicial: Vector2 = nivel.jugador1.position
		for accion in [&"j1_derecha", &"j1_patada"]:
			var entrada := InputEventAction.new()
			entrada.action = accion
			entrada.pressed = true
			Input.parse_input_event(entrada)
		Input.flush_buffered_events()
		await create_timer(0.1, true, false, true).timeout
		_exigir(nivel.jugador1.position == posicion_inicial and nivel.jugador2.vida_actual == 100, "Durante FIGTH no se puede mover ni atacar")
		for accion in [&"j1_derecha", &"j1_patada"]:
			var entrada := InputEventAction.new()
			entrada.action = accion
			entrada.pressed = false
			Input.parse_input_event(entrada)
		Input.flush_buffered_events()
		await _captura("figth")
		if transicion.activo:
			await transicion.finalizada
		_exigir(not paused and not transicion.pantalla.visible, "Al terminar FIGTH debe habilitarse la pelea y retirarse la transición")
		# Guardar PNGs detiene el hilo principal; se mide la duración sin capturas.
		if not capturar:
			_exigir(Time.get_ticks_msec() - inicio_presentacion < 1300, "El cartel debe dar paso rápidamente a la pelea")
		_exigir(nivel.name == "OtroNivel", "Debe cargar la escena seleccionada")
		_exigir(nivel.jugador1.vida_maxima == 137 and nivel.jugador2.vida_maxima == 100, "Cada jugador debe cargar su propia elección")
		_exigir(nivel.jugador1.oponente == nivel.jugador2, "Deben conectarse los oponentes")
		_exigir(nivel.jugador1.danio == 23 and nivel.jugador1.stamina_maxima == 145.0, "Las stats mostradas deben coincidir con el combate")
		nivel.get_node("GestorPausa")._reiniciar_combate()
		await process_frame
		await process_frame
		_exigir(current_scene.jugador1.vida_maxima == 137, "Reiniciar debe conservar la selección")
		current_scene.get_node("GestorPausa")._volver_al_menu()
		await process_frame
		await process_frame
		_exigir(current_scene.scene_file_path == "res://escenas/menu/menu.tscn", "Debe poder volver al menú")
	var segundo := load("res://escenas/menu/selector_combate.tscn").instantiate() as Control
	root.add_child(segundo)
	await _esperar_aparicion(segundo)
	_exigir(segundo.listos == [false, false] and segundo.indices == [0, 0], "Un nuevo duelo debe reiniciar ambos jugadores")
	for i in 20:
		var extra := seleccion.personajes[0].duplicate() as FichaSeleccion
		extra.id = StringName("prueba_%d" % i)
		seleccion.personajes.append(extra)
	segundo._elegir(21, 1)
	await process_frame
	await process_frame
	_exigir(segundo.tarjetas.size() == 23, "El catálogo grande debe mantener la casilla vacía")
	_exigir(segundo.scroll.scroll_vertical > 0, "La cuadrícula debe mostrar el cursor al desplazarse")
	segundo.queue_free()
	for ruta in [ruta_personaje, ruta_escenario]:
		DirAccess.remove_absolute(ruta)
	print("SELECCION: %d fallos" % fallos)
	quit(1 if fallos else 0)
