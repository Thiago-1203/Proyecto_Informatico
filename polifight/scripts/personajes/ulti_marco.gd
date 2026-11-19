extends Estado_base

const LETRA = preload("res://scripts/personajes/letra_marco.gd")
const OLEADAS := [0.65, 1.2, 1.75, 2.3]
const CARRILES := [-220.0, 0.0, 220.0]
const DANIO_LETRA := 6
var tiempo: float = 0.0
var siguiente: int = 0


func start() -> void:
	tiempo = 0.0
	siguiente = 0
	nodo_controlado.carga_ulti = 0.0
	nodo_controlado.ulti_cambiada.emit(0.0)
	nodo_controlado.velocity.x = 0.0
	nodo_controlado.animacion.play(&"RESET")
	nodo_controlado.animacion.advance(0.0)
	nodo_controlado.hitbox.finalizar_ataque()
	nodo_controlado.hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	nodo_controlado.play_animation(&"ulti")
	nodo_controlado.animacion.advance(0.0)


func on_physics_process(delta: float) -> void:
	tiempo += delta
	nodo_controlado.velocity.x = 0.0
	if not nodo_controlado.is_on_floor():
		nodo_controlado.velocity.y += nodo_controlado.GRAVITY * delta
	nodo_controlado.move_and_slide()
	while siguiente < OLEADAS.size() and tiempo >= OLEADAS[siguiente]:
		_lanzar_oleada(siguiente)
		siguiente += 1
	if tiempo >= nodo_controlado.animacion.get_animation(&"ulti").length:
		maquina_estados.cambiar_a("Idle")


func _lanzar_oleada(indice: int) -> void:
	var rival: Personaje = nodo_controlado.oponente
	if not is_instance_valid(rival) or rival.vida_actual <= 0:
		return
	var escena := nodo_controlado.get_parent() as Node2D
	var escala := nodo_controlado.global_scale.abs()
	# La posición se fija al invocar cada oleada: las letras no persiguen al rival.
	var centro := rival.global_position.x
	var arriba := nodo_controlado.get_viewport().get_canvas_transform().affine_inverse() * Vector2(0, -96)
	for carril in CARRILES.size():
		var letra := LETRA.new()
		letra.configurar(nodo_controlado, DANIO_LETRA)
		letra.variante = indice * CARRILES.size() + carril
		letra.scale = escala / escena.global_scale.abs()
		# Alternar columnas deja sitio para leer los nombres verticales largos.
		# Los carriles laterales se desplazan hacia afuera para conservar el alcance.
		var desfase := 88.0 if indice % 2 == 1 else 0.0
		var horizontal: float = CARRILES[carril] + (-desfase if carril == 0 else desfase)
		if carril == 1:
			# Times New Roman ocupa más largo: usar tres columnas a esta velocidad.
			horizontal = (indice % 3 - 1) * 88.0
		letra.position = escena.to_local(Vector2(centro + horizontal * escala.x, arriba.y - carril * 100.0 * escala.y))
		escena.add_child(letra)


func end() -> void:
	# Un golpe cancela las oleadas pendientes. Las ya invocadas siguen cayendo.
	nodo_controlado.iniciar_cooldown_ataque()
