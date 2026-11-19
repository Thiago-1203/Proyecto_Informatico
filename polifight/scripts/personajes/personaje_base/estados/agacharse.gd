extends Estado_base


func start() -> void:
	nodo_controlado.velocity.x = 0.0
	nodo_controlado.play_animation("agacharse")
	nodo_controlado.animacion.advance(0.0)
	
	

func on_physics_process(delta : float)-> void:
	if _actualizar_movimiento_agachado():
		return
	if not nodo_controlado.is_on_floor():
		gravity(delta)
	
	
	nodo_controlado.move_and_slide()


func gravity(delta) -> void:
	nodo_controlado.velocity.y += nodo_controlado.GRAVITY * delta
	
func on_input(_event)-> void:
	var salto := nodo_controlado.accion("salto")
	var ataque := nodo_controlado.accion("ataque")
	var bloqueo := nodo_controlado.accion("bloqueo")
	var patada := nodo_controlado.accion("patada")
	
	if nodo_controlado.entrada_presionada(bloqueo) and nodo_controlado.is_on_floor() and nodo_controlado.puede_bloquear() and maquina_estados.tiene_estado(&"Bloqueando"):
		maquina_estados.cambiar_a("Bloqueando")
	elif _event.is_action_pressed(patada) and nodo_controlado.is_on_floor() and maquina_estados.tiene_estado(&"Patada"):
		maquina_estados.cambiar_a("Patada")
	elif nodo_controlado.entrada_presionada(salto) and nodo_controlado.is_on_floor():
		maquina_estados.cambiar_a("Saltar")
	elif nodo_controlado.entrada_recien_presionada(ataque):
		maquina_estados.cambiar_a("Puño")
	else:
		_actualizar_movimiento_agachado()


func _actualizar_movimiento_agachado() -> bool:
	if not nodo_controlado.is_on_floor():
		return false
	var direccion := nodo_controlado.eje_entrada(nodo_controlado.accion("izquierda"), nodo_controlado.accion("derecha"))
	var destino: String
	if nodo_controlado.entrada_presionada(nodo_controlado.accion("agacharse")):
		destino = "CaminarAgachado" if direccion != 0.0 and maquina_estados.tiene_estado(&"CaminarAgachado") else "Agacharse"
	else:
		destino = "Caminar" if direccion != 0.0 else "Idle"
	if maquina_estados.es_estado_actual(StringName(destino)):
		return false
	maquina_estados.cambiar_a(destino)
	return true
