extends SceneTree

const NIVEL = preload("res://escenas/juego/nivelI.tscn")
var nivel: Node
var fallos: int = 0

func _initialize() -> void:
	call_deferred("_probar")

func exigir(valor: bool, mensaje: String) -> void:
	if not valor:
		push_error(mensaje)
		fallos += 1

func preparar(numero: int) -> Personaje:
	if is_instance_valid(nivel):
		nivel.free()
	nivel = NIVEL.instantiate()
	root.add_child(nivel)
	current_scene = nivel
	await create_timer(0.4, true, true).timeout
	nivel.jugador1.position.x = 700
	nivel.jugador2.position.x = 1400
	await physics_frame
	var jugador: Personaje = nivel.jugador1 if numero == 1 else nivel.jugador2
	jugador.set("carga_ulti", 100.0)
	return jugador

func _probar_carga(numero: int) -> void:
	var jugador: Personaje = await preparar(numero)
	var rival: Personaje = jugador.oponente
	jugador.set("carga_ulti", 0.0)
	await create_timer(0.5, true, true).timeout
	exigir(is_zero_approx(jugador.get("carga_ulti")), "Esperar no recarga la ulti")
	var barra := nivel.hud.get_node("Barras/PanelJugador%d/UltiBar%d" % [numero, numero]) as ProgressBar
	exigir(barra.fill_mode == ProgressBar.FILL_BOTTOM_TO_TOP, "La barra debe llenarse hacia arriba")
	# Un ataque fallado no carga. Los impactos pasan por la hurtbox real.
	jugador.hitbox.iniciar_ataque()
	exigir(is_zero_approx(jugador.get("carga_ulti")), "Un ataque sin impacto no carga")
	rival.hurtbox._cuando_entra_un_area(jugador.hitbox)
	exigir(is_equal_approx(jugador.get("carga_ulti"), 20.0), "Un golpe conectado carga 20")
	exigir(is_equal_approx(barra.value, 20.0), "El HUD refleja la carga del golpe")
	rival.hurtbox._cuando_entra_un_area(jugador.hitbox)
	exigir(is_equal_approx(jugador.get("carga_ulti"), 20.0), "Reentrar en el mismo golpe no duplica carga")
	jugador.hitbox.finalizar_ataque()
	Input.action_press(rival.accion("bloqueo"))
	rival.maquina_estados.cambiar_a("Bloqueando")
	jugador.hitbox.iniciar_ataque()
	rival.hurtbox._cuando_entra_un_area(jugador.hitbox)
	jugador.hitbox.finalizar_ataque()
	exigir(is_equal_approx(jugador.get("carga_ulti"), 20.0), "Un golpe bloqueado no carga")
	Input.action_release(rival.accion("bloqueo"))
	rival.maquina_estados.cambiar_a("Idle")
	for i in range(5):
		jugador.hitbox.iniciar_ataque()
		rival.hurtbox._cuando_entra_un_area(jugador.hitbox)
		jugador.hitbox.finalizar_ataque()
	exigir(is_equal_approx(jugador.get("carga_ulti"), 100.0), "La carga se limita a 100")

func _probar() -> void:
	for numero in [1, 2]:
		await _probar_carga(numero)
	for numero in [1, 2]:
		var jugador: Personaje = await preparar(numero)
		var rival: Personaje = jugador.oponente
		# Activación por la acción de cada jugador, con carga completa.
		Input.action_press(jugador.accion("ulti"))
		await physics_frame
		await physics_frame
		Input.action_release(jugador.accion("ulti"))
		exigir(jugador.maquina_estados.es_estado_actual(&"Ulti"), "La entrada debe activar la ulti")
		exigir(is_zero_approx(jugador.get("carga_ulti")), "Debe consumir la carga")
		await create_timer(0.4, true, true).timeout
		exigir(rival.vida_actual == 100, "La apertura de laptop no debe causar daño")
		await create_timer(2.5, true, true).timeout
		exigir(rival.vida_actual == 68, "Cuatro códigos deben causar 32 de daño en ambas direcciones")
		exigir(jugador.vida_actual == 100, "Sin autogolpe")
		exigir(is_zero_approx(jugador.get("carga_ulti")), "Los códigos de la ulti no recargan su propia barra")
		exigir(jugador.maquina_estados.es_estado_actual(&"Idle"), "Debe recuperar Idle")
		exigir(jugador.sprite.scale == Vector2.ONE, "Restaurar escala")
		jugador.maquina_estados.cambiar_a("Ulti")
		exigir(not jugador.maquina_estados.es_estado_actual(&"Ulti"), "Sin carga no puede repetir")
	# Cancelación antes de escribir.
	var jugador: Personaje = await preparar(1)
	jugador.maquina_estados.cambiar_a("Ulti")
	await create_timer(0.25, true, true).timeout
	jugador.recibir_golpe(10, jugador.oponente)
	await create_timer(2.0, true, true).timeout
	exigir(jugador.oponente.vida_actual == 100, "La interrupción cancela disparos pendientes")
	exigir(get_nodes_in_group("proyectiles_codigo").is_empty(), "No quedan proyectiles")
	# Bloqueo usa la defensa existente y consume stamina.
	jugador = await preparar(1)
	var rival: Personaje = jugador.oponente
	Input.action_press(rival.accion("bloqueo"))
	rival.maquina_estados.cambiar_a("Bloqueando")
	jugador.maquina_estados.cambiar_a("Ulti")
	await create_timer(2.8, true, true).timeout
	exigir(rival.vida_actual == 100, "Bloquear evita el daño de código")
	exigir(rival.stamina_actual < 10, "Los cuatro bloqueos consumen stamina")
	Input.action_release(rival.accion("bloqueo"))
	# Pausa congela la escritura y los proyectiles.
	jugador = await preparar(1)
	jugador.maquina_estados.cambiar_a("Ulti")
	await create_timer(0.8, true, true).timeout
	var estado: Node = jugador.maquina_estados.estado_actual
	var tiempo: float = estado.get("tiempo")
	paused = true
	await create_timer(0.2, true).timeout
	exigir(is_equal_approx(estado.get("tiempo"), tiempo), "Pausa congela la ulti")
	paused = false
	await create_timer(3.0, true, true).timeout
	exigir(get_nodes_in_group("proyectiles_codigo").is_empty(), "Se limpian impactos y proyectiles")
	# Activación desde agachado restaura la hurtbox; un impacto final dispara KO.
	jugador = await preparar(1)
	jugador.maquina_estados.cambiar_a("Agacharse")
	await physics_frame
	jugador.maquina_estados.cambiar_a("Ulti")
	var forma := jugador.hurtbox.get_node("CollisionShape2D") as CollisionShape2D
	exigir((forma.shape as RectangleShape2D).size == Vector2(277, 411), "La ulti restaura la hurtbox de pie")
	jugador.oponente.vida_actual = 8
	await create_timer(1.5, true, true).timeout
	exigir(jugador.oponente.vida_actual == 0, "Los códigos pueden causar KO")
	exigir(get_nodes_in_group("proyectiles_codigo").is_empty(), "El KO limpia los códigos en vuelo")
	nivel.free()
	print("ULTI: ", fallos, " fallos")
	quit(1 if fallos else 0)
