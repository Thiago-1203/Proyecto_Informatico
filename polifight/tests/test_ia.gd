extends SceneTree

const SELECTOR = preload("res://escenas/menu/selector_combate.tscn")
const NIVEL = preload("res://escenas/juego/nivelI.tscn")
var fallos: int = 0


func _initialize() -> void:
	call_deferred("_probar")


func _exigir(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos += 1
		push_error(mensaje)


func _tecla(selector: Control, tecla: Key) -> void:
	var evento := InputEventKey.new()
	evento.physical_keycode = tecla
	evento.pressed = true
	selector._habilitado = true
	selector._input(evento)


func _probar() -> void:
	var seleccion: EstadoSeleccionPartida = root.get_node("SeleccionPartida")
	for dificultad in 3:
		var selector := SELECTOR.instantiate()
		root.add_child(selector)
		await selector.aparicion_finalizada
		_exigir(selector.paso == selector.Paso.RIVAL, "Debe comenzar eligiendo rival")
		_tecla(selector, KEY_DOWN)
		_tecla(selector, KEY_ENTER)
		_exigir(seleccion.contra_ia and selector.paso == selector.Paso.DIFICULTAD, "Debe ofrecer la dificultad al elegir IA")
		selector._confirmar_configuracion(dificultad)
		_exigir(seleccion.dificultad_ia == dificultad, "Debe guardar la dificultad elegida")
		_tecla(selector, KEY_F)
		_exigir(selector.listos == [true, false], "Un jugador debe confirmar primero su luchador")
		_tecla(selector, KEY_F)
		_exigir(selector.listos == [true, true], "El mismo teclado debe confirmar al luchador de la IA")
		_tecla(selector, KEY_F)
		_exigir(selector.paso == selector.Paso.ESCENARIO, "La partida en solitario debe llegar a escenarios")
		await selector.aparicion_finalizada
		selector._volver()
		await selector.aparicion_finalizada
		_exigir(selector.listos == [false, false] and seleccion.contra_ia, "Volver debe permitir cambiar ambos luchadores y conservar el rival")
		selector._volver()
		_exigir(selector.paso == selector.Paso.DIFICULTAD, "Debe permitir cambiar dificultad")
		selector._volver()
		selector._confirmar_configuracion(0)
		_exigir(not seleccion.contra_ia, "Cambiar a persona debe desactivar la IA")
		selector.queue_free()
		await process_frame

		seleccion.contra_ia = true
		seleccion.dificultad_ia = dificultad as EstadoSeleccionPartida.Dificultad
		var nivel := NIVEL.instantiate()
		root.add_child(nivel)
		current_scene = nivel
		var humano: Personaje = nivel.jugador1
		var cpu: Personaje = nivel.jugador2
		_exigir(cpu.controlado_por_ia and not humano.controlado_por_ia, "Solo J2 debe ser IA")
		_exigir(cpu.dificultad_ia == dificultad, "El combate debe usar la dificultad seleccionada")
		cpu.controlador_ia.azar.seed = 100 + dificultad
		var inicio := cpu.position.x
		for i in 180:
			await physics_frame
		_exigir(cpu.position.x < inicio - 100.0, "La IA debe acercarse al rival")
		paused = true
		var posicion := cpu.position
		var espera: float = cpu.controlador_ia.espera
		await create_timer(0.2, true).timeout
		_exigir(cpu.position == posicion and cpu.controlador_ia.espera == espera, "La pausa debe detener la IA")
		paused = false
		for i in 1800:
			await physics_frame
			if humano.vida_actual < humano.vida_maxima:
				break
		_exigir(humano.vida_actual < humano.vida_maxima, "La IA debe causar daño en cada dificultad")
		nivel.hud.mostrar_ganador(2)
		_exigir(nivel.hud.texto_ganador.texto == "LA IA GANA!", "La victoria debe identificar a la IA")
		# Una tecla de J2 no debe cambiar las decisiones de la CPU.
		var estado := cpu.maquina_estados.estado_actual
		var tecla := InputEventAction.new()
		tecla.action = &"j2_patada"
		tecla.pressed = true
		cpu.maquina_estados._input(tecla)
		_exigir(cpu.maquina_estados.estado_actual == estado, "Los controles de J2 deben ignorarse contra IA")
		# Provocar un ataque visible para comprobar la decisión defensiva y la stamina.
		cpu.controlador_ia.perfil = cpu.controlador_ia.perfil.duplicate()
		cpu.controlador_ia.perfil.defensa = 1.0
		cpu.position.x = humano.position.x + 320.0
		cpu.maquina_estados.cambiar_a("Idle")
		humano.maquina_estados.cambiar_a("Patada")
		cpu.controlador_ia.espera = 0.0
		cpu.controlador_ia.actualizar(cpu, 0.016)
		_exigir(cpu.entrada_presionada(&"j2_bloqueo"), "La IA debe detectar y bloquear un ataque")
		cpu.stamina_actual = 0.0
		cpu.stamina_agotada = true
		cpu.controlador_ia.espera = 0.0
		cpu.controlador_ia.actualizar(cpu, 0.016)
		_exigir(not cpu.entrada_presionada(&"j2_bloqueo"), "La IA debe respetar el agotamiento de stamina")
		humano.recibir_golpe(humano.vida_maxima, cpu)
		cpu.controlador_ia.actualizar(cpu, 0.016)
		_exigir(cpu.controlador_ia.acciones.is_empty(), "La IA debe detenerse al terminar el combate")
		nivel.get_node("GestorPausa")._reiniciar_combate()
		await process_frame
		await process_frame
		_exigir(current_scene.jugador2.controlado_por_ia and current_scene.jugador2.dificultad_ia == dificultad, "Reiniciar debe conservar IA y dificultad")
		current_scene.queue_free()
		await process_frame
	seleccion.reiniciar()
	var persona := seleccion.crear_jugador(2)
	_exigir(not persona.controlado_por_ia, "Un nuevo duelo humano debe recuperar los controles locales")
	persona.free()
	print("IA: %d fallos" % fallos)
	quit(1 if fallos else 0)
