class_name HUDCombate
extends Control

@onready var barra_jugador1: ProgressBar = %BarraJugador1
@onready var barra_jugador2: ProgressBar = %BarraJugador2
@onready var stamina_jugador1: ProgressBar = $Barras/PanelJugador1/StaminaBar1
@onready var stamina_jugador2: ProgressBar = $Barras/PanelJugador2/StaminaBar2
@onready var anuncio_ganador: Control = %AnuncioGanador
@onready var texto_ganador: Control = anuncio_ganador.texto_ganador

signal reiniciar_solicitado
signal volver_al_menu_solicitado

var rival_es_ia: bool = false

func _ready() -> void:
	anuncio_ganador.reiniciar_solicitado.connect(reiniciar_solicitado.emit)
	anuncio_ganador.volver_al_menu_solicitado.connect(volver_al_menu_solicitado.emit)


func configurar(jugador1: Personaje, jugador2: Personaje) -> void:
	for numero in [1, 2]:
		var jugador: Personaje = jugador1 if numero == 1 else jugador2
		var barra := get_node("Barras/PanelJugador%d/UltiBar%d" % [numero, numero]) as ProgressBar
		barra.value = 0.0
		if jugador.has_signal("ulti_cambiada"):
			barra.value = jugador.get("carga_ulti")
			jugador.connect("ulti_cambiada", func(carga: float): barra.value = carga)
	rival_es_ia = jugador2.controlado_por_ia
	anuncio_ganador.hide()
	$Barras.show()
	barra_jugador1.max_value = jugador1.vida_maxima
	barra_jugador2.max_value = jugador2.vida_maxima
	stamina_jugador1.max_value = jugador1.stamina_maxima
	stamina_jugador2.max_value = jugador2.stamina_maxima
	
	barra_jugador1.value = jugador1.vida_actual
	barra_jugador2.value = jugador2.vida_actual
	stamina_jugador1.value = jugador1.stamina_actual
	stamina_jugador2.value = jugador2.stamina_actual
	
	if not jugador1.vida_cambiada.is_connected(_actualizar_jugador_1):
		jugador1.vida_cambiada.connect(_actualizar_jugador_1)
		
	if not jugador2.vida_cambiada.is_connected(_actualizar_jugador_2):
		jugador2.vida_cambiada.connect(_actualizar_jugador_2)

	if not jugador1.stamina_cambiada.is_connected(_actualizar_stamina_jugador_1):
		jugador1.stamina_cambiada.connect(_actualizar_stamina_jugador_1)

	if not jugador2.stamina_cambiada.is_connected(_actualizar_stamina_jugador_2):
		jugador2.stamina_cambiada.connect(_actualizar_stamina_jugador_2)
		
func _actualizar_jugador_1(vida_actual: int, _vida_maxima: int)-> void:
	barra_jugador1.value = vida_actual
	
func _actualizar_jugador_2(vida_actual: int, _vida_maxima: int) -> void:
	barra_jugador2.value = vida_actual


func _actualizar_stamina_jugador_1(stamina_actual: float, _stamina_maxima: float) -> void:
	stamina_jugador1.value = stamina_actual


func _actualizar_stamina_jugador_2(stamina_actual: float, _stamina_maxima: float) -> void:
	stamina_jugador2.value = stamina_actual


func mostrar_ganador(numero_jugador: int) -> void:
	$Barras.hide()
	var seleccion := get_node("/root/SeleccionPartida") as EstadoSeleccionPartida
	var ficha: FichaSeleccion = seleccion.jugadores[numero_jugador - 1] if seleccion.jugadores.size() >= numero_jugador else null
	anuncio_ganador.mostrar(numero_jugador, rival_es_ia and numero_jugador == 2, ficha)
