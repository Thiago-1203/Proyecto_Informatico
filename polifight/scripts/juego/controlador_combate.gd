extends Node2D

@onready var seleccion: EstadoSeleccionPartida = get_node("/root/SeleccionPartida")

# Cada escenario aporta sus puntos de aparición; el catálogo aporta los luchadores.
@export var punto_jugador1: NodePath = ^"AparicionJ1"
@export var punto_jugador2: NodePath = ^"AparicionJ2"

var jugador1: Personaje
var jugador2: Personaje
@onready var hud: HUDCombate = $HUDLayer/HUD as HUDCombate

# Ritmo global del combate. 1.0 mantiene la velocidad nativa; el valor actual
# acelera de forma pareja las animaciones, la física y las reglas temporales.
@export_range(0.5, 1.25, 0.05) var escala_tiempo_combate: float = 1.5

var escala_tiempo_anterior: float = 1.0
var combate_finalizado: bool = false
var personaje_derrotado_actual: Personaje
var personaje_ganador_actual: Personaje


func _ready() -> void:
	jugador1 = _crear_jugador(1, punto_jugador1)
	jugador2 = _crear_jugador(2, punto_jugador2)
	if jugador1 == null or jugador2 == null:
		return
	escala_tiempo_anterior = Engine.time_scale
	Engine.time_scale = escala_tiempo_combate
	jugador1.configurar_oponente(jugador2)
	jugador2.configurar_oponente(jugador1)
	hud.configurar(jugador1, jugador2)

	jugador1.vida_agotada.connect(_cuando_termina_el_combate)
	jugador2.vida_agotada.connect(_cuando_termina_el_combate)
	jugador1.secuencia_ko_finalizada.connect(_cuando_finaliza_secuencia_ko)
	jugador2.secuencia_ko_finalizada.connect(_cuando_finaliza_secuencia_ko)


func _crear_jugador(numero: int, punto: NodePath) -> Personaje:
	var jugador := seleccion.crear_jugador(numero)
	if jugador == null:
		return null
	jugador.name = "Jugador%d" % numero
	jugador.position = (get_node(punto) as Node2D).position
	add_child(jugador)
	return jugador


func _exit_tree() -> void:
	Engine.time_scale = escala_tiempo_anterior


func _cuando_termina_el_combate(personaje_derrotado: Personaje) -> void:
	if combate_finalizado:
		return

	combate_finalizado = true
	personaje_derrotado_actual = personaje_derrotado
	personaje_ganador_actual = jugador2 if personaje_derrotado == jugador1 else jugador1


func _cuando_finaliza_secuencia_ko(personaje_derrotado: Personaje) -> void:
	if not combate_finalizado or personaje_derrotado != personaje_derrotado_actual:
		return
	if not is_instance_valid(personaje_ganador_actual):
		return

	personaje_ganador_actual.celebrar_victoria()
	hud.mostrar_ganador(personaje_ganador_actual.numero_jugador)
