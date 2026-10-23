extends Control

signal volver_solicitado

const SELECTOR_COMBATE = preload("res://escenas/menu/selector_combate.tscn")

const TARJETA = preload("res://scripts/menu/tarjeta_modo.gd")
const FONDO_ANIMADO: PackedScene = preload("res://cinematica_polifight/cinematica_colegio.tscn")
const ENTRADA_COLEGIO: PackedScene = preload("res://escenas/menu/entrada_colegio.tscn")
const RESOLUCION := Vector2(1920, 1080)
const MODOS := [
	{
		"titulo": "HISTORIA", "subtitulo": "PROXIMAMENTE",
		"descripcion": "ESTE MODO TODAVIA NO ESTA DISPONIBLE.",
		"arte": preload("res://assets/ui/selector_modos/historia.png"),
		"escena": "",
	},
	{
		"titulo": "1 VS 1", "subtitulo": "DUELO LOCAL",
		"descripcion": "DOS JUGADORES. UN SOLO GANADOR.",
		"arte": preload("res://assets/ui/selector_modos/duelo_local.png"),
		"escena": "seleccion",
	},
	{
		"titulo": "2 VS 2", "subtitulo": "PROXIMAMENTE",
		"descripcion": "ESTE MODO TODAVIA NO ESTA DISPONIBLE.",
		"arte": preload("res://assets/ui/selector_modos/equipos.png"),
		"escena": "",
	},
]

@export var usar_fondo_del_menu: bool = false

@onready var lienzo: Control = $Lienzo
@onready var carrusel: Control = $Lienzo/Carrusel
@onready var indicadores: Control = $Lienzo/Indicadores
@onready var aviso: Control = $Lienzo/Aviso

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
var entrada_puerta: CanvasLayer
var puerta_finalizada: bool = false


func _ready() -> void:
	# El menú conserva su propia instancia y su tiempo de animación al abrir los modos.
	# Al ejecutar esta escena sola en el editor también se muestra un fondo animado.
	if not usar_fondo_del_menu:
		var fondo = FONDO_ANIMADO.instantiate()
		fondo.name = "Fondo"
		fondo.duracion_fundido = 0.0
		add_child(fondo)
		move_child(fondo, 0)
		fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_ajustar_escala)
	indicadores.draw.connect(_dibujar_indicadores)
	for modo in MODOS:
		var tarjeta = TARJETA.new()
		tarjeta.name = "Tarjeta" + str(_tarjetas.size())
		tarjeta.ilustracion = modo["arte"]
		tarjeta.titulo = modo["titulo"]
		tarjeta.subtitulo = modo["subtitulo"]
		tarjeta.descripcion = modo["descripcion"]
		tarjeta.size = Vector2(640, 520)
		carrusel.add_child(tarjeta)
		_tarjetas.append(tarjeta)
	_ajustar_escala()
	_actualizar_tarjetas(false)
	aviso.hide()
	_reproducir_entrada()


func _reproducir_entrada() -> void:
	modulate.a = 0.0
	_entrada = create_tween().set_parallel(true)
	_entrada.tween_property(self, "modulate:a", 1.0, 0.24)
	for i in _tarjetas.size():
		var tarjeta := _tarjetas[i]
		var destino := tarjeta.position
		var central := i == indice_seleccionado
		var desplazamiento := Vector2(0, 72) if central else Vector2(-150 if destino.x < 640 else 150, 32)
		tarjeta.position += desplazamiento
		tarjeta.modulate.a = 0.0
		var demora := 0.04 if central else 0.1
		_entrada.tween_property(tarjeta, "position", destino, 0.38).set_delay(demora).set_trans(
			Tween.TRANS_CUBIC
		).set_ease(Tween.EASE_OUT)
		_entrada.tween_property(tarjeta, "modulate:a", 1.0, 0.25).set_delay(demora)
	await _entrada.finished
	_entrando = false


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
	if _saliendo or _entrando or is_instance_valid(selector_combate) or event.is_echo():
		return
	if event.is_action_pressed(&"modo_volver"):
		get_viewport().set_input_as_handled()
		_saliendo = true
		volver_solicitado.emit()
	elif event.is_action_pressed(&"modo_confirmar") and _confirmacion_habilitada:
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
		var distancia := posmod(i - indice_seleccionado + 1, MODOS.size()) - 1
		var central := distancia == 0
		var escala := Vector2.ONE if central else Vector2.ONE * 0.67
		var destino := Vector2(640, 370) if central else Vector2(110 if distancia < 0 else 1380, 450)
		var color := Color.WHITE if central else Color(0.58, 0.7, 0.86)
		tarjeta.set("seleccionado", central)
		tarjeta.z_index = 2 if central else 1
		if animar:
			_transicion.tween_property(tarjeta, "position", destino, 0.24)
			_transicion.tween_property(tarjeta, "scale", escala, 0.24)
			_transicion.tween_property(tarjeta, "modulate", color, 0.24)
		else:
			tarjeta.position = destino
			tarjeta.scale = escala
			tarjeta.modulate = color
	indicadores.queue_redraw()


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
	puerta_finalizada = false
	if _transicion != null and _transicion.is_valid():
		_transicion.kill()
	var salida := create_tween().set_parallel(true)
	salida.tween_property(lienzo, "modulate:a", 0.0, 0.16)
	salida.tween_property($Oscurecimiento, "modulate:a", 0.0, 0.16)
	await salida.finished
	lienzo.hide()
	entrada_puerta = ENTRADA_COLEGIO.instantiate()
	var fondo := get_parent().get_node_or_null("CinematicaColegio") if usar_fondo_del_menu else get_node_or_null("Fondo")
	if fondo != null:
		entrada_puerta.fotograma_inicial = fondo.obtener_fotograma_actual()
		entrada_puerta.fondo_animado = fondo
	add_child(entrada_puerta)
	entrada_puerta.reproducir()
	await entrada_puerta.finalizada
	puerta_finalizada = true
	entrada_puerta.set_process_input(false)
	entrada_puerta.pantalla.hide()
	entrada_puerta.queue_free()
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
