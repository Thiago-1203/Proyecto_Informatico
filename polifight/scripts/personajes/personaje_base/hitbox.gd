class_name Hitbox
extends Area2D

#hitbox es donde el personaje le hace daño a otros

var atacante: Personaje
var danio: int
var multiplicador_retroceso: float = 1.0
var ataque_en_curso: bool = false
var objetivos_golpeados: Array[Personaje] = []


func configurar(nuevo_atacante: Personaje, nuevo_danio: int)-> void:
	atacante = nuevo_atacante
	danio = nuevo_danio


func iniciar_ataque(nuevo_multiplicador: float = 1.0) -> void:
	multiplicador_retroceso = nuevo_multiplicador
	objetivos_golpeados.clear()
	ataque_en_curso = true


func registrar_impacto(objetivo: Personaje) -> bool:
	if not ataque_en_curso or objetivo == atacante or objetivos_golpeados.has(objetivo):
		return false
	objetivos_golpeados.append(objetivo)
	return true


func finalizar_ataque() -> void:
	ataque_en_curso = false
	multiplicador_retroceso = 1.0
