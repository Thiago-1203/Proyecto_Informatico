class_name EstadoSeleccionPartida
extends Node
## Persiste al cambiar de escena y al reiniciar el combate desde la pausa.

const CATALOGO: CatalogoSeleccion = preload("res://datos/seleccion/catalogo.tres")

var personajes: Array[FichaSeleccion] = []
var escenarios: Array[FichaSeleccion] = []
var jugadores: Array[FichaSeleccion] = []
var escenario: FichaSeleccion


func _ready() -> void:
	personajes = CATALOGO.disponibles(CATALOGO.personajes)
	escenarios = CATALOGO.disponibles(CATALOGO.escenarios)
	reiniciar()


func reiniciar() -> void:
	jugadores.clear()
	if not personajes.is_empty():
		jugadores.assign([personajes[0], personajes[0]])
	escenario = escenarios[0] if not escenarios.is_empty() else null


func crear_jugador(numero: int) -> Personaje:
	if jugadores.size() != 2:
		push_error("No hay personajes disponibles en el catálogo.")
		return null
	var escena := load(jugadores[numero - 1].escena) as PackedScene
	var instancia := escena.instantiate()
	if not instancia is Personaje:
		push_error("La escena seleccionada debe heredar de Personaje.")
		instancia.free()
		return null
	instancia.numero_jugador = numero
	instancia.direccion_inicial = 1 if numero == 1 else -1
	return instancia as Personaje
