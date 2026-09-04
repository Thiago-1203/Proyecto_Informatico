extends Estado_base


func start() -> void:
	nodo_controlado.velocity.x = 0.0
	nodo_controlado.play_animation("puño")
	
	if not nodo_controlado.animacion.animation_finished.is_connected(_cuando_termina_animacion):
		nodo_controlado.animacion.animation_finished.connect(_cuando_termina_animacion)

func on_physics_process(delta: float) -> void:
	if not nodo_controlado.is_on_floor():
		gravity(delta)
	
	
	nodo_controlado.move_and_slide()

func gravity(delta) -> void:
	nodo_controlado.velocity.y += nodo_controlado.GRAVITY * delta

func _cuando_termina_animacion(nombre:StringName)-> void:
	if nombre != &"puño":
		return
		
	var izquierda := nodo_controlado.accion("izquierda")
	var derecha := nodo_controlado.accion("derecha")
	var agacharse := nodo_controlado.accion("agacharse")
	var direccion := Input.get_axis(izquierda,derecha)
	
	if Input.is_action_pressed(agacharse) and nodo_controlado.is_on_floor():
		maquina_estados.cambiar_a("Agacharse")
	elif direccion == 0.0:
		maquina_estados.cambiar_a("Idle")
	else:
		maquina_estados.cambiar_a("Caminar")



func end()-> void:
	if nodo_controlado.animacion.animation_finished.is_connected(_cuando_termina_animacion):
		nodo_controlado.animacion.animation_finished.disconnect(_cuando_termina_animacion)
	
