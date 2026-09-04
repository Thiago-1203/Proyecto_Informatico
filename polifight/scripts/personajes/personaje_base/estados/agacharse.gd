extends Estado_base


func start() -> void:
	nodo_controlado.velocity.x = 0.0
	nodo_controlado.play_animation("agacharse")
	
	

func on_physics_process(delta : float)-> void:
	if not nodo_controlado.is_on_floor():
		gravity(delta)
	
	
	nodo_controlado.move_and_slide()


func gravity(delta) -> void:
	nodo_controlado.velocity.y += nodo_controlado.GRAVITY * delta
	
func on_input(_event)-> void:
	var izquierda := nodo_controlado.accion("izquierda")
	var derecha := nodo_controlado.accion("derecha")
	var salto := nodo_controlado.accion("salto")
	var ataque := nodo_controlado.accion("ataque")
	var agacharse := nodo_controlado.accion("agacharse")
	
	if not Input.is_action_pressed(derecha) and not Input.is_action_pressed(izquierda) and not Input.is_action_pressed(agacharse) and nodo_controlado.is_on_floor():
		maquina_estados.cambiar_a("Idle")
	elif Input.is_action_pressed(salto) and nodo_controlado.is_on_floor():
		maquina_estados.cambiar_a("Saltar")
	elif Input.is_action_just_pressed(ataque):
		maquina_estados.cambiar_a("Puño")
