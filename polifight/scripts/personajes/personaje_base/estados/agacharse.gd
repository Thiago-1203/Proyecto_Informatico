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
	var bloqueo := nodo_controlado.accion("bloqueo")
	var patada := nodo_controlado.accion("patada")
	
	if nodo_controlado.entrada_presionada(bloqueo) and nodo_controlado.is_on_floor() and nodo_controlado.puede_bloquear() and maquina_estados.tiene_estado(&"Bloqueando"):
		maquina_estados.cambiar_a("Bloqueando")
	elif _event.is_action_pressed(patada) and nodo_controlado.is_on_floor() and maquina_estados.tiene_estado(&"Patada"):
		maquina_estados.cambiar_a("Patada")
	elif not nodo_controlado.entrada_presionada(derecha) and not nodo_controlado.entrada_presionada(izquierda) and not nodo_controlado.entrada_presionada(agacharse) and nodo_controlado.is_on_floor():
		maquina_estados.cambiar_a("Idle")
	elif nodo_controlado.entrada_presionada(salto) and nodo_controlado.is_on_floor():
		maquina_estados.cambiar_a("Saltar")
	elif nodo_controlado.entrada_recien_presionada(ataque):
		maquina_estados.cambiar_a("Puño")
