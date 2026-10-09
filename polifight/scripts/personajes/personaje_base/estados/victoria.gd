extends Estado_base

var celebracion_iniciada: bool = false


func start() -> void:
	celebracion_iniciada = false
	nodo_controlado.velocity.x = 0.0
	nodo_controlado.hurtbox.set_deferred("monitoring", false)
	var forma_golpe := nodo_controlado.hitbox.get_node("CollisionShape2D") as CollisionShape2D
	forma_golpe.set_deferred("disabled", true)
	nodo_controlado.animacion.speed_scale = 1.0
	nodo_controlado.sprite.position = Vector2.ZERO
	# Si ganó en el aire, aterriza antes de levantar los brazos.
	nodo_controlado.play_animation(&"idle")
	_intentar_celebrar()


func on_physics_process(delta: float) -> void:
	nodo_controlado.velocity.x = 0.0
	if not nodo_controlado.is_on_floor():
		nodo_controlado.velocity.y += nodo_controlado.GRAVITY * delta
	nodo_controlado.move_and_slide()
	_intentar_celebrar()


func _intentar_celebrar() -> void:
	if celebracion_iniciada or not nodo_controlado.is_on_floor():
		return
	celebracion_iniciada = true
	nodo_controlado.play_animation(&"victoria")
