extends Estado_base

const CUADROS = preload("res://assets/characters/Barbieri/Ulti/barbieri_frames.tres")
const PROYECTIL = preload("res://scripts/personajes/proyectil_codigo.gd")
const DISPAROS := [0.65, 0.95, 1.25, 1.55]
var tiempo: float
var siguiente: int
var texturas: Array[AtlasTexture] = []
var posicion_anterior: Vector2
var escala_anterior: Vector2


func start() -> void:
	tiempo = 0.0
	siguiente = 0
	posicion_anterior = nodo_controlado.sprite.position
	escala_anterior = nodo_controlado.sprite.scale
	nodo_controlado.carga_ulti = 0.0
	nodo_controlado.ulti_cambiada.emit(0.0)
	nodo_controlado.velocity.x = 0.0
	# Restablecer también la hurtbox si se activó estando agachado.
	nodo_controlado.animacion.play(&"RESET")
	nodo_controlado.animacion.advance(0.0)
	nodo_controlado.animacion.stop()
	nodo_controlado.hitbox.finalizar_ataque()
	nodo_controlado.hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	if texturas.is_empty():
		for i in range(6):
			texturas.append(CUADROS.get_frame_texture(&"ulti", i))
	# La hoja generada ocupa más alto que el idle: alinear tamaño y pies.
	nodo_controlado.sprite.scale = Vector2(0.82, 0.82)
	nodo_controlado.sprite.position = Vector2(0.0, 8.0)
	_mostrar_pose(0)


func _mostrar_pose(indice: int) -> void:
	nodo_controlado.sprite.texture = texturas[indice]


func on_physics_process(delta: float) -> void:
	tiempo += delta
	nodo_controlado.velocity.x = 0.0
	if not nodo_controlado.is_on_floor():
		nodo_controlado.velocity.y += nodo_controlado.GRAVITY * delta
	nodo_controlado.move_and_slide()
	if tiempo < 0.18:
		_mostrar_pose(0)
	elif tiempo < 0.38:
		_mostrar_pose(1)
	elif tiempo < 0.58:
		_mostrar_pose(2)
	elif tiempo < 1.85:
		_mostrar_pose(3 + (int((tiempo - 0.58) * 12.0) % 2))
	elif tiempo < 2.1:
		_mostrar_pose(5)
	else:
		maquina_estados.cambiar_a("Idle")
		return
	while siguiente < DISPAROS.size() and tiempo >= DISPAROS[siguiente]:
		var proyectil := PROYECTIL.new()
		proyectil.configurar(nodo_controlado, 8)
		proyectil.direccion = nodo_controlado.direccion_mirada
		var escena := nodo_controlado.get_tree().current_scene
		proyectil.position = escena.to_local(nodo_controlado.to_global(Vector2(155 * proyectil.direccion, -45)))
		proyectil.scale = nodo_controlado.global_scale / escena.global_scale
		escena.add_child(proyectil)
		siguiente += 1


func end() -> void:
	# Un golpe, KO o victoria cancela los disparos pendientes.
	nodo_controlado.sprite.position = posicion_anterior
	nodo_controlado.sprite.scale = escala_anterior
	nodo_controlado.sprite.texture = preload("res://assets/characters/Barbieri/idle/idle1.png")
	nodo_controlado.iniciar_cooldown_ataque()
