extends Control

@onready var seleccion: EstadoSeleccionPartida = get_node("/root/SeleccionPartida")
## Flujo compartido por teclado, mando y mouse. Las tarjetas salen del catálogo.

signal aparicion_finalizada
signal volver_solicitado
signal combate_solicitado(escena: String)

const OSCURIDAD_PUERTA: Texture2D = preload("res://cinematica_polifight/entrada_colegio/oscuro.png")
const FONDO_UI = preload("res://scripts/menu/menu_fondo.gd")
const CABECERA = preload("res://scripts/menu/menu_cabecera.gd")
const OPCION = preload("res://scripts/menu/tarjeta_opcion.gd")
const TEXTO = preload("res://scripts/ui/texto_arcade.gd")
const VISTA = preload("res://scripts/menu/vista_previa_personaje.gd")
const BOTON = preload("res://scripts/menu/boton_arcade.gd")
const AZUL := Color("52b8ff")
const DORADO := Color("ffb80d")
const BLANCO := Color("fff0b5")
const RESOLUCION := Vector2(1920, 1080)
const COLUMNAS_PERSONAJES := 2
const POSICIONES_VISTAS := [Vector2(125, 350), Vector2(1305, 350)]
enum Paso { PERSONAJES, ESCENARIO, RIVAL, DIFICULTAD }
enum Foco { TARJETAS, LISTO, CONTINUAR, VOLVER }

var _usando_mando := false
var fondo_ui: Control
var cabecera: Control
var jugador_mouse: int = 0
var opciones_configuracion: Array[Button] = []
var paso: Paso = Paso.RIVAL
var opcion_configuracion: int = 0
var _ayuda: Control
var listos: Array[bool] = [false, false]
var focos: Array[int] = [Foco.TARJETAS, Foco.TARJETAS]
var vistas: Array[Control] = []
var botones_listo: Array[Button] = []
var boton_continuar: Button
var _direccion_mando: Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO]
var _repeticion_mando: Array[float] = [0.0, 0.0]
var indices: Array[int] = [0, 0]
var indice_escenario: int = 0
var lienzo: Control
var contenido: Control
var tarjetas: Array[Button] = []
var scroll: ScrollContainer
var estadisticas_visibles: Array[Dictionary] = [{}, {}]
var _entrando: bool = false
var _aparicion: Tween
var _habilitado: bool = false
var _iniciando: bool = false
var _mensaje: Control
var _boton_volver: Button
var fondo_escenario: TextureRect
var sombra_fondo: ColorRect


func _ready() -> void:
	seleccion.reiniciar()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var base_negra := ColorRect.new()
	base_negra.color = Color.BLACK
	base_negra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base_negra)
	base_negra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo_escenario = TextureRect.new()
	fondo_escenario.name = "FondoEscenario"
	fondo_escenario.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo_escenario.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo_escenario.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo_escenario)
	fondo_escenario.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sombra_fondo = ColorRect.new()
	sombra_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material_fondo := ShaderMaterial.new()
	material_fondo.shader = preload("res://assets/shaders/fondo_seleccion.gdshader")
	sombra_fondo.material = material_fondo
	add_child(sombra_fondo)
	sombra_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lienzo = Control.new()
	lienzo.size = RESOLUCION
	lienzo.clip_contents = true
	add_child(lienzo)
	resized.connect(_ajustar_escala)
	_ajustar_escala()
	fondo_ui = FONDO_UI.new()
	lienzo.add_child(fondo_ui)
	cabecera = CABECERA.new()
	lienzo.add_child(cabecera)
	_crear_marco()
	for i in 2:
		var vista := VISTA.new()
		vista.position = POSICIONES_VISTAS[i]
		vista.size = Vector2(490, 400)
		vista.z_index = 2
		lienzo.add_child(vista)
		vistas.append(vista)
	_renderizar()
	_animar_aparicion()


func _ajustar_escala() -> void:
	if lienzo == null:
		return
	var factor := minf(size.x / RESOLUCION.x, size.y / RESOLUCION.y)
	lienzo.scale = Vector2.ONE * factor
	lienzo.position = (size - RESOLUCION * factor) * 0.5


func _animar_aparicion() -> void:
	if _aparicion != null and _aparicion.is_valid():
		_aparicion.kill()
	_entrando = true
	_habilitado = false
	lienzo.modulate.a = 0.0
	contenido.position.y = 20.0
	fondo_escenario.modulate.a = 0.0 if paso == Paso.ESCENARIO else 1.0
	_aparicion = create_tween().set_parallel(true)
	_aparicion.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_aparicion.tween_property(lienzo, "modulate:a", 1.0, 0.55).set_delay(0.08)
	_aparicion.tween_property(contenido, "position:y", 0.0, 0.55).set_delay(0.08)
	_aparicion.tween_property(fondo_escenario, "modulate:a", 1.0, 0.6)
	for j in vistas.size():
		var vista := vistas[j]
		var destino: float = POSICIONES_VISTAS[j].x
		vista.position.x = destino + (-44.0 if j == 0 else 44.0)
		_aparicion.tween_property(vista, "position:x", destino, 0.55).set_delay(0.08 + j * 0.04)
	await _aparicion.finished
	_entrando = false
	aparicion_finalizada.emit()


func _process(delta: float) -> void:
	if _iniciando or _entrando:
		return
	if not _habilitado:
		_habilitado = not (Input.is_action_pressed(&"modo_confirmar") or Input.is_physical_key_pressed(KEY_F))
		return
	# Cada mando tiene su propio cursor, igual que cada grupo de teclas.
	for j in 2:
		var direccion: Vector2i = get_node("/root/EntradaMandos").direccion_menu(j)
		if direccion == Vector2i.ZERO:
			_direccion_mando[j] = direccion
		elif direccion != _direccion_mando[j]:
			_direccion_mando[j] = direccion
			_repeticion_mando[j] = 0.35
			_navegar(j, direccion)
		else:
			_repeticion_mando[j] -= delta
			if _repeticion_mando[j] <= 0.0:
				_repeticion_mando[j] = 0.18
				_navegar(j, direccion)


func _input(event: InputEvent) -> void:
	# El selector tiene dos cursores propios: no dejar que la GUI procese
	# de nuevo los mismos sticks o botones y cambie el foco por su cuenta.
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()
		_usando_mando = true
		_actualizar_ayuda()
	elif event is InputEventKey or event is InputEventMouseButton:
		_usando_mando = false
		_actualizar_ayuda()
	if not _habilitado or _iniciando or _entrando:
		return
	if event is InputEventKey and event.pressed:
		var tecla: int = event.physical_keycode if event.physical_keycode else event.keycode
		var teclas := [KEY_A, KEY_D, KEY_W, KEY_S, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]
		var indice := teclas.find(tecla)
		if indice >= 0:
			var direcciones := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
			_navegar(0 if indice < 4 else 1, direcciones[indice % 4])
			get_viewport().set_input_as_handled()
		elif not event.echo and tecla in [KEY_F, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
			_activar(0 if tecla in [KEY_F, KEY_SPACE] else 1)
		elif not event.echo and tecla == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_volver()
	elif event is InputEventJoypadButton and event.pressed:
		var jugador: int = get_node("/root/EntradaMandos").registrar_dispositivo(event.device)
		if jugador < 0:
			return
		get_viewport().set_input_as_handled()
		if event.button_index == JOY_BUTTON_A:
			_activar(jugador)
		elif event.button_index == JOY_BUTTON_B:
			_volver()


func _navegar(jugador: int, direccion: Vector2i) -> void:
	if paso in [Paso.RIVAL, Paso.DIFICULTAD]:
		opcion_configuracion = posmod(opcion_configuracion + direccion.x + direccion.y, 2 if paso == Paso.RIVAL else 3)
		_renderizar()
		return
	jugador = _cursor_humano(jugador)
	jugador_mouse = jugador
	if _iniciando or _entrando:
		return
	var cantidad := seleccion.escenarios.size() if paso == Paso.ESCENARIO else seleccion.personajes.size()
	var columnas := 6 if paso == Paso.ESCENARIO else COLUMNAS_PERSONAJES
	var indice := indice_escenario if paso == Paso.ESCENARIO else indices[jugador]
	match focos[jugador]:
		Foco.TARJETAS:
			if direccion.x != 0:
				_elegir(posmod(indice + direccion.x, cantidad + 1), jugador)
				return
			var destino := indice + direccion.y * columnas
			if destino >= 0 and destino <= cantidad:
				_elegir(destino, jugador)
				return
			focos[jugador] = (Foco.CONTINUAR if paso == Paso.ESCENARIO else Foco.LISTO) if direccion.y > 0 else Foco.VOLVER
		Foco.LISTO:
			focos[jugador] = Foco.TARJETAS if direccion.y < 0 else (Foco.CONTINUAR if listos[0] and listos[1] else Foco.VOLVER)
		Foco.CONTINUAR:
			focos[jugador] = (Foco.TARJETAS if paso == Paso.ESCENARIO else Foco.LISTO) if direccion.y < 0 else Foco.VOLVER
		Foco.VOLVER:
			focos[jugador] = Foco.TARJETAS if direccion.y < 0 else (Foco.CONTINUAR if paso == Paso.ESCENARIO or (listos[0] and listos[1]) else Foco.LISTO)
	_renderizar()


func _elegir(indice: int, jugador: int = 0) -> void:
	if _iniciando or _entrando:
		return
	focos[jugador] = Foco.TARJETAS
	if paso == Paso.ESCENARIO:
		indice_escenario = indice
		if indice < seleccion.escenarios.size():
			seleccion.escenario = seleccion.escenarios[indice]
	else:
		indices[jugador] = indice
		listos[jugador] = false
		if indice < seleccion.personajes.size():
			seleccion.jugadores[jugador] = seleccion.personajes[indice]
	_renderizar()
	if indice < tarjetas.size():
		scroll.call_deferred("ensure_control_visible", tarjetas[indice])


func _elegir_mouse(indice: int) -> void:
	_elegir(indice, _cursor_humano(jugador_mouse))


func _tarjeta_mouse(event: InputEvent, indice: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_elegir(indice, _cursor_humano(1))
		get_viewport().set_input_as_handled()


func _activar(jugador: int) -> void:
	if paso in [Paso.RIVAL, Paso.DIFICULTAD]:
		_confirmar_configuracion(opcion_configuracion)
		return
	jugador = _cursor_humano(jugador)
	match focos[jugador]:
		Foco.VOLVER: _volver()
		Foco.CONTINUAR:
			if paso == Paso.ESCENARIO:
				_iniciar()
			else:
				_ir_escenarios()
		Foco.TARJETAS, Foco.LISTO:
			if paso == Paso.ESCENARIO:
				if indice_escenario < seleccion.escenarios.size():
					focos[jugador] = Foco.CONTINUAR
					_renderizar()
			else:
				_alternar_listo(jugador)


func _alternar_listo(jugador: int) -> void:
	if _iniciando or _entrando:
		return
	if indices[jugador] >= seleccion.personajes.size():
		_mensaje.texto = "CASILLA VACIA / PROXIMAMENTE"
		return
	listos[jugador] = not listos[jugador]
	focos[jugador] = Foco.LISTO
	if listos[0] and listos[1]:
		focos.assign([Foco.CONTINUAR, Foco.CONTINUAR])
	_renderizar()
	if listos[jugador] and vistas[jugador].visible:
		var vista := vistas[jugador]
		vista.modulate = Color("ffe9a0")
		var golpe := vista.create_tween()
		golpe.tween_property(vista, "modulate", Color.WHITE, 0.22)
		var boton := botones_listo[jugador]
		boton.modulate = Color("ffe9a0")
		golpe.parallel().tween_property(boton, "modulate", Color.WHITE, 0.22)


func _ir_escenarios() -> void:
	if _iniciando or _entrando or not (listos[0] and listos[1]) or seleccion.escenarios.is_empty():
		return
	paso = Paso.ESCENARIO
	focos.assign([Foco.TARJETAS, Foco.TARJETAS])
	_renderizar()
	_animar_aparicion()


func _iniciar() -> void:
	if _iniciando or _entrando or indice_escenario >= seleccion.escenarios.size():
		return
	_iniciando = true
	combate_solicitado.emit(seleccion.escenario.escena)


func _volver() -> void:
	if _iniciando or _entrando:
		return
	if paso == Paso.ESCENARIO:
		paso = Paso.PERSONAJES
		listos.assign([false, false])
		focos.assign([Foco.TARJETAS, Foco.TARJETAS])
		_renderizar()
		_animar_aparicion()
	elif paso == Paso.PERSONAJES:
		paso = Paso.DIFICULTAD if seleccion.contra_ia else Paso.RIVAL
		opcion_configuracion = seleccion.dificultad_ia if seleccion.contra_ia else 0
		listos.assign([false, false])
		focos.assign([Foco.TARJETAS, Foco.TARJETAS])
		_renderizar()
	elif paso == Paso.DIFICULTAD:
		paso = Paso.RIVAL
		opcion_configuracion = 1
		_renderizar()
	else:
		volver_solicitado.emit()


func mostrar_error() -> void:
	_iniciando = false
	_habilitado = false
	_mensaje.texto = "NO SE PUDO CARGAR. INTENTA OTRA VEZ."


func _mascara_foco(tipo: Foco) -> int:
	var mascara := 0
	for j in 2:
		if focos[j] == tipo:
			mascara |= 1 << j
	return mascara


func _crear_marco() -> void:
	contenido = lienzo
	_boton_volver = _boton("<  VOLVER", Rect2(80, 942, 270, 56), _volver, 3)
	_ayuda = _texto("", Rect2(80, 1032, 1760, 28), 3, Color("91a5ba"))
	_mensaje = _texto("", Rect2(390, 966, 890, 28), 2, DORADO)
	contenido = null


func _renderizar() -> void:
	if contenido != null:
		contenido.hide()
		contenido.queue_free()
	contenido = Control.new()
	contenido.size = RESOLUCION
	contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# El contenido pertenece al lienzo para compartir la escala de toda la interfaz.
	contenido.position = Vector2.ZERO
	lienzo.add_child(contenido)
	tarjetas.clear()
	opciones_configuracion.clear()
	cabecera.paso = 3 if paso == Paso.ESCENARIO else (2 if paso == Paso.PERSONAJES else 1)
	botones_listo.clear()
	boton_continuar = null
	_mensaje.texto = ""
	_boton_volver.show()
	_boton_volver.position = Vector2(80, 942)
	_boton_volver.size = Vector2(270, 56)
	_boton_volver.foco_jugadores = _mascara_foco(Foco.VOLVER)
	_boton_volver.texto = "<  LUCHADORES" if paso == Paso.ESCENARIO else "<  VOLVER"
	_boton_volver.tamano_pixel = 2 if paso == Paso.ESCENARIO else 3
	_boton_volver.queue_redraw()
	fondo_escenario.texture = seleccion.escenario.imagen if paso == Paso.ESCENARIO else OSCURIDAD_PUERTA
	fondo_escenario.modulate = Color.WHITE
	sombra_fondo.visible = paso == Paso.ESCENARIO
	fondo_ui.visible = paso != Paso.ESCENARIO
	if seleccion.personajes.is_empty() or seleccion.escenarios.is_empty():
		_texto("NO HAY CONTENIDO DISPONIBLE", Rect2(490, 450, 940, 80), 5, DORADO)
		return
	for j in 2:
		vistas[j].visible = paso == Paso.PERSONAJES and indices[j] < seleccion.personajes.size()
		if vistas[j].visible:
			vistas[j].configurar(seleccion.jugadores[j], j == 1)
	_actualizar_ayuda()
	if paso in [Paso.RIVAL, Paso.DIFICULTAD]:
		_renderizar_configuracion()
	elif paso == Paso.ESCENARIO:
		_renderizar_escenarios()
	else:
		_renderizar_personajes()
	_sincronizar_foco()


func _renderizar_personajes() -> void:
	var eligiendo_ia := seleccion.contra_ia and listos[0] and not listos[1]
	_texto("ELIGE A LA IA" if eligiendo_ia else "ELIGE TU LUCHADOR", Rect2(100, 185, 1720, 64), 8, BLANCO)
	for i in 2:
		var ficha := seleccion.jugadores[i]
		var x := 100.0 if i == 0 else 1300.0
		var color := AZUL if i == 0 else DORADO
		var vacio := indices[i] >= seleccion.personajes.size()
		estadisticas_visibles[i] = {} if vacio else ficha.obtener_estadisticas()
		_texto("IA" if seleccion.contra_ia and i == 1 else "JUGADOR %d" % (i + 1), Rect2(x, 290, 520, 35), 4, color)
		_texto("PROXIMAMENTE" if vacio else ficha.nombre, Rect2(x, 774, 520, 58), 6, BLANCO)
		var boton := _boton("LISTO!" if listos[i] else "CONFIRMAR", Rect2(x + 25, 855, 470, 64), _alternar_listo.bind(i), 4)
		boton.foco_jugadores = (1 << i) if focos[i] == Foco.LISTO else 0
		boton.color_normal = color
		boton.color_borde = color
		botones_listo.append(boton)
	for i in 2:
		var tab := _boton("IA" if seleccion.contra_ia and i == 1 else "J%d" % (i + 1), Rect2(725 + i * 245, 340, 225, 48), _seleccionar_cursor_mouse.bind(i), 3)
		tab.color_normal = AZUL if i == 0 else DORADO
		tab.color_borde = tab.color_normal if _cursor_humano(jugador_mouse) == i else Color("344465")
	_crear_grilla(Rect2(725, 420, 470, 285), COLUMNAS_PERSONAJES, seleccion.personajes)
	_texto("VS", Rect2(780, 750, 360, 70), 9, DORADO)
	boton_continuar = _boton("ELEGIR ARENA", Rect2(700, 946, 520, 64), _ir_escenarios, 4)
	boton_continuar.foco_jugadores = _mascara_foco(Foco.CONTINUAR)
	boton_continuar.disabled = not (listos[0] and listos[1])
	boton_continuar.color_borde = DORADO
	boton_continuar.modulate.a = 1.0 if not boton_continuar.disabled else 0.35
	_boton_volver.position = Vector2(100, 954)
	_boton_volver.size = Vector2(270, 48)
	_boton_volver.tamano_pixel = 3


func _renderizar_escenarios() -> void:
	var ficha := seleccion.escenario
	_texto("ELIGE LA ARENA", Rect2(100, 185, 1720, 64), 8, BLANCO)
	_texto("", Rect2(80, 231, 1400, 24), 2, Color("a6b8ca")).alineacion_horizontal = 0
	_texto("PROXIMAMENTE" if indice_escenario >= seleccion.escenarios.size() else ficha.nombre, Rect2(80, 316, 1540, 110), 10, BLANCO).alineacion_horizontal = 0
	_panel(Rect2(80, 449, 100, 4), DORADO, Color.TRANSPARENT)
	_texto(ficha.subtitulo, Rect2(80, 480, 1200, 32), 3, DORADO).alineacion_horizontal = 0
	_texto("", Rect2(80, 527, 1200, 28), 2, BLANCO).alineacion_horizontal = 0
	_panel(Rect2(80, 635, 1760, 64), Color("0b1727ee"), Color("304053"))
	_texto(seleccion.jugadores[0].nombre + "  VS  " + seleccion.jugadores[1].nombre, Rect2(110, 655, 1000, 26), 3, BLANCO).alineacion_horizontal = 0
	_texto("IA / " + seleccion.NOMBRES_DIFICULTAD[seleccion.dificultad_ia] if seleccion.contra_ia else "MULTIJUGADOR LOCAL", Rect2(1250, 655, 560, 26), 2, DORADO).alineacion_horizontal = 2
	_texto("ARENAS DISPONIBLES", Rect2(80, 737, 700, 28), 2, Color("a6b8ca")).alineacion_horizontal = 0
	_crear_grilla(Rect2(80, 785, 1760, 150), 6, seleccion.escenarios)
	var confirmar := _boton("A PELEAR  >", Rect2(1370, 950, 470, 48), _iniciar, 3)
	boton_continuar = confirmar
	confirmar.foco_jugadores = _mascara_foco(Foco.CONTINUAR)
	confirmar.disabled = indice_escenario >= seleccion.escenarios.size()
	confirmar.modulate.a = 0.4 if confirmar.disabled else 1.0
	confirmar.color_normal = BLANCO
	confirmar.color_borde = DORADO
	confirmar.color_fondo = Color("55401a")


func _crear_grilla(rect: Rect2, columnas: int, fichas: Array[FichaSeleccion]) -> void:
	scroll = ScrollContainer.new()
	scroll.position = rect.position
	scroll.size = rect.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	contenido.add_child(scroll)
	var grilla := GridContainer.new()
	grilla.columns = columnas
	grilla.add_theme_constant_override("h_separation", 16)
	grilla.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grilla)
	for i in fichas.size() + 1:
		var vacia := i == fichas.size()
		var tarjeta := Button.new()
		tarjeta.custom_minimum_size = Vector2((rect.size.x - 24 - 16 * (columnas - 1)) / columnas, 150 if paso == Paso.ESCENARIO else 260)
		tarjeta.focus_mode = Control.FOCUS_NONE
		tarjeta.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tarjeta.tooltip_text = "CASILLA VACIA / PROXIMAMENTE" if vacia else fichas[i].nombre
		var mascara := 0
		for j in 2:
			if focos[j] == Foco.TARJETAS and i == (indice_escenario if paso == Paso.ESCENARIO else indices[j]):
				mascara |= 1 << j
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color("283b64") if mascara else Color("10172c")
		estilo.border_color = (AZUL if mascara == 1 else DORADO) if mascara else Color("235285")
		estilo.set_border_width_all(5 if mascara else 3)
		tarjeta.add_theme_stylebox_override("normal", estilo)
		var hover := estilo.duplicate() as StyleBoxFlat
		hover.border_color = BLANCO
		tarjeta.add_theme_stylebox_override("hover", hover)
		tarjeta.add_theme_stylebox_override("pressed", hover)
		tarjeta.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		grilla.add_child(tarjeta)
		if mascara:
			var pulso := tarjeta.create_tween().set_loops()
			pulso.tween_property(estilo, "border_color", estilo.border_color.lightened(0.2), 0.65).set_trans(Tween.TRANS_SINE)
			pulso.tween_property(estilo, "border_color", estilo.border_color, 0.65).set_trans(Tween.TRANS_SINE)
		tarjetas.append(tarjeta)
		tarjeta.pressed.connect(_elegir_mouse.bind(i))
		tarjeta.gui_input.connect(_tarjeta_mouse.bind(i))
		var ancho := tarjeta.custom_minimum_size.x
		if vacia:
			_texto("?", Rect2(6, 30 if paso == Paso.ESCENARIO else 65, ancho - 12, 60), 4 if paso == Paso.ESCENARIO else 6, Color("53677f"), tarjeta)
			_texto("PRONTO", Rect2(6, tarjeta.custom_minimum_size.y - 40, ancho - 12, 28), 3, Color("8193a8"), tarjeta)
		else:
			# El retrato de la cuadrícula es estático; el idle queda en las vistas laterales.
			_imagen(fichas[i].imagen, Rect2(18, 38, ancho - 36, tarjeta.custom_minimum_size.y - 90), false, tarjeta)
			_texto(fichas[i].nombre, Rect2(6, tarjeta.custom_minimum_size.y - 40, ancho - 12, 28), 3, BLANCO, tarjeta)
		for j in 2:
			if i == (indice_escenario if paso == Paso.ESCENARIO else indices[j]):
				_texto(("IA" if seleccion.contra_ia and j == 1 else "J%d" % (j + 1)), Rect2(8 + j * (ancho * 0.5), 8, ancho * 0.5 - 16, 18), 2, AZUL if j == 0 else DORADO, tarjeta)


func _panel(rect: Rect2, fondo: Color, borde: Color) -> void:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", estilo)
	contenido.add_child(panel)


func _texto(valor: String, rect: Rect2, pixel: int, color: Color, padre: Control = null) -> Control:
	var texto := TEXTO.new()
	texto.texto = valor
	texto.tamano_pixel = pixel
	texto.color = color
	texto.desplazamiento_sombra = Vector2(2, 2)
	# También caben nombres futuros más largos dentro de su tarjeta.
	while texto.tamano_pixel > 2 and texto.get_minimum_size().x > rect.size.x:
		texto.tamano_pixel -= 1
	texto.position = rect.position
	texto.size = rect.size
	(padre if padre != null else contenido).add_child(texto)
	return texto


func _imagen(textura: Texture2D, rect: Rect2, espejo: bool = false, padre: Control = null) -> void:
	var imagen := TextureRect.new()
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.texture = textura
	imagen.position = rect.position
	imagen.size = rect.size
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen.flip_h = espejo
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(padre if padre != null else contenido).add_child(imagen)


func _boton(valor: String, rect: Rect2, accion: Callable, pixel: int) -> Button:
	var boton := BOTON.new()
	boton.texto = valor
	boton.tamano_pixel = pixel
	boton.dibujar_marco = true
	boton.grosor_borde = 3
	boton.color_borde = Color("596780")
	boton.color_normal = BLANCO
	boton.color_fondo = Color("111b36")
	boton.position = rect.position
	boton.size = rect.size
	boton.focus_mode = Control.FOCUS_NONE
	boton.pressed.connect(accion)
	contenido.add_child(boton)
	return boton


func _cursor_humano(jugador: int) -> int:
	if seleccion.contra_ia:
		if paso == Paso.PERSONAJES and listos[0] and not listos[1]:
			return 1
		return 0
	return jugador


func _confirmar_configuracion(indice: int) -> void:
	if _entrando or _iniciando:
		return
	if paso == Paso.RIVAL:
		seleccion.contra_ia = indice == 1
		paso = Paso.DIFICULTAD if seleccion.contra_ia else Paso.PERSONAJES
		opcion_configuracion = seleccion.dificultad_ia if seleccion.contra_ia else 0
	else:
		seleccion.dificultad_ia = indice as EstadoSeleccionPartida.Dificultad
		paso = Paso.PERSONAJES
	_renderizar()
	_animar_contenido()
	_habilitado = false


func _renderizar_configuracion() -> void:
	var rival := paso == Paso.RIVAL
	_texto("ELIGE TU RIVAL" if rival else "ELIGE LA DIFICULTAD", Rect2(100, 185, 1720, 64), 8, BLANCO)
	var titulos := ["CON UN AMIGO", "CONTRA LA IA"] if rival else ["FACIL", "NORMAL", "DIFICIL"]
	var detalles := ["DOS JUGADORES EN ESTE EQUIPO", "UN JUGADOR CONTRA LA COMPUTADORA"] if rival else ["PARA PRACTICAR", "UNA PELEA EQUILIBRADA", "MAS PRESION"]
	for i in titulos.size():
		var tarjeta := OPCION.new()
		tarjeta.titulo = titulos[i]
		tarjeta.icono = i if rival else i + 2
		tarjeta.acento = DORADO
		tarjeta.elegido = opcion_configuracion == i
		tarjeta.position = Vector2(360, (400 if rival else 335) + i * 155)
		tarjeta.size = Vector2(1200, 116)
		tarjeta.pressed.connect(_elegir_configuracion.bind(i))
		contenido.add_child(tarjeta)
		opciones_configuracion.append(tarjeta)
	_texto(detalles[opcion_configuracion], Rect2(360, 835, 1200, 32), 3, Color("a6b8ca"))
	boton_continuar = _boton("CONTINUAR", Rect2(1370, 946, 470, 56), _confirmar_opcion_actual, 4)
	boton_continuar.color_borde = DORADO


func _elegir_configuracion(indice: int) -> void:
	if _entrando or _iniciando:
		return
	opcion_configuracion = indice
	_renderizar()


func _confirmar_opcion_actual() -> void:
	_confirmar_configuracion(opcion_configuracion)


func _seleccionar_cursor_mouse(jugador: int) -> void:
	jugador_mouse = _cursor_humano(jugador)
	_renderizar()


func _actualizar_ayuda() -> void:
	if _ayuda == null:
		return
	if _usando_mando:
		_ayuda.texto = "CRUCETA  ELEGIR     A  CONFIRMAR     B  VOLVER"
	elif paso == Paso.PERSONAJES and not seleccion.contra_ia:
		_ayuda.texto = "J1  WASD + F     J2  FLECHAS + ENTER     ESC  VOLVER"
	else:
		_ayuda.texto = "FLECHAS  ELEGIR     ENTER  CONFIRMAR     ESC  VOLVER"


func _sincronizar_foco() -> void:
	var objetivo: Control
	if paso in [Paso.RIVAL, Paso.DIFICULTAD]:
		objetivo = opciones_configuracion[opcion_configuracion]
	else:
		var jugador := _cursor_humano(jugador_mouse)
		match focos[jugador]:
			Foco.VOLVER: objetivo = _boton_volver
			Foco.CONTINUAR: objetivo = boton_continuar
			Foco.LISTO: objetivo = botones_listo[jugador] if not botones_listo.is_empty() else boton_continuar
			_: objetivo = tarjetas[mini(indice_escenario if paso == Paso.ESCENARIO else indices[jugador], tarjetas.size() - 1)] if not tarjetas.is_empty() else _boton_volver
	if objetivo != null:
		objetivo.focus_mode = Control.FOCUS_ALL
		objetivo.grab_focus()


func _animar_contenido() -> void:
	contenido.modulate.a = 0.0
	var entrada := contenido.create_tween().set_parallel(true)
	entrada.tween_property(contenido, "modulate:a", 1.0, 0.18)
	for i in opciones_configuracion.size():
		var fila := opciones_configuracion[i]
		var destino := fila.position
		fila.position.x -= 18.0
		entrada.tween_property(fila, "position", destino, 0.18 + i * 0.03).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
