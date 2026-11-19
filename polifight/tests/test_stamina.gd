extends SceneTree
## Recarga normal, ruptura de defensa y reactivación al llenar la barra real.

const NIVEL = preload("res://escenas/juego/nivelI.tscn")
var fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _exigir(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos += 1
		push_error(mensaje)


func _intentar_bloquear(jugador: Personaje) -> void:
	var evento := InputEventAction.new()
	evento.action = jugador.accion("bloqueo")
	evento.pressed = true
	Input.action_press(evento.action)
	jugador.maquina_estados._input(evento)
	Input.action_release(evento.action)


func _probar() -> void:
	var nivel := NIVEL.instantiate()
	root.add_child(nivel)
	current_scene = nivel
	await create_timer(0.4).timeout
	# Avanzar la recarga con deltas exactos, sin depender del ritmo de renderizado.
	nivel.process_mode = Node.PROCESS_MODE_DISABLED
	for jugador: Personaje in [nivel.jugador1, nivel.jugador2]:
		var barra := nivel.hud.get_node("Barras/PanelJugador%d/StaminaBar%d" % [jugador.numero_jugador, jugador.numero_jugador]) as ProgressBar
		jugador._cambiar_stamina(50.0)
		jugador._process(1.0)
		_exigir(is_equal_approx(jugador.stamina_actual, 62.0), "La stamina parcial debe recargarse a la velocidad normal")
		_exigir(not jugador.stamina_agotada and jugador.puede_bloquear(), "Gastar parte de la barra no debe exigir llenarla")
		_intentar_bloquear(jugador)
		_exigir(jugador.maquina_estados.es_estado_actual(&"Bloqueando"), "La entrada real permite bloquear con stamina parcial")
		jugador._process(1.0)
		_exigir(is_equal_approx(jugador.stamina_actual, 62.0), "La recarga no debe avanzar mientras bloquea")
		jugador._cambiar_stamina(50.0)
		jugador.recibir_golpe(10, jugador.oponente)
		jugador.recibir_golpe(10, jugador.oponente)
		_exigir(is_zero_approx(jugador.stamina_actual) and jugador.stamina_agotada, "Dos bloqueos con 50 de stamina deben romper la defensa")
		_exigir(jugador.vida_actual == jugador.vida_maxima, "El último bloqueo sigue evitando daño")
		jugador.maquina_estados.cambiar_a("Idle")
		jugador._process(1.0)
		_exigir(is_equal_approx(jugador.stamina_actual, 6.0), "Tras agotarse debe recargar a la mitad de velocidad")
		for carga in [25.0, 60.0, 99.99]:
			jugador._cambiar_stamina(carga)
			_exigir(jugador.stamina_agotada and not jugador.puede_bloquear(), "Recargar parcialmente no debe habilitar la defensa")
			_intentar_bloquear(jugador)
			_exigir(jugador.maquina_estados.es_estado_actual(&"Idle"), "La entrada de bloqueo debe rechazarse hasta llenar la barra")
		jugador._process(1.0)
		_exigir(jugador.stamina_actual == jugador.stamina_maxima and not jugador.stamina_agotada, "Al llenarse debe terminar el agotamiento sin exceder el máximo")
		_exigir(is_equal_approx(barra.value, barra.max_value), "El HUD debe reflejar la recarga completa")
		_intentar_bloquear(jugador)
		_exigir(jugador.maquina_estados.es_estado_actual(&"Bloqueando"), "Al llenarse la barra vuelve a funcionar el bloqueo")
		jugador.recibir_golpe(10, jugador.oponente)
		jugador.maquina_estados.cambiar_a("Idle")
		jugador._process(1.0)
		_exigir(is_equal_approx(jugador.stamina_actual, 87.0), "Después de recuperarse debe volver a recargar a velocidad normal")
		_exigir(is_equal_approx(barra.value, jugador.stamina_actual), "El HUD debe seguir el consumo y la recarga")
	# La pausa también congela la recarga lenta.
	var jugador: Personaje = nivel.jugador1
	jugador._cambiar_stamina(0.0)
	nivel.process_mode = Node.PROCESS_MODE_INHERIT
	paused = true
	await create_timer(0.15, true).timeout
	_exigir(is_zero_approx(jugador.stamina_actual), "La pausa debe detener la recarga de stamina")
	paused = false
	await create_timer(0.1).timeout
	_exigir(jugador.stamina_actual > 0.0 and jugador.stamina_agotada, "Reanudar debe continuar la recarga lenta")
	nivel.get_node("GestorPausa")._reiniciar_combate()
	await process_frame
	await process_frame
	_exigir(current_scene.jugador1.stamina_actual == current_scene.jugador1.stamina_maxima and not current_scene.jugador1.stamina_agotada, "Reiniciar el combate debe restaurar la defensa")
	print("STAMINA: %d fallos" % fallos)
	quit(1 if fallos else 0)
