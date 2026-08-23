class_name Hitbox
extends Area2D

#hitbox es donde el personaje le hace daño a otros

var atacante: Personaje
var danio: int


func configurar(nuevo_atacante: Personaje, nuevo_danio: int)-> void:
	atacante = nuevo_atacante
	danio = nuevo_danio
