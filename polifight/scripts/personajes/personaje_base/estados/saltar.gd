extends Estado_base



func start()->void:
	nodo_controlado.velocity.y = nodo_controlado.JUMP_VELOCITY
	nodo_controlado.play_animation("salto")

func on_physics_process(delta: float) -> void:
	var izquierda := nodo_controlado.accion("izquierda")
	var derecha := nodo_controlado.accion("derecha")
	var direccion := Input.get_axis(izquierda, derecha)
	nodo_controlado.velocity.x = direccion * nodo_controlado.SPEED
	
	if not nodo_controlado.is_on_floor():
		gravity(delta)
	
	
	
	if nodo_controlado.velocity.y < 0.0:
		nodo_controlado.play_animation("salto")
	else:
		nodo_controlado.play_animation("caida")
		
	nodo_controlado.move_and_slide()
	
	if nodo_controlado.is_on_floor():
		if direccion == 0.0:
			maquina_estados.cambiar_a("Idle")
		else:
			maquina_estados.cambiar_a("Caminar")
	
func gravity(delta) -> void:
	nodo_controlado.velocity.y += nodo_controlado.GRAVITY * delta
	
func on_input(_event)->void:
	var ataque := nodo_controlado.accion("ataque")
	var agacharse := nodo_controlado.accion("agacharse")
	
	if Input.is_action_just_pressed(ataque):
		maquina_estados.cambiar_a("Puño")
