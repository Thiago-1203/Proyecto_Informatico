extends "res://scripts/personajes/personaje_base/estados/punio.gd"


func _init() -> void:
	nombre_animacion = &"patada"


func obtener_multiplicador_retroceso() -> float:
	return nodo_controlado.multiplicador_retroceso_patada
