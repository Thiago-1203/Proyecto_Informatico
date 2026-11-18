extends Control

signal reiniciar_solicitado
signal volver_al_menu_solicitado
signal aparicion_finalizada

const TEXTO = preload("res://scripts/ui/texto_arcade.gd")
const BOTON = preload("res://scripts/menu/boton_arcade.gd")
const VISTA = preload("res://scripts/menu/vista_previa_personaje.gd")
const FONDO = preload("res://scripts/ui/fondo_victoria.gd")
const BASE := Vector2(1920, 1080)

var velo: ColorRect
var lienzo: Control
var fondo: Control
var resultado: Control
var vista: Control
var texto_ganador: Control
var nombre: Control
var titulo: Control
var ko: Control
var revancha: Button
var menu: Button
var _entrada: Tween
var _animando := false
var _habilitado := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	velo = ColorRect.new()
	velo.color = Color("080d20d9")
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lienzo = Control.new()
	lienzo.size = BASE
	lienzo.clip_contents = true
	add_child(lienzo)
	fondo = FONDO.new()
	fondo.size = BASE
	lienzo.add_child(fondo)
	resultado = Control.new()
	resultado.size = BASE
	resultado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.add_child(resultado)
	_texto("COMBATE FINALIZADO", Rect2(110, 75, 900, 35), 3, Color("9caac1"))
	_texto("POLIFIGHT", Rect2(1460, 75, 350, 35), 4, Color("ffc34a"))
	vista = VISTA.new()
	vista.position = Vector2(180, 290)
	vista.size = Vector2(520, 490)
	resultado.add_child(vista)
	titulo = _texto("VICTORIA", Rect2(850, 265, 940, 120), 15, Color("fff0b5"))
	nombre = _texto("", Rect2(850, 430, 940, 72), 9, Color("ffc34a"))
	texto_ganador = _texto("", Rect2(850, 530, 940, 40), 4, Color("a9c5e5"))
	revancha = _boton("REVANCHA", Rect2(850, 710, 860, 80), reiniciar_solicitado.emit)
	menu = _boton("MENU PRINCIPAL", Rect2(850, 822, 860, 80), volver_al_menu_solicitado.emit)
	revancha.focus_neighbor_bottom = menu.get_path()
	revancha.focus_neighbor_top = menu.get_path()
	menu.focus_neighbor_top = revancha.get_path()
	menu.focus_neighbor_bottom = revancha.get_path()
	revancha.focus_next = menu.get_path()
	menu.focus_next = revancha.get_path()
	_texto("A / ENTER  CONFIRMAR     B / ESC  MENU", Rect2(110, 1008, 1450, 32), 3, Color("a9bbd1"))
	ko = TEXTO.new()
	ko.texto = "K.O."
	ko.tamano_pixel = 22
	ko.color = Color("fff0b5")
	ko.color_sombra = Color("8f2624")
	ko.size = Vector2(800, 220)
	ko.position = (BASE - ko.size) * 0.5
	lienzo.add_child(ko)
	resized.connect(_ajustar)
	_ajustar()
	hide()

func _ajustar() -> void:
	if lienzo == null:
		return
	var escala := minf(size.x / BASE.x, size.y / BASE.y)
	lienzo.scale = Vector2.ONE * escala
	lienzo.position = (size - BASE * escala) * 0.5

func mostrar(numero: int, es_ia: bool, ficha: FichaSeleccion) -> void:
	if _entrada != null and _entrada.is_valid():
		_entrada.kill()
	_habilitado = false
	_animando = true
	revancha.disabled = true
	menu.disabled = true
	texto_ganador.texto = "LA IA GANA!" if es_ia else "JUGADOR %d GANA!" % numero
	nombre.tamano_pixel = 9
	vista.visible = ficha != null
	nombre.texto = ficha.nombre if ficha != null else "JUGADOR %d" % numero
	while nombre.tamano_pixel > 3 and nombre.get_minimum_size().x > 940:
		nombre.tamano_pixel -= 1
	if ficha != null:
		var celebracion := ficha.duplicate() as FichaSeleccion
		# La vista filtra métodos y colisiones; sólo reproduce las pistas del sprite.
		var escena := load(ficha.escena) as PackedScene
		var origen := escena.instantiate()
		var animacion := origen.get_node_or_null(ficha.ruta_animacion) as AnimationPlayer
		if animacion != null and animacion.has_animation(&"victoria"):
			celebracion.animacion_idle = &"victoria"
		origen.free()
		vista.configurar(celebracion)
	show()
	_ajustar()
	velo.modulate.a = 0.0
	fondo.modulate.a = 0.0
	resultado.modulate.a = 0.0
	resultado.position = Vector2(35, 0)
	ko.show()
	ko.modulate.a = 0.0
	ko.pivot_offset = ko.size * 0.5
	ko.scale = Vector2.ONE * 1.2
	_entrada = create_tween().set_ignore_time_scale(true)
	_entrada.set_parallel(true)
	_entrada.tween_property(velo, "modulate:a", 1.0, 0.25)
	_entrada.tween_property(fondo, "modulate:a", 1.0, 0.25)
	_entrada.tween_property(ko, "modulate:a", 1.0, 0.08)
	_entrada.tween_property(ko, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_entrada.chain().tween_interval(0.25)
	_entrada.chain().tween_property(ko, "modulate:a", 0.0, 0.12)
	_entrada.chain().tween_property(resultado, "modulate:a", 1.0, 0.2)
	_entrada.parallel().tween_property(resultado, "position", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await _entrada.finished
	ko.hide()
	_animando = false
	aparicion_finalizada.emit()

func _process(_delta: float) -> void:
	if not visible or _animando or _habilitado:
		return
	# El golpe final o una tecla mantenida no puede disparar una revancha.
	if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_cancel"):
		return
	_habilitado = true
	revancha.disabled = false
	menu.disabled = false
	revancha.grab_focus()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not _habilitado:
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		menu.grab_focus()

func _texto(valor: String, rect: Rect2, pixel: int, color: Color) -> Control:
	var label := TEXTO.new()
	label.texto = valor
	label.tamano_pixel = pixel
	label.color = color
	label.color_sombra = Color("030612")
	label.position = rect.position
	label.size = rect.size
	label.alineacion_horizontal = 0
	resultado.add_child(label)
	return label

func _boton(valor: String, rect: Rect2, accion: Callable) -> Button:
	var boton := BOTON.new()
	boton.texto = valor
	boton.tamano_pixel = 4
	boton.dibujar_marco = true
	boton.color_normal = Color("fff0b5")
	boton.color_borde = Color("6d7890")
	boton.position = rect.position
	boton.size = rect.size
	boton.pressed.connect(accion)
	resultado.add_child(boton)
	return boton
