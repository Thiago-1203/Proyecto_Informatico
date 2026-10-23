extends Control

@onready var seleccion: EstadoSeleccionPartida = get_node("/root/SeleccionPartida")
## Flujo compartido por teclado, mando y mouse. Las tarjetas salen del catálogo.

signal aparicion_finalizada
signal volver_solicitado
signal combate_solicitado(escena: String)

const OSCURIDAD_PUERTA: Texture2D = preload("res://cinematica_polifight/entrada_colegio/oscuro.png")
const TEXTO = preload("res://scripts/ui/texto_pixel.gd")
const VISTA = preload("res://scripts/menu/vista_previa_personaje.gd")
const BOTON = preload("res://scripts/menu/boton_pixel.gd")
const AZUL := Color("52b8ff")
const DORADO := Color("ffb80d")
const BLANCO := Color("fff2d5")
const RESOLUCION := Vector2(1920, 1080)
const COLUMNAS_PERSONAJES := 4
const POSICIONES_VISTAS := [Vector2(100, 244), Vector2(1390, 244)]
enum Paso { PERSONAJES, ESCENARIO }
enum Foco { TARJETAS, LISTO, CONTINUAR, VOLVER }

var paso: Paso = Paso.PERSONAJES
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
	add_child(lienzo)
	resized.connect(_ajustar_escala)
	_ajustar_escala()
	_crear_marco()
	for i in 2:
		var vista := VISTA.new()
		vista.position = POSICIONES_VISTAS[i]
		vista.size = Vector2(430, 335)
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
		var direccion := Vector2i.ZERO
		if j in Input.get_connected_joypads():
			direccion.x = int(Input.is_joy_button_pressed(j, JOY_BUTTON_DPAD_RIGHT)) - int(Input.is_joy_button_pressed(j, JOY_BUTTON_DPAD_LEFT))
			direccion.y = int(Input.is_joy_button_pressed(j, JOY_BUTTON_DPAD_DOWN)) - int(Input.is_joy_button_pressed(j, JOY_BUTTON_DPAD_UP))
			var eje := Vector2(Input.get_joy_axis(j, JOY_AXIS_LEFT_X), Input.get_joy_axis(j, JOY_AXIS_LEFT_Y))
			if eje.length() > 0.6:
				direccion = Vector2i(signf(eje.x), 0) if absf(eje.x) > absf(eje.y) else Vector2i(0, signf(eje.y))
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
	elif event is InputEventJoypadButton and event.pressed and event.device in [0, 1]:
		get_viewport().set_input_as_handled()
		if event.button_index == JOY_BUTTON_A:
			_activar(event.device)
		elif event.button_index == JOY_BUTTON_B:
			_volver()


func _navegar(jugador: int, direccion: Vector2i) -> void:
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
	_elegir(indice, 0)


func _tarjeta_mouse(event: InputEvent, indice: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_elegir(indice, 1)
		get_viewport().set_input_as_handled()


func _activar(jugador: int) -> void:
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
	_boton_volver = _boton("VOLVER", Rect2(65, 970, 420, 62), _volver, 3)
	_texto("J1: WASD + F    J2: FLECHAS + ENTER    ESC: VOLVER", Rect2(500, 1045, 920, 22), 2, BLANCO)
	_mensaje = _texto("", Rect2(565, 1010, 790, 28), 2, DORADO)
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
	botones_listo.clear()
	boton_continuar = null
	_mensaje.texto = ""
	_boton_volver.foco_jugadores = _mascara_foco(Foco.VOLVER)
	_boton_volver.texto = "CAMBIAR LUCHADORES" if paso == Paso.ESCENARIO else "VOLVER"
	_boton_volver.queue_redraw()
	fondo_escenario.texture = OSCURIDAD_PUERTA if paso == Paso.PERSONAJES else seleccion.escenario.imagen
	fondo_escenario.modulate = Color.WHITE
	sombra_fondo.visible = paso == Paso.ESCENARIO
	if seleccion.personajes.is_empty() or seleccion.escenarios.is_empty():
		_texto("NO HAY CONTENIDO DISPONIBLE", Rect2(490, 450, 940, 80), 5, DORADO)
		return
	for j in 2:
		vistas[j].visible = paso == Paso.PERSONAJES and indices[j] < seleccion.personajes.size()
		if vistas[j].visible:
			vistas[j].configurar(seleccion.jugadores[j], j == 1)
	if paso == Paso.ESCENARIO:
		_renderizar_escenarios()
	else:
		_renderizar_personajes()


func _renderizar_personajes() -> void:
	# El panel central alberga el título y una cuadrícula compacta que puede crecer.
	_panel(Rect2(610, 100, 700, 820), Color("041020"), Color("235285"))
	_texto("ELIGE TU LUCHADOR", Rect2(640, 145, 640, 58), 5, BLANCO)
	_panel(Rect2(640, 220, 640, 2), Color("235285"), Color.TRANSPARENT)
	var maximos := {"danio": 1.0, "stamina": 1.0}
	for personaje in seleccion.personajes:
		var stats := personaje.obtener_estadisticas()
		for clave in maximos:
			maximos[clave] = maxf(maximos[clave], stats.get(clave, 0.0))
	for i in 2:
		var ficha := seleccion.jugadores[i]
		var x := 70.0 if i == 0 else 1360.0
		var color := AZUL if i == 0 else DORADO
		var listo := listos[i]
		var vacio := indices[i] >= seleccion.personajes.size()
		# Una sola card agrupa estado, personaje animado, nombre y atributos.
		_panel(Rect2(x, 145, 490, 775), Color("061020"), color.darkened(0.55))
		_panel(Rect2(x, 145, 490, 5), color, Color.TRANSPARENT)
		_texto("J%d / %s" % [i + 1, "LISTO" if listo else "ELIGIENDO"], Rect2(x + 30, 177, 430, 30), 3, color).alineacion_horizontal = 0
		_panel(Rect2(x + 20, 232, 450, 360), Color("020711"), Color("142439"))
		_texto("PROXIMAMENTE" if vacio else ficha.nombre, Rect2(x + 30, 614, 430, 42), 5, BLANCO).alineacion_horizontal = 0
		_texto("CASILLA VACIA" if vacio else ficha.subtitulo, Rect2(x + 30, 673, 430, 20), 2, color).alineacion_horizontal = 0
		estadisticas_visibles[i] = {} if vacio else ficha.obtener_estadisticas()
		_barra_stat("DANIO DE ATAQUE", "danio", estadisticas_visibles[i], maximos["danio"], Vector2(x + 30, 718), i, color)
		_barra_stat("STAMINA", "stamina", estadisticas_visibles[i], maximos["stamina"], Vector2(x + 30, 784), i, color)
		var listo_boton := _boton("CAMBIAR J%d" % (i + 1) if listo else "LISTO J%d" % (i + 1), Rect2(x + 30, 852, 430, 46), _alternar_listo.bind(i), 3)
		listo_boton.foco_jugadores = (1 << i) if focos[i] == Foco.LISTO else 0
		botones_listo.append(listo_boton)
	_crear_grilla(Rect2(640, 250, 640, 630), COLUMNAS_PERSONAJES, seleccion.personajes)
	boton_continuar = _boton("ELEGIR ESCENARIO", Rect2(610, 945, 700, 62), _ir_escenarios, 4)
	boton_continuar.foco_jugadores = _mascara_foco(Foco.CONTINUAR)
	boton_continuar.disabled = not (listos[0] and listos[1])
	boton_continuar.modulate.a = 1.0 if not boton_continuar.disabled else 0.4


func _barra_stat(etiqueta: String, clave: String, stats: Dictionary, maximo: float, origen: Vector2, jugador: int, color: Color) -> void:
	_texto(etiqueta, Rect2(origen, Vector2(310, 20)), 2, color).alineacion_horizontal = 0
	var numero := _texto("-" if stats.is_empty() else _formatear_stat(stats[clave]), Rect2(origen + Vector2(330, 0), Vector2(100, 20)), 2, BLANCO)
	numero.alineacion_horizontal = 2
	numero.name = ("DanioJ" if clave == "danio" else "StaminaJ") + str(jugador + 1)
	var barra := ProgressBar.new()
	barra.name = ("BarraDanioJ" if clave == "danio" else "BarraStaminaJ") + str(jugador + 1)
	barra.position = origen + Vector2(0, 30)
	barra.size = Vector2(430, 14)
	barra.max_value = maximo
	barra.value = stats.get(clave, 0.0)
	barra.show_percentage = false
	barra.mouse_filter = Control.MOUSE_FILTER_PASS
	barra.tooltip_text = "Escala respecto del mayor valor del catálogo de personajes."
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color("020711")
	fondo.border_color = Color("235285")
	fondo.set_border_width_all(1)
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = color
	barra.add_theme_stylebox_override("background", fondo)
	barra.add_theme_stylebox_override("fill", relleno)
	contenido.add_child(barra)


func _renderizar_escenarios() -> void:
	var ficha := seleccion.escenario
	_texto("ELIGE DONDE PELEAR", Rect2(80, 205, 1080, 58), 5, AZUL).alineacion_horizontal = 0
	_texto("PROXIMAMENTE" if indice_escenario >= seleccion.escenarios.size() else ficha.nombre, Rect2(80, 300, 1440, 100), 11, BLANCO).alineacion_horizontal = 0
	_panel(Rect2(80, 430, 110, 6), DORADO, Color.TRANSPARENT)
	_texto(ficha.subtitulo + " / " + ficha.descripcion, Rect2(80, 466, 1200, 32), 3, BLANCO).alineacion_horizontal = 0
	# El escenario seleccionado se muestra a pantalla completa, detrás de la interfaz.
	_panel(Rect2(80, 615, 700, 64), Color("041020dc"), Color.TRANSPARENT)
	_texto(seleccion.jugadores[0].nombre + "  VS  " + seleccion.jugadores[1].nombre, Rect2(100, 634, 660, 28), 3, BLANCO)
	_texto("ESCENARIOS", Rect2(80, 725, 700, 28), 3, DORADO).alineacion_horizontal = 0
	_crear_grilla(Rect2(80, 775, 1760, 160), 6, seleccion.escenarios)
	var confirmar := _boton("INICIAR COMBATE", Rect2(1370, 970, 470, 62), _iniciar, 3)
	boton_continuar = confirmar
	confirmar.foco_jugadores = _mascara_foco(Foco.CONTINUAR)
	confirmar.disabled = indice_escenario >= seleccion.escenarios.size()
	confirmar.modulate.a = 0.4 if confirmar.disabled else 1.0
	confirmar.color_normal = DORADO
	confirmar.color_borde = DORADO


func _formatear_stat(valor: float) -> String:
	return str(int(valor)) if is_equal_approx(valor, roundf(valor)) else "%.1f" % valor


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
		tarjeta.custom_minimum_size = Vector2((rect.size.x - 24 - 16 * (columnas - 1)) / columnas, 150 if paso == Paso.ESCENARIO else 154)
		tarjeta.focus_mode = Control.FOCUS_NONE
		tarjeta.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tarjeta.tooltip_text = "CASILLA VACIA / PROXIMAMENTE" if vacia else fichas[i].nombre
		var mascara := 0
		for j in 2:
			if focos[j] == Foco.TARJETAS and i == (indice_escenario if paso == Paso.ESCENARIO else indices[j]):
				mascara |= 1 << j
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color("173a56ee") if mascara else Color("041020dc")
		estilo.border_color = (AZUL if mascara == 1 else DORADO) if mascara else Color("235285")
		estilo.set_border_width_all(3 if mascara else 1)
		tarjeta.add_theme_stylebox_override("normal", estilo)
		var hover := estilo.duplicate() as StyleBoxFlat
		hover.border_color = BLANCO
		tarjeta.add_theme_stylebox_override("hover", hover)
		tarjeta.add_theme_stylebox_override("pressed", hover)
		grilla.add_child(tarjeta)
		tarjetas.append(tarjeta)
		tarjeta.pressed.connect(_elegir_mouse.bind(i))
		tarjeta.gui_input.connect(_tarjeta_mouse.bind(i))
		var ancho := tarjeta.custom_minimum_size.x
		if vacia:
			_texto("-", Rect2(6, 40, ancho - 12, 60), 6, AZUL, tarjeta)
			_texto("PRONTO" if paso == Paso.PERSONAJES else "PROXIMAMENTE", Rect2(6, tarjeta.custom_minimum_size.y - 40, ancho - 12, 28), 2, AZUL, tarjeta)
		else:
			# El retrato de la cuadrícula es estático; el idle queda en las vistas laterales.
			_imagen(fichas[i].imagen, Rect2(12, 30, ancho - 24, tarjeta.custom_minimum_size.y - 88), false, tarjeta)
			_texto(fichas[i].nombre, Rect2(6, tarjeta.custom_minimum_size.y - 40, ancho - 12, 28), 2, BLANCO, tarjeta)
		for j in 2:
			if i == (indice_escenario if paso == Paso.ESCENARIO else indices[j]):
				_texto("J%d" % (j + 1), Rect2(8 + j * (ancho * 0.5), 8, ancho * 0.5 - 16, 18), 2, AZUL if j == 0 else DORADO, tarjeta)


func _panel(rect: Rect2, fondo: Color, borde: Color) -> void:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(3)
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
	boton.position = rect.position
	boton.size = rect.size
	boton.focus_mode = Control.FOCUS_NONE
	boton.pressed.connect(accion)
	contenido.add_child(boton)
	return boton
