extends SceneTree

const NIVEL: PackedScene = preload("res://escenas/juego/nivelI.tscn")
var impactos: Array[float] = []
var ruta_captura: String = ""


func _initialize() -> void:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--captura="):
			ruta_captura = argumento.trim_prefix("--captura=")
	call_deferred("_probar")


func _probar() -> void:
	for numero in [1, 2]:
		await _probar_jugador(numero)
	await _probar_transiciones()
	print("PATADA: todas las comprobaciones pasaron")
	quit()


func _crear_nivel() -> Node:
	var nivel := NIVEL.instantiate()
	root.add_child(nivel)
	current_scene = nivel
	await create_timer(0.4, true, true).timeout
	return nivel


func _colocar(nivel: Node) -> void:
	nivel.jugador1.position.x = 800.0
	nivel.jugador2.position.x = 1120.0


func _tecla_patada(numero: int, presionada: bool = true) -> void:
	var evento := InputEventKey.new()
	evento.physical_keycode = KEY_K if numero == 1 else KEY_2
	evento.pressed = presionada
	Input.parse_input_event(evento)
	Input.flush_buffered_events()


func _registrar_impacto(_danio: int, atacante: Personaje, _factor: float) -> void:
	impactos.append(absf(atacante.oponente.velocity.x))


func _probar_jugador(numero: int) -> void:
	var nivel: Node = await _crear_nivel()
	_colocar(nivel)
	var atacante: Personaje = nivel.jugador1 if numero == 1 else nivel.jugador2
	var defensor: Personaje = atacante.oponente
	defensor.hurtbox.golpe_recibido.connect(_registrar_impacto)
	impactos.clear()
	await physics_frame
	_tecla_patada(numero)
	await process_frame
	_exigir(atacante.maquina_estados.es_estado_actual(&"Patada"))
	await create_timer(0.1, true, true).timeout
	_exigir(defensor.vida_actual == 100, "La preparación no debe golpear")
	_exigir(atacante.hitbox.get_node("CollisionShape2D").disabled)
	await create_timer(0.14, true, true).timeout
	_exigir(defensor.vida_actual == 90, "La patada debe golpear una vez")
	_exigir(atacante.vida_actual == 100, "No debe haber autogolpe")
	_exigir(impactos.size() == 1)
	_exigir(is_equal_approx(impactos[0], 360.0))
	_exigir(atacante.direccion_mirada == (1 if numero == 1 else -1))
	_exigir(signf(defensor.velocity.x) == float(atacante.direccion_mirada))
	# Simula reentrada en el área durante el mismo ataque.
	defensor.hurtbox._cuando_entra_un_area(atacante.hitbox)
	defensor.hurtbox._cuando_entra_un_area(atacante.hitbox)
	_exigir(defensor.vida_actual == 90)
	if DisplayServer.get_name() != "headless" and numero == 1 and not ruta_captura.is_empty():
		await RenderingServer.frame_post_draw
		_exigir(root.get_texture().get_image().save_png(ruta_captura) == OK)
	_tecla_patada(numero, false)
	await create_timer(0.6, true, true).timeout
	_exigir(atacante.maquina_estados.es_estado_actual(&"Idle"))
	_exigir(not atacante.hitbox.ataque_en_curso)
	var forma := atacante.hitbox.get_node("CollisionShape2D") as CollisionShape2D
	_exigir(forma.disabled)
	_exigir(forma.position == Vector2(163, -39))
	_exigir((forma.shape as RectangleShape2D).size == Vector2(94, 76))
	_exigir(is_equal_approx(atacante.hitbox.multiplicador_retroceso, 1.0))
	# El puño posterior conserva su impulso original y vuelve a golpear.
	_colocar(nivel)
	atacante.maquina_estados.cambiar_a("Puño")
	await create_timer(0.6, true, true).timeout
	_exigir(defensor.vida_actual == 80)
	_exigir(impactos.size() == 2)
	_exigir(is_equal_approx(impactos[1], 180.0))
	# Un bloqueo recibe más empuje pero sigue evitando daño.
	_colocar(nivel)
	Input.action_press(defensor.accion("bloqueo"))
	defensor.maquina_estados.cambiar_a("Bloqueando")
	_tecla_patada(numero)
	await create_timer(0.25, true, true).timeout
	_exigir(defensor.vida_actual == 80)
	_exigir(is_equal_approx(defensor.stamina_actual, 75.0))
	_exigir(impactos.size() == 3)
	_exigir(is_equal_approx(impactos[2], 220.0))
	Input.action_release(defensor.accion("bloqueo"))
	_tecla_patada(numero, false)
	await create_timer(0.6, true, true).timeout
	# La patada interrumpida limpia la forma y no deja un golpe pendiente.
	_colocar(nivel)
	_tecla_patada(numero)
	await create_timer(0.08, true, true).timeout
	atacante.recibir_golpe(10, defensor)
	await physics_frame
	_exigir(atacante.maquina_estados.es_estado_actual(&"RecibirGolpe"))
	_exigir(forma.disabled and not atacante.hitbox.ataque_en_curso)
	_exigir(forma.position == Vector2(163, -39))
	_tecla_patada(numero, false)
	await create_timer(0.6, true, true).timeout
	_exigir(defensor.vida_actual == 80)
	# Un golpe final de patada conserva KO y celebración.
	_colocar(nivel)
	defensor.vida_actual = 10
	_tecla_patada(numero)
	await create_timer(0.25, true, true).timeout
	_exigir(defensor.vida_actual == 0)
	_exigir(defensor.maquina_estados.es_estado_actual(&"KO"))
	_exigir(is_equal_approx(impactos.back(), 520.0))
	_tecla_patada(numero, false)
	await create_timer(5.0, true, true).timeout
	_exigir(atacante.maquina_estados.es_estado_actual(&"Victoria"))
	_exigir(nivel.combate_finalizado)
	print("PATADA OK jugador ", numero, ": daño, bloqueo, recuperación, interrupción y KO")
	nivel.queue_free()
	await process_frame
	await process_frame
	_exigir(is_equal_approx(Engine.time_scale, 1.0))


func _probar_transiciones() -> void:
	var nivel: Node = await _crear_nivel()
	var jugador: Personaje = nivel.jugador1
	for nombre_estado in ["Caminar", "Agacharse"]:
		Input.action_press(jugador.accion("derecha") if nombre_estado == "Caminar" else jugador.accion("agacharse"))
		jugador.maquina_estados.cambiar_a(nombre_estado)
		_tecla_patada(1)
		await process_frame
		_exigir(jugador.maquina_estados.es_estado_actual(&"Patada"))
		_tecla_patada(1, false)
		await create_timer(0.8, true, true).timeout
		_exigir(jugador.maquina_estados.es_estado_actual(StringName(nombre_estado)))
		Input.action_release(jugador.accion("derecha"))
		Input.action_release(jugador.accion("agacharse"))
		jugador.maquina_estados.cambiar_a("Idle")
	# La pausa congela una patada en curso.
	_tecla_patada(1)
	await create_timer(0.1, true, true).timeout
	var gestor: Node = nivel.get_node("GestorPausa")
	gestor._pausar_combate()
	var tiempo: float = jugador.animacion.current_animation_position
	await create_timer(0.2, true).timeout
	_exigir(is_equal_approx(jugador.animacion.current_animation_position, tiempo))
	gestor._reanudar_combate()
	_tecla_patada(1, false)
	await create_timer(0.8, true, true).timeout
	_exigir(jugador.maquina_estados.es_estado_actual(&"Idle"))
	gestor._reiniciar_combate()
	await create_timer(0.5, true, true).timeout
	_exigir(current_scene != nivel)
	_exigir(current_scene.jugador1.vida_actual == 100)
	_exigir(current_scene.jugador1.maquina_estados.es_estado_actual(&"Idle"))
	current_scene.get_node("GestorPausa")._volver_al_menu()
	await create_timer(0.5, true, true).timeout
	_exigir(current_scene.scene_file_path == "res://escenas/menu/menu.tscn")
	_exigir(not paused and is_equal_approx(Engine.time_scale, 1.0))
	print("PATADA OK entradas caminando/agachado, pausa, reinicio y menú")


func _exigir(condicion: bool, mensaje: String = "Comprobación fallida") -> void:
	if not condicion:
		push_error(mensaje)
		print_stack()
		quit(1)
