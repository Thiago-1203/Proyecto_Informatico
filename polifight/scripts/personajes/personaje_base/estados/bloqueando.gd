extends Estado_base


func start() -> void:
	nodo_controlado.velocity.x = 0.0
	nodo_controlado.play_animation(&"bloqueo")


func on_physics_process(delta: float) -> void:
	nodo_controlado.velocity.x = move_toward(
		nodo_controlado.velocity.x,
		0.0,
		nodo_controlado.frenado_retroceso * delta
	)

	if not nodo_controlado.is_on_floor():
		gravity(delta)

	nodo_controlado.move_and_slide()

	var bloqueo := nodo_controlado.accion("bloqueo")
	var retroceso_finalizado := is_zero_approx(nodo_controlado.velocity.x)
	var bloqueo_agotado := not nodo_controlado.puede_bloquear()
	if retroceso_finalizado and (not Input.is_action_pressed(bloqueo) or bloqueo_agotado):
		_volver_a_movimiento()


func on_input(_event: InputEvent) -> void:
	var bloqueo := nodo_controlado.accion("bloqueo")
	if not Input.is_action_pressed(bloqueo) and is_zero_approx(nodo_controlado.velocity.x):
		_volver_a_movimiento()


func gravity(delta: float) -> void:
	nodo_controlado.velocity.y += nodo_controlado.GRAVITY * delta


func _volver_a_movimiento() -> void:
	var izquierda := nodo_controlado.accion("izquierda")
	var derecha := nodo_controlado.accion("derecha")
	var agacharse := nodo_controlado.accion("agacharse")
	var direccion := Input.get_axis(izquierda, derecha)

	if Input.is_action_pressed(agacharse) and nodo_controlado.is_on_floor():
		maquina_estados.cambiar_a("Agacharse")
	elif direccion == 0.0:
		maquina_estados.cambiar_a("Idle")
	else:
		maquina_estados.cambiar_a("Caminar")
