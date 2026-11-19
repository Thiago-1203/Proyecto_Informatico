extends "res://scripts/personajes/personaje_base/estados/agacharse.gd"

@export_range(0.1, 1.0, 0.05) var multiplicador_velocidad: float = 0.5
var escala_sprite_anterior: Vector2


func start() -> void:
	escala_sprite_anterior = nodo_controlado.sprite.scale
	nodo_controlado.velocity.x = 0.0
	nodo_controlado.play_animation(&"Caminar_Agachado")
	nodo_controlado.animacion.advance(0.0)


func on_physics_process(delta: float) -> void:
	if _actualizar_movimiento_agachado():
		return
	var direccion := nodo_controlado.eje_entrada(nodo_controlado.accion("izquierda"), nodo_controlado.accion("derecha"))
	nodo_controlado.velocity.x = direccion * nodo_controlado.SPEED * multiplicador_velocidad
	if not nodo_controlado.is_on_floor():
		gravity(delta)
	nodo_controlado.move_and_slide()


func end() -> void:
	nodo_controlado.sprite.scale = escala_sprite_anterior
