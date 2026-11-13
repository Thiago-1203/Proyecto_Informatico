extends SceneTree

const NIVEL = preload("res://escenas/juego/nivelI.tscn")
var fallos: int = 0


func _initialize() -> void:
	call_deferred("_probar")


func _exigir(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos += 1
		push_error(mensaje)


func _probar() -> void:
	var seleccion: EstadoSeleccionPartida = root.get_node("SeleccionPartida")
	for dificultad in 3:
		seleccion.contra_ia = true
		seleccion.dificultad_ia = dificultad as EstadoSeleccionPartida.Dificultad
		var nivel := NIVEL.instantiate()
		root.add_child(nivel)
		current_scene = nivel
		var cpu: Personaje = nivel.jugador2
		var rival: Personaje = nivel.jugador1
		cpu.controlador_ia.azar.seed = 420 + dificultad
		rival.vida_maxima = 10000
		rival.vida_actual = 10000
		var retrocedio := false
		var salto := false
		var avanzo := false
		var salto_con_desplazamiento := false
		for i in 2400:
			await physics_frame
			var hacia := signf(rival.position.x - cpu.position.x)
			if cpu.is_on_floor() and cpu.maquina_estados.es_estado_actual(&"Caminar"):
				retrocedio = retrocedio or cpu.velocity.x * hacia < -10.0
				avanzo = avanzo or cpu.velocity.x * hacia > 10.0
			if cpu.maquina_estados.es_estado_actual(&"Saltar") and cpu.velocity.y < 0.0:
				salto = true
				salto_con_desplazamiento = salto_con_desplazamiento or absf(cpu.velocity.x) > 10.0
			if retrocedio and avanzo and salto and salto_con_desplazamiento and rival.vida_actual < 10000:
				break
		_exigir(avanzo, "La IA debe seguir acercándose para luchar")
		_exigir(retrocedio, "La IA debe retroceder en las tres dificultades")
		_exigir(salto, "La IA debe saltar en las tres dificultades")
		_exigir(salto_con_desplazamiento, "La IA debe mantener su dirección durante el salto")
		_exigir(rival.vida_actual < 10000, "Los movimientos evasivos no deben impedir que ataque")
		# No repetir el salto inmediatamente al aterrizar.
		await create_timer(0.1, false, true).timeout
		cpu.controlador_ia.descanso_salto = 2.0
		cpu.controlador_ia.perfil = cpu.controlador_ia.perfil.duplicate()
		cpu.controlador_ia.perfil.salto = 1.0
		cpu.maquina_estados.cambiar_a("Idle")
		cpu.controlador_ia.espera = 0.0
		cpu.controlador_ia.actualizar(cpu, 0.016)
		_exigir(not cpu.entrada_presionada(cpu.accion("salto")), "La IA debe esperar entre saltos")
		paused = true
		var descanso: float = cpu.controlador_ia.descanso_salto
		var movimiento: float = cpu.controlador_ia.movimiento_restante
		await create_timer(0.2, true).timeout
		_exigir(cpu.controlador_ia.descanso_salto == descanso and cpu.controlador_ia.movimiento_restante == movimiento, "La pausa debe congelar los tiempos de movimiento")
		paused = false
		nivel.queue_free()
		await process_frame
	seleccion.reiniciar()
	print("MOVIMIENTO IA: %d fallos" % fallos)
	quit(1 if fallos else 0)
