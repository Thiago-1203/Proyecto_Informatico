extends Node2D

## Ejecutar con F6 para ver la ulti real contra un rival inmóvil.
var nivel: Node
var espera: float = 0.7

func _ready() -> void:
	nivel = preload("res://escenas/juego/nivelI.tscn").instantiate()
	add_child(nivel)

func _process(delta: float) -> void:
	espera -= delta
	if espera > 0.0:
		return
	espera = 5.0
	nivel.jugador1.position.x = 700.0
	nivel.jugador2.position.x = 1400.0
	nivel.jugador2.vida_actual = 100
	nivel.jugador1.carga_ulti = 100.0
	if nivel.jugador1.puede_usar_ulti():
		nivel.jugador1.maquina_estados.cambiar_a("Ulti")
