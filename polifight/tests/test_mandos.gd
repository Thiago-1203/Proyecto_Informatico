extends SceneTree
## Entrada real de GUI y acciones: mandos con IDs arbitrarios, reconexión y pausa.
var fallos := 0
var comprobaciones := 0
var mandos: Node

func _initialize() -> void:
	call_deferred("_probar")

func exigir(condicion: bool, mensaje: String) -> void:
	comprobaciones += 1
	if not condicion:
		fallos += 1
		push_error(mensaje)

func boton(dispositivo: int, indice: JoyButton, pulsado: bool) -> void:
	var evento := InputEventJoypadButton.new()
	evento.device = dispositivo
	evento.button_index = indice
	evento.pressed = pulsado
	Input.parse_input_event(evento)
	Input.flush_buffered_events()
	await process_frame

func toque(dispositivo: int, indice: JoyButton) -> void:
	await boton(dispositivo, indice, true)
	await create_timer(0.06).timeout
	await boton(dispositivo, indice, false)
	await create_timer(0.04).timeout
	await process_frame

func eje(dispositivo: int, indice: JoyAxis, valor: float) -> void:
	var evento := InputEventJoypadMotion.new()
	evento.device = dispositivo
	evento.axis = indice
	evento.axis_value = valor
	Input.parse_input_event(evento)
	Input.flush_buffered_events()
	await process_frame

func escape() -> void:
	for pulsada in [true, false]:
		var evento := InputEventKey.new()
		evento.physical_keycode = KEY_ESCAPE
		evento.pressed = pulsada
		Input.parse_input_event(evento)
		Input.flush_buffered_events()
		await process_frame

func _probar() -> void:
	mandos = root.get_node("EntradaMandos")
	# No depender de que exista hardware en la máquina de CI.
	for dispositivo in mandos.dispositivos.duplicate():
		if dispositivo >= 0:
			mandos._conexion_cambiada(dispositivo, false)
	mandos.registrar_dispositivo(7)
	mandos.registrar_dispositivo(19)
	exigir(mandos.dispositivos == [7, 19], "IDs 7 y 19 deben ocupar J1 y J2")
	var menu = load("res://escenas/menu/menu.tscn").instantiate()
	root.add_child(menu)
	await create_timer(2.8).timeout
	exigir(root.gui_get_focus_owner() == menu.boton_jugar, "JUGAR tiene el foco inicial")
	await toque(19, JOY_BUTTON_DPAD_DOWN)
	exigir(root.gui_get_focus_owner() == menu.boton_salir, "La cruceta del segundo mando navega el menú principal")
	await toque(7, JOY_BUTTON_DPAD_UP)
	exigir(root.gui_get_focus_owner() == menu.boton_jugar, "La cruceta del primer mando vuelve a JUGAR")
	await boton(19, JOY_BUTTON_A, true)
	await boton(19, JOY_BUTTON_A, false)
	await create_timer(1.8).timeout
	exigir(is_instance_valid(menu.selector_modos), "A debe abrir JUGAR a través del Button real")
	if not is_instance_valid(menu.selector_modos):
		menu.free()
		_finalizar()
		return
	exigir(mandos.dispositivos == [19, 7], "El mando que abre JUGAR ocupa J1")
	var modos = menu.selector_modos
	exigir(not is_instance_valid(modos.selector_combate), "La misma pulsación de A no salta el selector de modos")
	var indice: int = modos.indice_seleccionado
	await toque(7, JOY_BUTTON_DPAD_RIGHT)
	exigir(modos.indice_seleccionado == posmod(indice + 1, modos.MODOS.size()), "Cruceta recorre los modos")
	await toque(7, JOY_BUTTON_DPAD_LEFT)
	await toque(19, JOY_BUTTON_A)
	await create_timer(2.2).timeout
	var selector = modos.selector_combate
	exigir(is_instance_valid(selector), "A inicia la elección de rival")
	if not is_instance_valid(selector):
		menu.free()
		_finalizar()
		return
	await create_timer(0.2).timeout
	await eje(19, JOY_AXIS_LEFT_Y, 0.2)
	exigir(selector.opcion_configuracion == 0, "El drift no cambia la opción")
	await eje(19, JOY_AXIS_LEFT_Y, 0.9)
	await eje(19, JOY_AXIS_LEFT_Y, 0.0)
	exigir(selector.opcion_configuracion == 1, "El stick del mando con ID 19 elige la IA")
	await toque(19, JOY_BUTTON_A)
	await create_timer(0.3).timeout
	exigir(selector.paso == selector.Paso.DIFICULTAD, "A confirma el rival sin duplicar confirmación")
	await boton(19, JOY_BUTTON_A, true)
	await create_timer(0.4).timeout
	exigir(selector.paso == selector.Paso.PERSONAJES and selector.listos == [false, false], "Mantener A no confirma también un luchador")
	await boton(19, JOY_BUTTON_A, false)
	await create_timer(0.1).timeout
	await toque(19, JOY_BUTTON_A)
	exigir(selector.listos[0], "Cualquier mando controla al humano contra la IA")
	await toque(19, JOY_BUTTON_A)
	exigir(selector.listos[1], "El mismo mando puede confirmar al rival IA")
	await toque(19, JOY_BUTTON_B)
	exigir(selector.paso == selector.Paso.DIFICULTAD, "B vuelve desde luchadores")
	await toque(19, JOY_BUTTON_B)
	await eje(19, JOY_AXIS_LEFT_Y, -0.9)
	await eje(19, JOY_AXIS_LEFT_Y, 0.0)
	await toque(19, JOY_BUTTON_A)
	await create_timer(0.3).timeout
	exigir(selector.paso == selector.Paso.PERSONAJES and not selector.seleccion.contra_ia, "El mando entra al duelo local")
	await toque(19, JOY_BUTTON_DPAD_RIGHT)
	exigir(selector.indices == [1, 0], "El mando principal mueve sólo el cursor J1")
	await toque(19, JOY_BUTTON_DPAD_LEFT)
	await toque(7, JOY_BUTTON_DPAD_RIGHT)
	exigir(selector.indices == [0, 1], "El otro mando mueve sólo el cursor J2")
	menu.free()
	await process_frame
	mandos.asignar_principal(7)
	# Gameplay: cada dispositivo afecta únicamente las acciones de su puesto.
	await boton(7, JOY_BUTTON_X, true)
	exigir(Input.is_action_pressed("j1_ataque") and not Input.is_action_pressed("j2_ataque"), "X del primer mando sólo ataca con J1")
	await boton(7, JOY_BUTTON_X, false)
	await boton(19, JOY_BUTTON_B, true)
	exigir(Input.is_action_pressed("j2_patada") and not Input.is_action_pressed("j1_patada"), "B del segundo mando sólo patea con J2")
	await boton(19, JOY_BUTTON_B, false)
	await eje(7, JOY_AXIS_LEFT_X, 0.9)
	exigir(Input.is_action_pressed("j1_derecha") and not Input.is_action_pressed("j2_derecha"), "El stick mueve a su propio jugador")
	mandos._conexion_cambiada(7, false)
	exigir(not Input.is_action_pressed("j1_derecha"), "Desconectar libera el movimiento mantenido")
	exigir(mandos.dispositivos == [-1, 19], "Desconectar J1 conserva el puesto de J2")
	mandos.registrar_dispositivo(23)
	exigir(mandos.dispositivos == [23, 19], "Reconectar con un ID nuevo recupera J1")
	await eje(7, JOY_AXIS_LEFT_X, 0.0)
	await toque(23, JOY_BUTTON_X)
	for evento in InputMap.action_get_events("j1_ataque"):
		if evento is InputEventJoypadButton:
			exigir(evento.device == 23, "Se reemplazan los bindings del dispositivo desconectado")
	for dispositivo in [23, 19]:
		var jugador: int = mandos.jugador_para_dispositivo(dispositivo) + 1
		for par in [[JOY_BUTTON_A, "salto"], [JOY_BUTTON_Y, "ulti"], [JOY_BUTTON_LEFT_SHOULDER, "bloqueo"]]:
			await boton(dispositivo, par[0], true)
			exigir(Input.is_action_pressed("j%d_%s" % [jugador, par[1]]), "El mando %d tiene asignado %s" % [dispositivo, par[1]])
			await boton(dispositivo, par[0], false)
		await eje(dispositivo, JOY_AXIS_TRIGGER_LEFT, 0.9)
		exigir(Input.is_action_pressed("j%d_bloqueo" % jugador), "El gatillo izquierdo permite bloquear")
		await eje(dispositivo, JOY_AXIS_TRIGGER_LEFT, 0.0)
	var nivel = load("res://escenas/juego/nivelI.tscn").instantiate()
	root.add_child(nivel)
	await create_timer(0.1).timeout
	await boton(23, JOY_BUTTON_X, true)
	await physics_frame
	await physics_frame
	exigir(nivel.jugador1.maquina_estados.es_estado_actual(&"Puño"), "X activa un puño en el personaje real")
	await boton(23, JOY_BUTTON_X, false)
	await toque(23, JOY_BUTTON_START)
	exigir(paused and nivel.get_node("MenuPausa").interfaz.visible, "START abre la pausa")
	var pausa = nivel.get_node("MenuPausa")
	await toque(23, JOY_BUTTON_DPAD_DOWN)
	exigir(root.gui_get_focus_owner() == pausa.boton_controles, "La cruceta alcanza Ver controles en la pausa compartida")
	await toque(23, JOY_BUTTON_A)
	exigir(paused and pausa.controles_visibles(), "A abre la guía manteniendo el combate pausado")
	exigir(not pausa.guia_controles.nota.texto.begins_with("EN EL TUTORIAL"), "La guía de combate explica ambos jugadores")
	await toque(23, JOY_BUTTON_DPAD_DOWN)
	exigir(root.gui_get_focus_owner() == pausa.guia_controles.boton_volver, "El foco permanece dentro de la guía")
	await escape()
	exigir(paused and not pausa.controles_visibles() and root.gui_get_focus_owner() == pausa.boton_controles, "Esc vuelve a pausa y restaura el foco sin reanudar")
	await toque(23, JOY_BUTTON_A)
	await toque(23, JOY_BUTTON_START)
	exigir(paused and not pausa.controles_visibles(), "Start cierra sólo la guía cuando está abierta")
	await toque(23, JOY_BUTTON_A)
	await boton(23, JOY_BUTTON_B, true)
	exigir(paused and not pausa.controles_visibles() and not Input.is_action_pressed("j1_patada"), "B vuelve a pausa sin dejar una patada presionada")
	await boton(23, JOY_BUTTON_B, false)
	await toque(23, JOY_BUTTON_DPAD_UP)
	await toque(23, JOY_BUTTON_A)
	exigir(not paused, "A confirma SEGUIR JUGANDO mientras el juego está pausado")
	await toque(19, JOY_BUTTON_START)
	await boton(19, JOY_BUTTON_B, true)
	exigir(not paused, "B cierra la pausa desde el otro mando")
	exigir(not Input.is_action_pressed("j2_patada"), "B para reanudar no dispara una patada")
	await boton(19, JOY_BUTTON_B, false)
	nivel.free()
	var seleccion = root.get_node("SeleccionPartida")
	var ia_anterior: bool = seleccion.contra_ia
	for contra_ia in [false, true]:
		seleccion.contra_ia = contra_ia
		for escenario in seleccion.escenarios:
			var arena = load(escenario.escena).instantiate()
			root.add_child(arena)
			await create_timer(0.1).timeout
			var gestor = arena.get_node("GestorPausa")
			var menu_pausa = arena.get_node("MenuPausa")
			gestor._pausar_combate()
			menu_pausa.boton_controles.pressed.emit()
			var posicion: Vector2 = arena.jugador1.position
			await create_timer(0.1).timeout
			exigir(paused and menu_pausa.controles_visibles() and arena.jugador1.position == posicion, "La guía pausa la arena %s con IA=%s" % [escenario.nombre, contra_ia])
			menu_pausa.guia_controles.boton_volver.pressed.emit()
			exigir(paused and not menu_pausa.controles_visibles(), "Volver conserva la pausa en %s" % escenario.nombre)
			arena.free()
	seleccion.contra_ia = ia_anterior
	_finalizar()

func _finalizar() -> void:
	print("MANDOS: %d comprobaciones, %d fallos" % [comprobaciones, fallos])
	quit(1 if fallos else 0)
