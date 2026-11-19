extends Control
## Guía compartida por la pausa de combate y la del dojo.
signal volver_solicitado

const TEXTO = preload("res://scripts/ui/texto_arcade.gd")
const BOTON = preload("res://scripts/menu/boton_arcade.gd")
const RESOLUCION := Vector2(1920, 1080)
const AZUL := Color("52b8ff")
const ORO := Color("ffb80d")
const BLANCO := Color("fff0b5")
const GRIS := Color("a6b8ca")
const FILAS := [
	["ACCION", "TECLADO J1", "TECLADO J2", "MANDO: XBOX / PS"],
	["MOVERSE", "A / D", "IZQ. / DER.", "STICK / CRUCETA"],
	["SALTAR", "W", "ARRIBA", "A / CRUZ O ARRIBA"],
	["AGACHARSE", "S", "ABAJO", "DIRECCION ABAJO"],
	["PUÑO", "J", "1 / NUM 1", "X / CUADRADO"],
	["PATADA", "K", "2 / NUM 2", "B / CIRCULO"],
	["BLOQUEAR", "H", "NUM 3", "LB / L1 O LT / L2"],
	["ULTI", "L", "3", "Y / TRIANGULO"],
	["PAUSA", "ESC", "ESC", "START / OPTIONS"],
]

var lienzo: Control
var nota: Control
var boton_volver: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sombra := ColorRect.new()
	sombra.color = Color("030715ed")
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sombra)
	sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lienzo = Control.new()
	lienzo.size = RESOLUCION
	add_child(lienzo)
	var panel := Panel.new()
	panel.position = Vector2(100, 100)
	panel.size = Vector2(1720, 880)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("0d172c")
	estilo.border_color = AZUL
	estilo.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", estilo)
	lienzo.add_child(panel)
	_texto("TUS CONTROLES", Rect2(150, 140, 1600, 55), 6, BLANCO)
	var xs := [150, 545, 880, 1250]
	var anchos := [365, 305, 340, 520]
	for f in FILAS.size():
		for c in 4:
			_texto(FILAS[f][c], Rect2(xs[c], 235 + f * 62, anchos[c], 32), 4 if f > 0 else 3, BLANCO if c == 0 else (AZUL if c < 3 else ORO))
	nota = _texto("", Rect2(150, 815, 1620, 26), 3, GRIS)
	_texto("EN OTROS MANDOS USA LAS MISMAS POSICIONES DE BOTON.", Rect2(150, 855, 1620, 26), 3, GRIS)
	boton_volver = BOTON.new()
	boton_volver.texto = "< VOLVER"
	boton_volver.tamano_pixel = 3
	boton_volver.dibujar_marco = true
	boton_volver.position = Vector2(1370, 901)
	boton_volver.size = Vector2(390, 54)
	lienzo.add_child(boton_volver)
	for propiedad in ["focus_neighbor_top", "focus_neighbor_bottom", "focus_neighbor_left", "focus_neighbor_right", "focus_previous", "focus_next"]:
		boton_volver.set(propiedad, boton_volver.get_path())
	boton_volver.pressed.connect(volver_solicitado.emit)
	resized.connect(_ajustar_escala)
	_ajustar_escala()
	hide()

func abrir(en_tutorial: bool = false) -> void:
	nota.texto = "EN EL TUTORIAL JUEGAS COMO J1. EN DUELO LOCAL, CADA JUGADOR TIENE SUS TECLAS." if en_tutorial else "J1 Y J2 TIENEN SUS PROPIAS TECLAS. CADA MANDO CONTROLA A SU JUGADOR."
	show()
	_ajustar_escala()
	boton_volver.grab_focus()

func _ajustar_escala() -> void:
	var factor := minf(size.x / RESOLUCION.x, size.y / RESOLUCION.y)
	lienzo.scale = Vector2.ONE * factor
	lienzo.position = (size - RESOLUCION * factor) * 0.5

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or event.is_echo():
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pausa"):
		get_viewport().set_input_as_handled()
		if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_B:
			var jugador: int = get_node("/root/EntradaMandos").jugador_para_dispositivo(event.device)
			if jugador >= 0:
				Input.action_release(StringName("j%d_patada" % (jugador + 1)))
		volver_solicitado.emit()

func _texto(valor: String, rect: Rect2, pixel: int, color: Color) -> Control:
	var texto := TEXTO.new()
	texto.texto = valor
	texto.tamano_pixel = pixel
	texto.color = color
	texto.alineacion_horizontal = 0
	texto.desplazamiento_sombra = Vector2(2, 2)
	texto.position = rect.position
	texto.size = rect.size
	lienzo.add_child(texto)
	return texto
