extends CanvasLayer
## Persiste durante el cambio de escena; el combate queda bloqueado hasta retirar FIGTH.

signal finalizada

const RUTA_CARTEL := "res://assets/ui/combate/figth.png"

var activo: bool = false
var pantalla: Control
var velo: ColorRect
var cartel: TextureRect
var _pausa_anterior: bool = false


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	pantalla = Control.new()
	pantalla.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pantalla.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(pantalla)
	velo = ColorRect.new()
	velo.name = "Fundido"
	velo.color = Color.BLACK
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla.add_child(velo)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cartel = TextureRect.new()
	cartel.name = "CartelFIGTH"
	cartel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cartel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cartel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cartel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla.add_child(cartel)
	pantalla.resized.connect(_ajustar_cartel)
	pantalla.hide()


func _ajustar_cartel() -> void:
	var factor := minf(pantalla.size.x / 1920.0, pantalla.size.y / 1080.0)
	cartel.size = Vector2(1080, 420) * factor
	cartel.position = (pantalla.size - cartel.size) * 0.5
	cartel.pivot_offset = cartel.size * 0.5


func _input(_evento: InputEvent) -> void:
	if activo:
		get_viewport().set_input_as_handled()


func iniciar(escena: String) -> Error:
	if activo:
		return ERR_BUSY
	activo = true
	_pausa_anterior = get_tree().paused
	get_tree().paused = true
	pantalla.show()
	cartel.hide()
	velo.modulate.a = 0.0
	await _fundir(1.0, 0.22)
	var error := get_tree().change_scene_to_file(escena)
	if error != OK:
		await _fundir(0.0, 0.18)
		_terminar()
		return error
	# El cambio de escena queda oculto por el negro; la arena se revela antes del cartel.
	await get_tree().process_frame
	await get_tree().process_frame
	await _fundir(0.0, 0.18)
	await get_tree().create_timer(0.1, true, false, true).timeout
	cartel.texture = load(RUTA_CARTEL) as Texture2D
	_ajustar_cartel()
	cartel.modulate.a = 0.0
	cartel.scale = Vector2.ONE * 1.12
	cartel.show()
	var impacto := create_tween().set_parallel(true).set_ignore_time_scale(true)
	impacto.tween_property(cartel, "modulate:a", 1.0, 0.06)
	impacto.tween_property(cartel, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await impacto.finished
	# Tiempos reales, independientes de la velocidad global del combate.
	await get_tree().create_timer(0.25, true, false, true).timeout
	var salida := create_tween().set_parallel(true).set_ignore_time_scale(true)
	salida.tween_property(cartel, "scale", Vector2.ONE * 1.05, 0.08)
	salida.tween_property(cartel, "modulate:a", 0.0, 0.08)
	await salida.finished
	_terminar()
	return OK


func _fundir(alpha: float, duracion: float) -> void:
	var fundido := create_tween().set_ignore_time_scale(true)
	fundido.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fundido.tween_property(velo, "modulate:a", alpha, duracion)
	await fundido.finished


func _terminar() -> void:
	pantalla.hide()
	cartel.hide()
	activo = false
	get_tree().paused = _pausa_anterior
	finalizada.emit()
