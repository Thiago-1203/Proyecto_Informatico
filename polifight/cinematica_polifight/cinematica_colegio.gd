extends Control
## Fondo independiente: se puede instanciar detrás de los controles del menú.

signal entrada_finalizada

@export_category("Animación pixel art")
@export_range(2.0, 12.0, 1.0) var cuadros_por_segundo: float = 4.0
@export_range(1.0, 12.0, 1.0) var velocidad_nubes_pixeles: float = 4.0
@export var reproducir_animacion: bool = true

@export_category("Entrada")
@export_range(0.0, 5.0, 0.1) var duracion_fundido: float = 1.2

const FOTOGRAMAS := [
	preload("frames/frame_00.png"),
	preload("frames/frame_01.png"),
	preload("frames/frame_02.png"),
	preload("frames/frame_03.png"),
	preload("frames/frame_04.png"),
	preload("frames/frame_05.png"),
	preload("frames/frame_06.png"),
	preload("frames/frame_07.png"),
	preload("frames/frame_08.png"),
	preload("frames/frame_09.png"),
	preload("frames/frame_10.png"),
	preload("frames/frame_11.png"),
	preload("frames/frame_12.png"),
	preload("frames/frame_13.png"),
	preload("frames/frame_14.png"),
	preload("frames/frame_15.png"),
]
const SHADER_NUBES: Shader = preload("nubes.gdshader")
const TEXTURA_NUBES: Texture2D = preload("frames/nubes.png")
const MASCARA_CIELO: Texture2D = preload("frames/mascara_cielo.png")

var _fondo: TextureRect
var _material_nubes: ShaderMaterial
var _tiempo_animacion: float = 0.0
var _fotograma_actual: int = -1


func _ready() -> void:
	# Los elementos no interceptan los botones del menú colocados encima.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fondo = TextureRect.new()
	_fondo.name = "FondoAnimado"
	_fondo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fondo)
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_material_nubes = ShaderMaterial.new()
	_material_nubes.shader = SHADER_NUBES
	_material_nubes.set_shader_parameter("textura_nubes", TEXTURA_NUBES)
	_material_nubes.set_shader_parameter("mascara_cielo", MASCARA_CIELO)
	_fondo.material = _material_nubes
	_mostrar_fotograma(0)

	var negro := ColorRect.new()
	negro.name = "Fundido"
	negro.color = Color.BLACK
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(negro)
	negro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if duracion_fundido > 0.0:
		var fundido := create_tween()
		fundido.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		fundido.tween_property(negro, "modulate:a", 0.0, duracion_fundido)
		await fundido.finished
	negro.queue_free()
	entrada_finalizada.emit()


func _process(delta: float) -> void:
	if not reproducir_animacion or FOTOGRAMAS.is_empty():
		return
	_tiempo_animacion += delta
	var indice := int(floor(_tiempo_animacion * cuadros_por_segundo)) % FOTOGRAMAS.size()
	_mostrar_fotograma(indice)
	var recorrido_nubes := fposmod(_tiempo_animacion * velocidad_nubes_pixeles, 640.0)
	_material_nubes.set_shader_parameter("desplazamiento_px", recorrido_nubes)


func _mostrar_fotograma(indice: int) -> void:
	if _fondo == null or indice == _fotograma_actual:
		return
	_fotograma_actual = indice
	_fondo.texture = FOTOGRAMAS[indice]
