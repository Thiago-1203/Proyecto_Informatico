extends Node2D

#ATTENTION para cuando se comience a hacer la seleccion de escenarios
# hacer una escena de combate base que sera la base de todos los escenarios

@onready var jugador1: Personaje = $barbieri as Personaje
@onready var jugador2: Personaje = $barbieri2 as Personaje
@onready var hud: HUDCombate = $HUDLayer/HUD as HUDCombate

func _ready() -> void:
	hud.configurar(jugador1, jugador2)
