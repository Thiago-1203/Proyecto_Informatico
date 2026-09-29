class_name HUDCombate
extends Control

@onready var barra_jugador1: ProgressBar = %BarraJugador1
@onready var barra_jugador2: ProgressBar = %BarraJugador2
@onready var stamina_jugador1: ProgressBar = $Barras/PanelJugador1/StaminaBar1
@onready var stamina_jugador2: ProgressBar = $Barras/PanelJugador2/StaminaBar2
@onready var anuncio_ganador: Control = %AnuncioGanador
@onready var fondo_victoria: ColorRect = %FondoVictoria
@onready var impacto_victoria: Control = %ImpactoVictoria
@onready var titulo_ko = %TituloKO
@onready var texto_ganador = %TextoGanador
@onready var borde_victoria: ReferenceRect = $AnuncioGanador/Centro/ImpactoVictoria/BordeExterior
@onready var acento_izquierdo: ColorRect = $AnuncioGanador/Centro/ImpactoVictoria/AcentoIzquierdo
@onready var acento_derecho: ColorRect = $AnuncioGanador/Centro/ImpactoVictoria/AcentoDerecho

var tween_anuncio_ganador: Tween
var tween_colores_victoria: Tween


func configurar(jugador1: Personaje, jugador2: Personaje) -> void:
	anuncio_ganador.hide()
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
	texto_ganador.texto = "JUGADOR %d GANA!" % numero_jugador
	anuncio_ganador.show()
	call_deferred("_animar_anuncio_ganador")


func _animar_anuncio_ganador() -> void:
	if not anuncio_ganador.visible:
		return

	if tween_anuncio_ganador != null and tween_anuncio_ganador.is_valid():
		tween_anuncio_ganador.kill()
	if tween_colores_victoria != null and tween_colores_victoria.is_valid():
		tween_colores_victoria.kill()

	var posicion_final := impacto_victoria.position
	anuncio_ganador.modulate.a = 0.0
	impacto_victoria.position = posicion_final + Vector2(0.0, 14.0)
	impacto_victoria.scale = Vector2.ONE
	titulo_ko.self_modulate = Color(1.0, 0.3, 0.16, 1.0)
	texto_ganador.self_modulate = Color(1.0, 0.78, 0.16, 1.0)
	fondo_victoria.color = Color(0.025, 0.065, 0.12, 0.94)

	tween_anuncio_ganador = create_tween()
	tween_anuncio_ganador.set_parallel(true)
	tween_anuncio_ganador.tween_property(
		anuncio_ganador,
		"modulate:a",
		1.0,
		0.16
	)
	tween_anuncio_ganador.tween_property(
		impacto_victoria,
		"position",
		posicion_final,
		0.2
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_anuncio_ganador.chain().tween_callback(_iniciar_ciclo_color)


func _iniciar_ciclo_color() -> void:
	if not anuncio_ganador.visible:
		return

	# El cambio de paleta es la animación principal: legible, arcade y sin tapar la pelea.
	tween_colores_victoria = create_tween().set_loops()
	tween_colores_victoria.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_agregar_fase_color(
		Color(1.0, 0.28, 0.14, 1.0),
		Color(1.0, 0.72, 0.1, 1.0),
		Color(0.58, 0.055, 0.05, 1.0),
		Color(0.035, 0.055, 0.115, 0.96)
	)
	_agregar_fase_color(
		Color(1.0, 0.82, 0.16, 1.0),
		Color(1.0, 0.96, 0.68, 1.0),
		Color(1.0, 0.55, 0.08, 1.0),
		Color(0.07, 0.045, 0.11, 0.96)
	)
	_agregar_fase_color(
		Color(0.26, 0.82, 1.0, 1.0),
		Color(0.75, 0.94, 1.0, 1.0),
		Color(0.18, 0.58, 0.86, 1.0),
		Color(0.025, 0.075, 0.13, 0.96)
	)


func _agregar_fase_color(
	color_ko: Color,
	color_ganador: Color,
	color_borde: Color,
	color_fondo: Color
) -> void:
	tween_colores_victoria.tween_property(titulo_ko, "self_modulate", color_ko, 0.36)
	tween_colores_victoria.parallel().tween_property(
		texto_ganador,
		"self_modulate",
		color_ganador,
		0.36
	)
	tween_colores_victoria.parallel().tween_property(
		borde_victoria,
		"border_color",
		color_borde,
		0.36
	)
	tween_colores_victoria.parallel().tween_property(
		acento_izquierdo,
		"color",
		color_borde,
		0.36
	)
	tween_colores_victoria.parallel().tween_property(
		acento_derecho,
		"color",
		color_ko,
		0.36
	)
	tween_colores_victoria.parallel().tween_property(
		fondo_victoria,
		"color",
		color_fondo,
		0.36
	)
	
