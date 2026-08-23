class_name Hurtbox
extends Area2D

#Hurtbox es basicamente los lugares donde si el jugador recibe el golpe le bajan la vida

signal golpe_recibido(danio: int, atacante: Personaje)

var personaje : Personaje

func _ready() -> void:
	area_entered.connect(_cuando_entra_un_area)
	
func _cuando_entra_un_area(area: Area2D) -> void:
	if not area is Hitbox:
		return
	
	var hitbox_recibida := area as Hitbox
	# Evita que un personaje se golpee con su propia Hitbox.
	if hitbox_recibida.atacante == personaje:
		return

	golpe_recibido.emit(hitbox_recibida.danio,hitbox_recibida.atacante)

func configurar(nuevo_personaje: Personaje) -> void:
	personaje = nuevo_personaje
