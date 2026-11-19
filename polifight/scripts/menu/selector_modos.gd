extends Control

signal volver_solicitado

const SELECTOR_COMBATE = preload("res://escenas/menu/selector_combate.tscn")

const TEXTO = preload("res://scripts/ui/texto_arcade.gd")
const BOTON = preload("res://scripts/menu/boton_arcade.gd")
const FONDO_UI = preload("res://scripts/menu/menu_fondo.gd")
const CABECERA = preload("res://scripts/menu/menu_cabecera.gd")
const TARJETA = preload("res://scripts/menu/tarjeta_modo.gd")
const RESOLUCION := Vector2(1920, 1080)
const MODOS := [
	{
		"titulo": "HISTORIA", "subtitulo": "PROXIMAMENTE",
		"descripcion": "ESTE MODO TODAVIA NO ESTA DISPONIBLE.",
		"arte": preload("res://assets/ui/selector_modos/historia.png"),
		"escena": "",
	},
	{
		"titulo": "1 VS 1", "subtitulo": "PERSONA O IA",
		"descripcion": "ELIGE TU RIVAL Y DOMINA EL DUELO.",
		"arte": preload("res://assets/ui/selector_modos/duelo_local.png"),
		"escena": "seleccion",
	},
	{
		"titulo": "2 VS 2", "subtitulo": "PROXIMAMENTE",
		"descripcion": "ESTE MODO TODAVIA NO ESTA DISPONIBLE.",
		"arte": preload("res://assets/ui/selector_modos/equipos.png"),
		"escena": "",
	},
	{
		"titulo": "TUTORIAL", "subtitulo": "APRENDE JUGANDO",
		"descripcion": "UN PASO A LA VEZ. A TU RITMO.",
		"arte": null,
		"escena": "res://escenas/juego/tutorial.tscn",
	},
]

@onready var lienzo: Control = $Lienzo
@onready var carrusel: Control = $Lienzo/Carrusel
@onready var indicadores: Control = $Lienzo/Indicadores
@onready var aviso: Control = $Lienzo/Aviso

var _ayuda: Control
var _usando_mando := false
var boton_jugar: Button
var indice_seleccionado: int = 1
var _tarjetas: Array[Control] = []
var _transicion: Tween
var _entrada: Tween
var _entrando: bool = true
var _tiempo_repeticion: float = 0.0
var _direccion_mantenida: int = 0
var _confirmacion_habilitada: bool = false
var _saliendo: bool = false
var selector_combate: Control


func _ready() -> void:
	resized.connect(_ajustar_escala)
	lienzo.clip_contents = true
	_crear_interfaz()
	indicadores.hide()
	for modo in MODOS:
		var tarjeta = TARJETA.new()
		tarjeta.name = "Tarjeta" + str(_tarjetas.size())
		tarjeta.ilustracion = modo["arte"]
		tarjeta.titulo = modo["titulo"]
		tarjeta.subtitulo = modo["subtitulo"]
		tarjeta.descripcion = modo["descripcion"]
		tarjeta.es_tutorial = modo["titulo"] == "TUTORIAL"
		tarjeta.size = Vector2(400, 600)
		tarjeta.disponible = not modo["escena"].is_empty()
		tarjeta.elegida.connect(_elegir_modo.bind(_tarjetas.size()))
		carrusel.add_child(tarjeta)
		_tarjetas.append(tarjeta)
	_ajustar_escala()
	_actualizar_tarjetas(false)
	aviso.hide()
	_reproducir_entrada()


func _reproducir_entrada() -> void:
	# El fondo permanece opaco para no revelar la portada tras cruzar la puerta.
	$Fondo.modulate = Color.BLACK
	lienzo.modulate.a = 0.0
	_entrada = create_tween().set_parallel(true)
	_entrada.tween_property($Fondo, "modulate", Color.WHITE, 0.24)
	_entrada.tween_property(lienzo, "modulate:a", 1.0, 0.24)
	for i in _tarjetas.size():
		var tarjeta := _tarjetas[i]
		var destino := tarjeta.position
		var desplazamiento := Vector2(0, 24)
		tarjeta.position += desplazamiento
		tarjeta.modulate.a = 0.0
		var demora := 0.04 + i * 0.05
		_entrada.tween_property(tarjeta, "position", destino, 0.38).set_delay(demora).set_trans(
			Tween.TRANS_CUBIC
		).set_ease(Tween.EASE_OUT)
		_entrada.tween_property(tarjeta, "modulate:a", 1.0, 0.25).set_delay(demora)
	await _entrada.finished
	_entrando = false
	_tarjetas[indice_seleccionado].grab_focus()


func _process(delta: float) -> void:
	if _saliendo or _entrando or is_instance_valid(selector_combate):
		return
	# No confirmar con la misma pulsación que abrió JUGAR.
	if not Input.is_action_pressed(&"modo_confirmar"):
		_confirmacion_habilitada = true
	var direccion := int(Input.is_action_pressed(&"modo_siguiente")) - int(Input.is_action_pressed(&"modo_anterior"))
	if direccion == 0:
		_direccion_mantenida = 0
		_tiempo_repeticion = 0.0
		return
	if direccion != _direccion_mantenida:
		_direccion_mantenida = direccion
		_tiempo_repeticion = 0.35
		_desplazar(direccion)
	else:
		_tiempo_repeticion -= delta
		if _tiempo_repeticion <= 0.0:
			_tiempo_repeticion = 0.18
			_desplazar(direccion)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_usando_mando = true
	elif event is InputEventKey or event is InputEventMouseButton:
		_usando_mando = false
	if _ayuda != null:
		_ayuda.texto = "CRUCETA  ELEGIR     A  CONTINUAR     B  VOLVER" if _usando_mando else "FLECHAS  ELEGIR     ENTER  CONTINUAR     ESC  VOLVER"
	if _saliendo or _entrando or is_instance_valid(selector_combate) or event.is_echo():
		return
	if event.is_action_pressed(&"modo_volver"):
		get_viewport().set_input_as_handled()
		_saliendo = true
		volver_solicitado.emit()
	elif event.is_action_pressed(&"modo_confirmar") and _confirmacion_habilitada:
		if event is InputEventJoypadButton:
			get_node("/root/EntradaMandos").asignar_principal(event.device)
		get_viewport().set_input_as_handled()
		_confirmar()


func _ajustar_escala() -> void:
	if not is_node_ready():
		return
	var factor := minf(size.x / RESOLUCION.x, size.y / RESOLUCION.y)
	lienzo.scale = Vector2.ONE * factor
	lienzo.position = (size - RESOLUCION * factor) * 0.5


func _desplazar(direccion: int) -> void:
	indice_seleccionado = posmod(indice_seleccionado + direccion, MODOS.size())
	aviso.hide()
	_actualizar_tarjetas(true)


func _actualizar_tarjetas(animar: bool) -> void:
	if _transicion != null and _transicion.is_valid():
		_transicion.kill()
	if animar:
		_transicion = create_tween().set_parallel(true)
		_transicion.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for i in _tarjetas.size():
		var tarjeta := _tarjetas[i]
		var central := i == indice_seleccionado
		var escala := Vector2.ONE
		var destino := Vector2(100 + i * 440, 295 if central else 315)
		var color := Color.WHITE
		tarjeta.set("seleccionado", central)
		tarjeta.z_index = 2 if central else 1
		if animar:
			_transicion.tween_property(tarjeta, "position", destino, 0.18)
		else:
			tarjeta.position = destino
		tarjeta.scale = escala
		tarjeta.modulate = color
	boton_jugar.texto = "CONTINUAR" if not MODOS[indice_seleccionado]["escena"].is_empty() else "PROXIMAMENTE"
	boton_jugar.disabled = MODOS[indice_seleccionado]["escena"].is_empty()
	boton_jugar.modulate.a = 0.45 if boton_jugar.disabled else 1.0
	boton_jugar.queue_redraw()
	indicadores.queue_redraw()
	if not _entrando:
		_tarjetas[indice_seleccionado].grab_focus()


func _dibujar_indicadores() -> void:
	for i in MODOS.size():
		var color := Color("ffb80d") if i == indice_seleccionado else Color("235285")
		var origen := Vector2(i * 48, 0)
		indicadores.draw_rect(Rect2(origen - Vector2(4, 4), Vector2(28, 28)), Color("020711"))
		indicadores.draw_rect(Rect2(origen, Vector2(20, 20)), color)


func _confirmar() -> void:
	var escena: String = MODOS[indice_seleccionado]["escena"]
	if escena.is_empty():
		aviso.show()
		return
	if _saliendo or is_instance_valid(selector_combate):
		return
	_saliendo = true
	if _transicion != null and _transicion.is_valid():
		_transicion.kill()
	var salida := create_tween().set_parallel(true)
	salida.tween_property(lienzo, "modulate:a", 0.0, 0.16)
	salida.tween_property($Oscurecimiento, "modulate:a", 0.0, 0.16)
	await salida.finished
	lienzo.hide()
	if escena != "seleccion":
		var error := get_tree().change_scene_to_file(escena)
		if error != OK:
			lienzo.show()
			lienzo.modulate.a = 1.0
			_saliendo = false
			push_error("No se pudo abrir el tutorial: " + error_string(error))
		return
	selector_combate = SELECTOR_COMBATE.instantiate()
	add_child(selector_combate)
	selector_combate.volver_solicitado.connect(_cerrar_seleccion)
	selector_combate.combate_solicitado.connect(_iniciar_combate)
	_saliendo = false


func _cerrar_seleccion() -> void:
	selector_combate.queue_free()
	lienzo.modulate.a = 1.0
	$Oscurecimiento.modulate.a = 1.0
	lienzo.show()
	_tarjetas[indice_seleccionado].grab_focus()
	_confirmacion_habilitada = false


func _iniciar_combate(escena: String) -> void:
	_saliendo = true
	var transicion := get_node("/root/TransicionCombate")
	var error: Error = await transicion.iniciar(escena)
	if error != OK:
		selector_combate.modulate.a = 1.0
		_saliendo = false
		selector_combate.mostrar_error()
		_confirmacion_habilitada = false
		push_error("No se pudo iniciar el modo: " + error_string(error))


func _exit_tree() -> void:
	if _entrada != null and _entrada.is_valid():
		_entrada.kill()
	if _transicion != null and _transicion.is_valid():
		_transicion.kill()


func _elegir_modo(indice: int) -> void:
	if _entrando or _saliendo or is_instance_valid(selector_combate):
		return
	indice_seleccionado = indice
	aviso.hide()
	_actualizar_tarjetas(true)


func _crear_interfaz() -> void:
	var fondo := FONDO_UI.new()
	lienzo.add_child(fondo)
	lienzo.move_child(fondo, 0)
	var cabecera := CABECERA.new()
	lienzo.add_child(cabecera)
	var titulo := TEXTO.new()
	titulo.texto = "ELIGE UN MODO"
	titulo.tamano_pixel = 8
	titulo.color = Color("fff2d5")
	titulo.alineacion_horizontal = 1
	titulo.position = Vector2(100, 178)
	titulo.size = Vector2(1720, 64)
	lienzo.add_child(titulo)
	var detalle := TEXTO.new()
	detalle.texto = ""
	detalle.tamano_pixel = 2
	detalle.color = Color("91a5ba")
	detalle.alineacion_horizontal = 0
	detalle.position = Vector2(80, 231)
	detalle.size = Vector2(1300, 24)
	lienzo.add_child(detalle)
	var volver := BOTON.new()
	volver.texto = "<  VOLVER"
	volver.tamano_pixel = 3
	volver.dibujar_marco = true
	volver.focus_mode = Control.FOCUS_NONE
	volver.position = Vector2(100, 946)
	volver.size = Vector2(270, 56)
	volver.pressed.connect(func():
		if not _saliendo and not _entrando:
			_saliendo = true
			volver_solicitado.emit())
	lienzo.add_child(volver)
	boton_jugar = BOTON.new()
	boton_jugar.texto = "CONTINUAR"
	boton_jugar.tamano_pixel = 3
	boton_jugar.dibujar_marco = true
	boton_jugar.focus_mode = Control.FOCUS_NONE
	boton_jugar.color_normal = Color("fff2d5")
	boton_jugar.color_borde = Color("ffb80d")
	boton_jugar.color_fondo = Color("30233a")
	boton_jugar.position = Vector2(1350, 946)
	boton_jugar.size = Vector2(470, 56)
	boton_jugar.pressed.connect(_confirmar)
	lienzo.add_child(boton_jugar)
	var ayuda := TEXTO.new()
	_ayuda = ayuda
	ayuda.texto = "FLECHAS  ELEGIR     ENTER  CONTINUAR     ESC  VOLVER"
	ayuda.tamano_pixel = 3
	ayuda.color = Color("91a5ba")
	ayuda.position = Vector2(80, 1032)
	ayuda.size = Vector2(1760, 28)
	lienzo.add_child(ayuda)
