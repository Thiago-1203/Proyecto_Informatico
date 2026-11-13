extends Estado_base



func start()->void:
	nodo_controlado.velocity.y = nodo_controlado.JUMP_VELOCITY
	nodo_controlado.play_animation("salto")

func on_physics_process(delta: float) -> void:
	var izquierda := nodo_controlado.accion("izquierda")
	var derecha := nodo_controlado.accion("derecha")
	var agacharse := nodo_controlado.accion("agacharse")
	var direccion := nodo_controlado.eje_entrada(izquierda, derecha)
	nodo_controlado.velocity.x = direccion * nodo_controlado.SPEED
	
	if not nodo_controlado.is_on_floor():
		gravity(delta)
	
	
	
	if nodo_controlado.velocity.y < 0.0:
		nodo_controlado.play_animation("salto")
	else:
		nodo_controlado.play_animation("caida")
		
	nodo_controlado.move_and_slide()
	
	if nodo_controlado.is_on_floor():
		if nodo_controlado.entrada_presionada(agacharse):
			maquina_estados.cambiar_a("Agacharse")
		elif direccion == 0.0:
			maquina_estados.cambiar_a("Idle")
		else:
			maquina_estados.cambiar_a("Caminar")
	
func gravity(delta) -> void:
	nodo_controlado.velocity.y += (
		nodo_controlado.GRAVITY
		* nodo_controlado.JUMP_GRAVITY_MULTIPLIER
		* delta
	)
	
func on_input(_event)->void:
	var ataque := nodo_controlado.accion("ataque")
	
	
	if nodo_controlado.entrada_recien_presionada(ataque):
		maquina_estados.cambiar_a("Puño")
