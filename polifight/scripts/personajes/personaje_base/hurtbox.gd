class_name Hurtbox
extends Area2D

#Hurtbox es basicamente los lugares donde si el jugador recibe el golpe le bajan la vida

signal golpe_recibido(danio: int, atacante: Personaje, multiplicador_retroceso: float)

var personaje : Personaje

func _ready() -> void:
	area_entered.connect(_cuando_entra_un_area)
	
func _cuando_entra_un_area(area: Area2D) -> void:
	if not area is Hitbox:
		return
	
	var hitbox_recibida := area as Hitbox
	# Evita autogolpes y reentradas del mismo ataque contra el mismo objetivo.
	if not hitbox_recibida.registrar_impacto(personaje):
		return

	golpe_recibido.emit(
		hitbox_recibida.danio,
		hitbox_recibida.atacante,
		hitbox_recibida.multiplicador_retroceso
	)

func configurar(nuevo_personaje: Personaje) -> void:
	personaje = nuevo_personaje
