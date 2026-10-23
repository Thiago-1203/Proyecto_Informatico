extends CanvasLayer
## Apertura continua de las hojas y avance de Camera2D sobre la fachada original.

signal finalizada

const FACHADA: Texture2D = preload("res://cinematica_polifight/frames/frame_00.png")
const OSCURIDAD: Texture2D = preload("res://cinematica_polifight/entrada_colegio/oscuro.png")
const TAMANO_FACHADA := Vector2(640, 360)
const CENTRO_INICIAL := Vector2(320, 180)
const CENTRO_PUERTA := Vector2(320, 245)
const ZOOM_FINAL: float = 64.0

@export_range(0.15, 1.0, 0.05) var duracion_apertura: float = 0.30
@export_range(0.3, 2.0, 0.05) var duracion_acercamiento: float = 0.72
@export_range(0.0, 0.4, 0.02) var demora_acercamiento: float = 0.08
@export var fotograma_inicial: Texture2D
var fondo_animado: Control

@onready var pantalla: Control = $Pantalla
@onready var mundo: SubViewport = $Pantalla/Contenedor/Mundo
@onready var fachada: Sprite2D = $Pantalla/Contenedor/Mundo/Fachada
@onready var hueco: Sprite2D = $Pantalla/Contenedor/Mundo/Hueco
@onready var hoja_izquierda: Polygon2D = $Pantalla/Contenedor/Mundo/HojaIzquierda
@onready var hoja_derecha: Polygon2D = $Pantalla/Contenedor/Mundo/HojaDerecha
@onready var camara: Camera2D = $Pantalla/Contenedor/Mundo/Camara

var _tiempo: float = 0.0
var _reproduciendo: bool = false


func _ready() -> void:
	mundo.world_2d = World2D.new()
	pantalla.hide()
	set_process(false)
	set_process_input(false)
	fachada.texture = fotograma_inicial if fotograma_inicial != null else FACHADA
	hueco.texture = OSCURIDAD
	hueco.scale = Vector2(28, 40) / OSCURIDAD.get_size()
	hoja_izquierda.uv = PackedVector2Array([
		Vector2(306, 225), Vector2(320, 225), Vector2(320, 265), Vector2(306, 265),
	])
	hoja_derecha.uv = PackedVector2Array([
		Vector2(320, 225), Vector2(334, 225), Vector2(334, 265), Vector2(320, 265),
	])
	_actualizar_fachada()
	_aplicar_animacion()


func reproducir() -> void:
	if _reproduciendo:
		return
	_tiempo = 0.0
	_reproduciendo = true
	if is_instance_valid(fondo_animado):
		fachada.material = fondo_animado.obtener_material_actual()
	_actualizar_fachada()
	_aplicar_animacion()
	pantalla.show()
	camara.make_current()
	set_process(true)
	set_process_input(true)


func _input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_tiempo += delta
	_actualizar_fachada()
	_aplicar_animacion()
	var duracion_total := maxf(duracion_apertura, demora_acercamiento + duracion_acercamiento) + 0.08
	if _tiempo >= duracion_total:
		_reproduciendo = false
		set_process(false)
		finalizada.emit()


func _actualizar_fachada() -> void:
	if is_instance_valid(fondo_animado):
		fachada.texture = fondo_animado.obtener_fotograma_actual()
	# Las dos hojas toman sus píxeles de la misma fachada, sin imágenes adicionales.
	hoja_izquierda.texture = fachada.texture
	hoja_derecha.texture = fachada.texture


func _aplicar_animacion() -> void:
	var apertura := 1.0 - pow(1.0 - clampf(_tiempo / duracion_apertura, 0.0, 1.0), 3.0)
	var angulo := deg_to_rad(82.0) * apertura
	var ancho := 14.0 * cos(angulo)
	var profundidad := 4.5 * sin(angulo)
	# Los goznes permanecen fijos. Los bordes interiores retroceden hacia el colegio.
	hoja_izquierda.polygon = PackedVector2Array([
		Vector2(306, 225), Vector2(306 + ancho, 225 + profundidad),
		Vector2(306 + ancho, 265 - profundidad), Vector2(306, 265),
	])
	hoja_derecha.polygon = PackedVector2Array([
		Vector2(334 - ancho, 225 + profundidad), Vector2(334, 225),
		Vector2(334, 265), Vector2(334 - ancho, 265 - profundidad),
	])
	var luz := lerpf(1.0, 0.65, apertura)
	hoja_izquierda.modulate = Color(luz, luz, luz)
	hoja_derecha.modulate = Color(luz, luz, luz)

	var avance := clampf((_tiempo - demora_acercamiento) / duracion_acercamiento, 0.0, 1.0)
	var aumento := pow(ZOOM_FINAL, pow(avance, 1.2))
	var encuadre := Vector2(mundo.size) / TAMANO_FACHADA
	camara.zoom = Vector2.ONE * maxf(encuadre.x, encuadre.y) * aumento
	camara.position = CENTRO_INICIAL.lerp(CENTRO_PUERTA, smoothstep(0.0, 0.55, avance))
