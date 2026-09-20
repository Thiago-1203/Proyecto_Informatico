extends Estado_base

var primer_impacto_completado: bool = false
var rebote_completado: bool = false
var animacion_ko_completada: bool = false
var secuencia_lista: bool = false
var demora_restante: float = 0.0


func start() -> void:
	primer_impacto_completado = false
	rebote_completado = false
	animacion_ko_completada = false
	secuencia_lista = false
	demora_restante = nodo_controlado.demora_victoria_ko
	nodo_controlado.hurtbox.set_deferred("monitoring", false)

	var forma_golpe := nodo_controlado.hitbox.get_node("CollisionShape2D") as CollisionShape2D
	forma_golpe.set_deferred("disabled", true)
	nodo_controlado.animacion.speed_scale = nodo_controlado.velocidad_animacion_ko
	nodo_controlado.play_animation(&"KO")

	if not nodo_controlado.animacion.animation_finished.is_connected(_cuando_termina_animacion):
		nodo_controlado.animacion.animation_finished.connect(_cuando_termina_animacion)


func on_physics_process(delta: float) -> void:
	if secuencia_lista:
		demora_restante -= delta
		if demora_restante <= 0.0:
			secuencia_lista = false
			nodo_controlado.notificar_secuencia_ko_finalizada()
		return

	var estaba_en_el_piso := nodo_controlado.is_on_floor()
	nodo_controlado.velocity.x = move_toward(
		nodo_controlado.velocity.x,
		0.0,
		nodo_controlado.frenado_retroceso * 0.35 * delta
	)

	if not nodo_controlado.is_on_floor() or nodo_controlado.velocity.y < 0.0:
		nodo_controlado.velocity.y += nodo_controlado.GRAVITY * delta

	nodo_controlado.move_and_slide()

	var acaba_de_aterrizar := not estaba_en_el_piso and nodo_controlado.is_on_floor()
	if acaba_de_aterrizar:
		_procesar_impacto_con_el_piso()


func _procesar_impacto_con_el_piso() -> void:
	if not primer_impacto_completado:
		primer_impacto_completado = true
		nodo_controlado.velocity.x *= nodo_controlado.conservacion_horizontal_rebote_ko
		nodo_controlado.velocity.y = -nodo_controlado.impulso_rebote_ko
		return

	if rebote_completado:
		return

	rebote_completado = true
	nodo_controlado.velocity = Vector2.ZERO
	_intentar_finalizar_secuencia()


func _cuando_termina_animacion(nombre: StringName) -> void:
	if nombre != &"KO":
		return

	animacion_ko_completada = true
	_intentar_finalizar_secuencia()


func _intentar_finalizar_secuencia() -> void:
	if rebote_completado and animacion_ko_completada:
		secuencia_lista = true


func end() -> void:
	nodo_controlado.animacion.speed_scale = 1.0
	if nodo_controlado.animacion.animation_finished.is_connected(_cuando_termina_animacion):
		nodo_controlado.animacion.animation_finished.disconnect(_cuando_termina_animacion)
