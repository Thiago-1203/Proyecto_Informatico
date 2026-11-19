extends SceneTree

const NIVEL = preload("res://escenas/juego/nivelI.tscn")
var fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _exigir(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos += 1
		push_error(mensaje)


func _entrada(jugador: Personaje, accion: String, pulsada: bool) -> void:
	var evento := InputEventAction.new()
	evento.action = jugador.accion(accion)
	evento.pressed = pulsada
	Input.parse_input_event(evento)
	Input.flush_buffered_events()
	await physics_frame
	await process_frame


func _probar() -> void:
	for numero in [1, 2]:
		var nivel := NIVEL.instantiate()
		root.add_child(nivel)
		current_scene = nivel
		await create_timer(0.4).timeout
		var jugador: Personaje = nivel.jugador1 if numero == 1 else nivel.jugador2
		var otro: Personaje = jugador.oponente
		var hacia := "derecha" if numero == 1 else "izquierda"
		var contrario := "izquierda" if numero == 1 else "derecha"
		var signo := 1.0 if numero == 1 else -1.0
		var forma := jugador.hurtbox.get_node("CollisionShape2D") as CollisionShape2D
		await _entrada(jugador, "agacharse", true)
		_exigir(jugador.maquina_estados.es_estado_actual(&"Agacharse"), "Abajo sin dirección debe agachar al jugador %d" % numero)
		await _entrada(jugador, hacia, true)
		_exigir(jugador.maquina_estados.es_estado_actual(&"CaminarAgachado"), "Abajo y dirección deben activar CaminarAgachado")
		_exigir(jugador.animacion.current_animation == "Caminar_Agachado", "Debe usar los sprites existentes")
		_exigir(forma.shape.size == Vector2(263.87, 200), "Debe conservar la hurtbox agachada al entrar desde quieto")
		var inicio := jugador.position.x
		var inicio_otro := otro.position
		var texturas := {}
		for i in 70:
			await physics_frame
			texturas[jugador.sprite.texture.resource_path] = true
		_exigir(texturas.size() == 3 and jugador.animacion.is_playing(), "La animación debe recorrer los tres sprites y continuar en bucle")
		_exigir((jugador.position.x - inicio) * signo > 100.0, "Debe avanzar en la dirección elegida")
		_exigir(is_equal_approx(absf(jugador.velocity.x), jugador.SPEED * 0.5), "Debe caminar agachado a la mitad de velocidad")
		_exigir(otro.position.is_equal_approx(inicio_otro), "Los controles de un jugador no deben mover al otro")
		await _entrada(jugador, hacia, false)
		_exigir(jugador.maquina_estados.es_estado_actual(&"Agacharse") and is_zero_approx(jugador.velocity.x), "Soltar la dirección debe dejarlo agachado y quieto")
		_exigir(jugador.sprite.scale == Vector2.ONE, "La pose quieta debe recuperar su escala")
		await _entrada(jugador, hacia, true)
		await _entrada(jugador, "agacharse", false)
		_exigir(jugador.maquina_estados.es_estado_actual(&"Caminar") and jugador.sprite.scale == Vector2.ONE, "Soltar abajo debe pasar a caminar de pie")
		_exigir(forma.shape.size == Vector2(277, 411), "Caminar de pie debe restaurar la hurtbox")
		await _entrada(jugador, "agacharse", true)
		_exigir(jugador.maquina_estados.es_estado_actual(&"CaminarAgachado"), "Debe entrar también desde caminar de pie")
		await _entrada(jugador, contrario, true)
		_exigir(jugador.maquina_estados.es_estado_actual(&"Agacharse"), "Las direcciones opuestas deben dejarlo quieto")
		await _entrada(jugador, contrario, false)
		await _entrada(jugador, "bloqueo", true)
		_exigir(jugador.maquina_estados.es_estado_actual(&"Bloqueando"), "Debe poder bloquear desde CaminarAgachado")
		await _entrada(jugador, "bloqueo", false)
		_exigir(jugador.maquina_estados.es_estado_actual(&"CaminarAgachado"), "Al soltar bloqueo debe recuperar la diagonal mantenida")
		await _entrada(jugador, "patada", true)
		_exigir(jugador.maquina_estados.es_estado_actual(&"Patada") and jugador.sprite.scale == Vector2.ONE, "Debe poder atacar con la escala normal del golpe")
		await _entrada(jugador, "patada", false)
		await create_timer(0.85).timeout
		_exigir(jugador.maquina_estados.es_estado_actual(&"CaminarAgachado"), "Tras atacar debe recuperar la diagonal sin otra pulsación")
		jugador.recibir_golpe(1, otro)
		await create_timer(0.6).timeout
		_exigir(jugador.maquina_estados.es_estado_actual(&"CaminarAgachado"), "Tras recibir daño debe recuperar la diagonal mantenida")
		await _entrada(jugador, "salto", true)
		_exigir(jugador.maquina_estados.es_estado_actual(&"Saltar"), "Debe poder saltar desde CaminarAgachado")
		await _entrada(jugador, "salto", false)
		await _entrada(jugador, hacia, false)
		await create_timer(1.8).timeout
		_exigir(jugador.is_on_floor() and jugador.maquina_estados.es_estado_actual(&"Agacharse"), "Al aterrizar con abajo debe seguir agachado")
		await _entrada(jugador, hacia, true)
		jugador.set("carga_ulti", 100.0)
		_exigir(jugador.call("puede_usar_ulti"), "CaminarAgachado debe permitir activar la ulti")
		var posicion := jugador.position
		var tiempo: float = jugador.animacion.current_animation_position
		paused = true
		await create_timer(0.15, true).timeout
		_exigir(jugador.position == posicion and is_equal_approx(jugador.animacion.current_animation_position, tiempo), "La pausa debe detener desplazamiento y animación")
		paused = false
		await _entrada(jugador, hacia, false)
		await _entrada(jugador, "agacharse", false)
		_exigir(jugador.maquina_estados.es_estado_actual(&"Idle"), "Soltar todo debe volver a Idle")
		nivel.free()
		await process_frame
	print("CAMINAR AGACHADO: %d fallos" % fallos)
	quit(1 if fallos else 0)
