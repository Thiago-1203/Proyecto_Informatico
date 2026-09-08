class_name HUDCombate
extends Control

@onready var barra_jugador1: ProgressBar = %BarraJugador1
@onready var barra_jugador2: ProgressBar = %BarraJugador2

func configurar(jugador1: Personaje, jugador2: Personaje) -> void:
	barra_jugador1.max_value = jugador1.vida_maxima
	barra_jugador2.max_value = jugador2.vida_maxima
	
	barra_jugador1.value = jugador1.vida_actual
	barra_jugador2.value = jugador2.vida_actual
	
	if not jugador1.vida_cambiada.is_connected(_actualizar_jugador_1):
		jugador1.vida_cambiada.connect(_actualizar_jugador_1)
		
	if not jugador2.vida_cambiada.is_connected(_actualizar_jugador_2):
		jugador2.vida_cambiada.connect(_actualizar_jugador_2)
		
func _actualizar_jugador_1(vida_actual: int, _vida_maxima: int)-> void:
	barra_jugador1.value = vida_actual
	
func _actualizar_jugador_2(vida_actual: int, _vida_maxima: int) -> void:
	barra_jugador2.value = vida_actual
	
