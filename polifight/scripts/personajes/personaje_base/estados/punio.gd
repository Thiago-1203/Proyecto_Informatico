extends Estado_base

var nombre_animacion: StringName = &"puño"
var posicion_hitbox_anterior: Vector2
var tamano_hitbox_anterior: Vector2

func start() -> void:
	nodo_controlado.velocity.x = 0.0
	var forma_golpe := nodo_controlado.hitbox.get_node("CollisionShape2D") as CollisionShape2D
	posicion_hitbox_anterior = forma_golpe.position
	tamano_hitbox_anterior = (forma_golpe.shape as RectangleShape2D).size
	nodo_controlado.hitbox.iniciar_ataque(obtener_multiplicador_retroceso())
	nodo_controlado.play_animation(nombre_animacion)
	
	if not nodo_controlado.animacion.animation_finished.is_connected(_cuando_termina_animacion):
		nodo_controlado.animacion.animation_finished.connect(_cuando_termina_animacion)

func on_physics_process(delta: float) -> void:
	if not nodo_controlado.is_on_floor():
		gravity(delta)
	
	
	nodo_controlado.move_and_slide()

func gravity(delta) -> void:
	nodo_controlado.velocity.y += (
		nodo_controlado.GRAVITY
		* nodo_controlado.JUMP_GRAVITY_MULTIPLIER
		* delta
	)

func obtener_multiplicador_retroceso() -> float:
	return 1.0


func _cuando_termina_animacion(nombre:StringName)-> void:
	if nombre != nombre_animacion:
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
	nodo_controlado.hitbox.finalizar_ataque()
	if nodo_controlado.animacion.animation_finished.is_connected(_cuando_termina_animacion):
		nodo_controlado.animacion.animation_finished.disconnect(_cuando_termina_animacion)
	var forma_golpe := nodo_controlado.hitbox.get_node("CollisionShape2D") as CollisionShape2D
	forma_golpe.set_deferred("disabled", true)
	forma_golpe.set_deferred("position", posicion_hitbox_anterior)
	forma_golpe.shape.set_deferred("size", tamano_hitbox_anterior)
	
