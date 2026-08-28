extends Estado_base



func on_physics_process(delta: float) -> void:
	nodo_controlado.play_animation("idle")
	nodo_controlado.velocity.x = 0
	
	gravity(delta)
	nodo_controlado.move_and_slide()

func gravity(delta) -> void:
	nodo_controlado.velocity.y += nodo_controlado.GRAVITY * delta

func on_input(_event):
	var izquierda := nodo_controlado.accion("izquierda")
	var derecha := nodo_controlado.accion("derecha")
	var salto := nodo_controlado.accion("salto")
	var ataque := nodo_controlado.accion("ataque")
	
	

	if Input.is_action_pressed(derecha) or Input.is_action_pressed(izquierda):
		maquina_estados.cambiar_a("Caminar")
	elif Input.is_action_pressed(salto) and nodo_controlado.is_on_floor():
		maquina_estados.cambiar_a("Saltar")
	elif Input.is_action_just_pressed(ataque):
		maquina_estados.cambiar_a("Puño")
