extends SceneTree

const NIVEL = preload("res://escenas/juego/nivelI.tscn")
var fallos: int = 0


func _initialize() -> void:
	call_deferred("_probar")


func _exigir(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos += 1
		push_error(mensaje)


func _entrada(jugador: Personaje, nombre: String) -> void:
	var evento := InputEventAction.new()
	evento.action = jugador.accion(nombre)
	evento.pressed = true
	Input.parse_input_event(evento)
	Input.flush_buffered_events()
	await process_frame
	evento = evento.duplicate()
	evento.pressed = false
	Input.parse_input_event(evento)
	Input.flush_buffered_events()


func _probar() -> void:
	var nivel := NIVEL.instantiate()
	root.add_child(nivel)
	current_scene = nivel
	await create_timer(0.4, false, true).timeout
	for jugador: Personaje in [nivel.jugador1, nivel.jugador2]:
		await _entrada(jugador, "patada")
		_exigir(jugador.maquina_estados.es_estado_actual(&"Patada"), "El primer ataque debe estar disponible")
		jugador.maquina_estados.cambiar_a("Puño")
		_exigir(jugador.maquina_estados.es_estado_actual(&"Patada"), "No debe cancelar el golpe actual con otro ataque")
		await create_timer(0.75, false, true).timeout
		_exigir(jugador.maquina_estados.es_estado_actual(&"Idle") and not jugador.puede_atacar(), "Debe haber recuperación después de la animación")
		var restante := jugador.cooldown_ataque_restante
		for i in 10:
			jugador.maquina_estados.cambiar_a("Puño")
			jugador.maquina_estados.cambiar_a("Patada")
		_exigir(jugador.maquina_estados.es_estado_actual(&"Idle"), "Spamear o alternar ataques no debe saltar la recuperación")
		_exigir(jugador.cooldown_ataque_restante == restante, "Los intentos rechazados no deben reiniciar el contador")
		# El cooldown permite moverse y defenderse, y se congela durante la pausa.
		jugador.maquina_estados.cambiar_a("Caminar")
		jugador.maquina_estados.cambiar_a("Bloqueando")
		_exigir(jugador.maquina_estados.es_estado_actual(&"Bloqueando"), "Debe poder defenderse durante la recuperación")
		paused = true
		await create_timer(0.2, true).timeout
		_exigir(jugador.cooldown_ataque_restante == restante, "La pausa debe congelar el cooldown")
		paused = false
		jugador.maquina_estados.cambiar_a("Idle")
		await create_timer(restante + 0.05, false, true).timeout
		await _entrada(jugador, "ataque")
		_exigir(jugador.maquina_estados.es_estado_actual(&"Puño"), "El puño debe volver a funcionar al terminar la recuperación")
		# Interrumpir un ataque también activa la recuperación compartida.
		jugador.recibir_golpe(1, jugador.oponente)
		_exigir(jugador.cooldown_ataque_restante > 0.0, "Interrumpir el puño debe conservar la recuperación")
		jugador.maquina_estados.cambiar_a("Patada")
		_exigir(jugador.maquina_estados.es_estado_actual(&"RecibirGolpe"), "Recibir daño no debe permitir eludir el cooldown")
		await create_timer(1.0, false, true).timeout
	# Todas las dificultades usan la misma barrera aunque quieran atacar cada frame.
	var cpu: Personaje = nivel.jugador2
	cpu.controlado_por_ia = true
	for dificultad in 3:
		cpu.controlador_ia = load("res://scripts/juego/ia_combate.gd").new(dificultad)
		cpu.maquina_estados.cambiar_a("Patada")
		await create_timer(0.75, false, true).timeout
		_exigir(not cpu.puede_atacar(), "La IA debe tener recuperación en las tres dificultades")
		cpu.maquina_estados.cambiar_a("Puño")
		_exigir(not cpu.maquina_estados.es_estado_actual(&"Puño"), "La IA no debe saltar el cooldown alternando ataques")
		await create_timer(0.7, false, true).timeout
	nivel.get_node("GestorPausa")._reiniciar_combate()
	await process_frame
	await process_frame
	_exigir(current_scene.jugador1.puede_atacar() and current_scene.jugador2.puede_atacar(), "Reiniciar debe recuperar el primer ataque")
	print("COOLDOWN: %d fallos" % fallos)
	quit(1 if fallos else 0)
