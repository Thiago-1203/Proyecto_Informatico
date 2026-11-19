extends Node2D
## Dojo sin KO ni reloj: una consigna, sus dos controles y práctica real.
const TEXTO = preload("res://scripts/ui/texto_arcade.gd")
const BOTON = preload("res://scripts/menu/boton_arcade.gd")
const RIVAL = preload("res://scripts/juego/rival_tutorial.gd")
const GUIA = preload("res://scripts/ui/guia_controles.gd")
const AZUL := Color("52b8ff")
const ORO := Color("ffb80d")
const BLANCO := Color("fff0b5")
const VERDE := Color("7fe0ac")
const GRIS := Color("a6b8ca")
const RESOLUCION := Vector2(1920, 1080)
const LECCIONES := [
	{"titulo": "UN PASO A LA VEZ", "objetivo": "Camina un poco hacia cada lado.", "teclado": "A  /  D", "mando": "STICK / CRUCETA: IZQ. Y DER.", "pista": "Tu luchador siempre mira hacia el rival."},
	{"titulo": "TOMA ALTURA", "objetivo": "Salta una vez y vuelve al suelo.", "teclado": "W", "mando": "A / CRUZ  O  DIRECCION ARRIBA", "pista": "Combina salto y direccion para avanzar por el aire."},
	{"titulo": "BAJA EL PERFIL", "objetivo": "Mantente agachado un instante.", "teclado": "S", "mando": "STICK / CRUCETA: ABAJO", "pista": "Tambien puedes moverte mientras te agachas."},
	{"titulo": "ROMPE EL HIELO", "objetivo": "Acercate y conecta un puño a Marco.", "teclado": "J", "mando": "X / CUADRADO  -  IZQUIERDO", "pista": "Los golpes necesitan alcance. Acercate si no llegas."},
	{"titulo": "DALE ESPACIO", "objetivo": "Conecta una patada a Marco.", "teclado": "K", "mando": "B / CIRCULO  -  DERECHO", "pista": "La patada empuja mas. Deja terminar cada ataque."},
	{"titulo": "PLANTA LA GUARDIA", "objetivo": "Manten el bloqueo y detene un golpe.", "teclado": "H  (MANTENER)", "mando": "LB / L1  O  LT / L2", "pista": "Marco golpeara despacio. Cada bloqueo gasta stamina."},
	{"titulo": "RECUPERA EL AIRE", "objetivo": "Suelta el bloqueo y recupera toda tu stamina.", "teclado": "SOLTAR H", "mando": "SOLTAR EL BOTON DE BLOQUEO", "pista": "Si agotas la barra, la defensa tarda mas en volver."},
	{"titulo": "GUARDA LO MEJOR", "objetivo": "Conecta golpes hasta llenar la barra de ulti.", "teclado": "J  /  K", "mando": "X / CUADRADO  O  B / CIRCULO", "pista": "La ulti se carga al acertar golpes, no al fallarlos."},
]

var raiz: Node2D
var fondo_raiz: Node2D
var camara: Camera2D
var mundo: Node2D
var lienzo: Control
var jugador: Personaje
var rival: Personaje
var cerebro: RefCounted
var paso := 0
var completado := false
var finalizado := false
var pausado := false
var mostrando_controles := false
var _saliendo := false
var _listo := false
var _posicion_anterior := Vector2.ZERO
var _recorrido := Vector2.ZERO
var _agachado := 0.0
var _salto_iniciado := false
var _ulti_iniciada := false
var _ulti_lista := false
var titulo: Control
var objetivo: Control
var pista: Control
var texto_teclado: Control
var texto_mando: Control
var progreso: Control
var segmentos: Array[ColorRect] = []
var boton_siguiente: Button
var boton_pausa: Button
var estado_stamina: Control
var estado_ulti: Control
var barra_stamina: ProgressBar
var barra_ulti: ProgressBar
var modal: Control
var _contenido_modal: Control
var guia_controles: Control

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var capa_fondo := CanvasLayer.new()
	capa_fondo.layer = -1
	add_child(capa_fondo)
	var base := ColorRect.new()
	base.color = Color("050915")
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_fondo.add_child(base)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo_raiz = Node2D.new()
	capa_fondo.add_child(fondo_raiz)
	var capa_ui := CanvasLayer.new()
	capa_ui.layer = 10
	add_child(capa_ui)
	raiz = Node2D.new()
	capa_ui.add_child(raiz)
	_crear_escenario()
	_crear_luchadores()
	_crear_interfaz()
	get_viewport().size_changed.connect(_ajustar_escala)
	_ajustar_escala()
	await get_tree().process_frame
	await get_tree().physics_frame
	_iniciar_paso(0)
	_listo = true

func _ajustar_escala() -> void:
	var disponible := get_viewport_rect().size
	var factor := minf(disponible.x / RESOLUCION.x, disponible.y / RESOLUCION.y)
	raiz.scale = Vector2.ONE * factor
	raiz.position = (disponible - RESOLUCION * factor) * 0.5
	fondo_raiz.scale = raiz.scale
	fondo_raiz.position = raiz.position
	camara.zoom = Vector2.ONE * factor * 0.65

func _crear_escenario() -> void:
	var fondo := TextureRect.new()
	fondo.texture = preload("res://assets/ui/fondos/Fondo1.png")
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.size = RESOLUCION
	fondo.modulate = Color("657087")
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo_raiz.add_child(fondo)
	var velo := ColorRect.new()
	velo.size = RESOLUCION
	velo.color = Color("080f20a0")
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo_raiz.add_child(velo)
	mundo = Node2D.new()
	mundo.name = "Practica"
	add_child(mundo)
	# La cámara reduce la imagen sin cambiar velocidades, gravedad ni colisiones.
	camara = Camera2D.new()
	camara.position = Vector2(1300, 523.0769)
	mundo.add_child(camara)
	_cuerpo(Rect2(-400, 980, 3400, 40))
	_cuerpo(Rect2(-90, -700, 40, 1700))
	_cuerpo(Rect2(2650, -700, 40, 1700))
	var suelo := Line2D.new()
	suelo.points = PackedVector2Array([Vector2(0, 980), Vector2(2600, 980)])
	suelo.width = 3
	suelo.default_color = Color("91a5ba")
	mundo.add_child(suelo)

func _cuerpo(rect: Rect2) -> void:
	var cuerpo := StaticBody2D.new()
	cuerpo.position = rect.get_center()
	var colision := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = rect.size
	colision.shape = forma
	cuerpo.add_child(colision)
	mundo.add_child(cuerpo)

func _crear_luchadores() -> void:
	jugador = preload("res://escenas/personajes/barbieri.tscn").instantiate()
	jugador.name = "Aprendiz"
	jugador.numero_jugador = 1
	jugador.position = Vector2(1140, 780)
	mundo.add_child(jugador)
	rival = preload("res://escenas/personajes/marco.tscn").instantiate()
	rival.name = "Compañero"
	rival.numero_jugador = 2
	rival.direccion_inicial = -1
	rival.controlado_por_ia = true
	rival.position = Vector2(1450, 780)
	mundo.add_child(rival)
	for personaje in [jugador, rival]:
		personaje.get_node("IndicadorJugador").hide()
		var nombre := TEXTO.new()
		nombre.texto = "TU" if personaje == jugador else "MARCO"
		nombre.color = AZUL if personaje == jugador else GRIS
		nombre.tamano_pixel = 5
		nombre.position = Vector2(-120, -295)
		nombre.size = Vector2(240, 40)
		nombre.desplazamiento_sombra = Vector2(2, 2)
		personaje.add_child(nombre)
	cerebro = RIVAL.new()
	rival.controlador_ia = cerebro
	# Los ataques de práctica conservan su reacción, sin quitar vida al aprendiz.
	rival.hitbox.configurar(rival, 0)
	jugador.configurar_oponente(rival)
	rival.configurar_oponente(jugador)
	jugador.hitbox.impacto_con_danio.connect(_golpe_acertado)
	jugador.stamina_cambiada.connect(_stamina_cambiada)
	jugador.ulti_cambiada.connect(_ulti_cambiada)

func _crear_interfaz() -> void:
	lienzo = Control.new()
	lienzo.size = RESOLUCION
	lienzo.z_index = 100
	lienzo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.focus_mode = Control.FOCUS_ALL
	raiz.add_child(lienzo)
	_texto("POLIFIGHT / DOJO", Rect2(100, 48, 900, 42), 5, BLANCO)
	_texto("SIN RELOJ. SIN KO. A TU RITMO.", Rect2(100, 98, 1100, 28), 3, GRIS)
	boton_pausa = _boton("PAUSA / CONTROLES", Rect2(1360, 54, 460, 56), _alternar_pausa)
	_panel(Rect2(100, 145, 1720, 155), Color("0d172c"), Color("344465"))
	progreso = _texto("", Rect2(130, 162, 500, 26), 3, AZUL)
	titulo = _texto("", Rect2(130, 200, 1280, 47), 6, BLANCO)
	objetivo = _texto("", Rect2(130, 262, 1320, 30), 4, BLANCO)
	boton_siguiente = _boton("", Rect2(1450, 232, 340, 54), _siguiente)
	for i in LECCIONES.size():
		var segmento := ColorRect.new()
		segmento.position = Vector2(1450 + i * 43, 168)
		segmento.size = Vector2(35, 8)
		segmento.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lienzo.add_child(segmento)
		segmentos.append(segmento)
	_texto("TU STAMINA", Rect2(130, 365, 320, 27), 3, AZUL)
	barra_stamina = _barra(Rect2(130, 404, 290, 14), AZUL)
	estado_stamina = _texto("", Rect2(130, 439, 320, 30), 4, BLANCO)
	_texto("TU ULTI", Rect2(1470, 365, 320, 27), 3, ORO)
	barra_ulti = _barra(Rect2(1470, 404, 290, 14), ORO)
	estado_ulti = _texto("", Rect2(1470, 439, 320, 30), 4, BLANCO)
	_panel(Rect2(100, 864, 835, 116), Color("0d172cf5"), Color("344465"))
	_panel(Rect2(955, 864, 865, 116), Color("0d172cf5"), Color("344465"))
	_texto("TECLADO / J1", Rect2(130, 879, 770, 24), 3, GRIS)
	_texto("MANDO / XBOX - PLAYSTATION", Rect2(985, 879, 800, 24), 3, GRIS)
	texto_teclado = _texto("", Rect2(130, 921, 770, 35), 4, AZUL)
	texto_mando = _texto("", Rect2(985, 921, 800, 35), 4, ORO)
	pista = _texto("", Rect2(100, 1002, 1720, 30), 3, BLANCO)
	_texto("ENTER / RB / R1: SEGUIR    ESC / START: PAUSA Y CONTROLES", Rect2(100, 1040, 1720, 30), 3, GRIS)
	modal = Control.new()
	modal.size = RESOLUCION
	lienzo.add_child(modal)
	var sombra := ColorRect.new()
	sombra.size = RESOLUCION
	sombra.color = Color("030715ed")
	modal.add_child(sombra)
	_contenido_modal = Control.new()
	_contenido_modal.size = RESOLUCION
	modal.add_child(_contenido_modal)
	guia_controles = GUIA.new()
	modal.add_child(guia_controles)
	guia_controles.volver_solicitado.connect(_mostrar_pausa)
	modal.hide()
	_stamina_cambiada(jugador.stamina_actual, jugador.stamina_maxima)
	_ulti_cambiada(jugador.carga_ulti)
	lienzo.grab_focus()

func _iniciar_paso(indice: int) -> void:
	for child in get_children():
		if child is Node2D and child != mundo:
			child.queue_free()
	paso = indice
	completado = false
	_recorrido = Vector2.ZERO
	_agachado = 0.0
	_salto_iniciado = false
	_ulti_iniciada = false
	_ulti_lista = false
	for personaje in [jugador, rival]:
		personaje.maquina_estados.cambiar_a("Idle")
		personaje.velocity = Vector2.ZERO
		personaje.cooldown_ataque_restante = 0.0
	jugador.position = Vector2(1140, 780)
	rival.position = Vector2(1450, 780)
	_posicion_anterior = jugador.position
	cerebro.atacar = paso == 5
	cerebro.espera = 1.8
	if paso == 6:
		# También se puede llegar aquí omitiendo defensa: siempre habrá algo que recuperar.
		jugador._cambiar_stamina(minf(jugador.stamina_actual, jugador.stamina_maxima - 25.0))
	elif paso != 5:
		jugador._cambiar_stamina(jugador.stamina_maxima)
	if paso == 7:
		jugador.carga_ulti = 0.0
		jugador.ulti_cambiada.emit(0.0)
	_actualizar_leccion()

func _actualizar_leccion() -> void:
	var leccion: Dictionary = LECCIONES[paso]
	progreso.texto = "PASO %02d / %02d" % [paso + 1, LECCIONES.size()]
	titulo.texto = "BIEN HECHO!" if completado else leccion["titulo"]
	titulo.color = VERDE if completado else BLANCO
	objetivo.texto = "Puedes practicar un poco mas o seguir al proximo paso." if completado else leccion["objetivo"]
	texto_teclado.texto = leccion["teclado"]
	texto_mando.texto = leccion["mando"]
	pista.texto = leccion["pista"]
	boton_siguiente.texto = "SEGUIR >" if completado else "OMITIR >"
	boton_siguiente.color_normal = VERDE if completado else GRIS
	boton_siguiente.queue_redraw()
	for i in segmentos.size():
		segmentos[i].color = VERDE if i < paso or (i == paso and completado) else (AZUL if i == paso else Color("344465"))
	if paso == 7 and _ulti_lista:
		texto_teclado.texto = "L"
		texto_mando.texto = "Y / TRIANGULO  -  SUPERIOR"
		if not completado:
			titulo.texto = "AHORA, LA ULTI!"
			objetivo.texto = "Barra llena: desata tu ataque especial."
		pista.texto = "En combate, vuelve a cargarla acertando nuevos golpes."

func _physics_process(delta: float) -> void:
	if not _listo or pausado or _saliendo:
		return
	# Mantener las vidas fuera del circuito de KO, sin alterar el combate normal.
	rival.vida_actual = rival.vida_maxima
	jugador.vida_actual = jugador.vida_maxima
	if finalizado or completado:
		return
	var desplazamiento := jugador.position.x - _posicion_anterior.x
	_posicion_anterior = jugador.position
	var estados := jugador.maquina_estados
	match paso:
		0:
			var anterior := _recorrido
			if estados.es_estado_actual(&"Caminar"):
				if desplazamiento < 0.0:
					_recorrido.x -= desplazamiento
				else:
					_recorrido.y += desplazamiento
			if _recorrido.x >= 75.0 and _recorrido.y >= 75.0:
				_completar()
			elif _recorrido.x >= 75.0 and anterior.x < 75.0:
				objetivo.texto = "Bien. Ahora camina hacia la derecha."
			elif _recorrido.y >= 75.0 and anterior.y < 75.0:
				objetivo.texto = "Bien. Ahora camina hacia la izquierda."
		1:
			if estados.es_estado_actual(&"Saltar"):
				_salto_iniciado = true
			if _salto_iniciado and jugador.is_on_floor() and not estados.es_estado_actual(&"Saltar"):
				_completar()
		2:
			if estados.es_estado_actual(&"Agacharse") or estados.es_estado_actual(&"CaminarAgachado"):
				_agachado += delta
			else:
				_agachado = 0.0
			if _agachado >= 0.5:
				_completar()
		7:
			if estados.es_estado_actual(&"Ulti"):
				_ulti_iniciada = true
			if _ulti_iniciada and not estados.es_estado_actual(&"Ulti"):
				_completar()

func _golpe_acertado(objetivo_golpe: Personaje) -> void:
	# Se restaura después de contabilizar el impacto para conservar la carga real de ulti.
	objetivo_golpe.vida_actual = objetivo_golpe.vida_maxima
	if not _listo or finalizado or completado:
		return
	if (paso == 3 and jugador.maquina_estados.es_estado_actual(&"Puño")) or (paso == 4 and jugador.maquina_estados.es_estado_actual(&"Patada")):
		_completar()

func _stamina_cambiada(actual: float, maxima: float) -> void:
	if not is_instance_valid(barra_stamina):
		return
	barra_stamina.value = actual / maxima * 100.0
	estado_stamina.texto = "%d / %d" % [roundi(actual), roundi(maxima)]
	if _listo and not completado and not finalizado:
		if paso == 5 and jugador.maquina_estados.es_estado_actual(&"Bloqueando") and actual < maxima:
			_completar()
		elif paso == 6 and actual >= maxima:
			_completar()

func _ulti_cambiada(carga: float) -> void:
	if not is_instance_valid(barra_ulti):
		return
	barra_ulti.value = carga
	estado_ulti.texto = "LISTA!" if carga >= 100 else "%d / 100" % roundi(carga)
	if _listo and not finalizado and not completado and paso == 7 and carga >= 100 and not _ulti_lista:
		_ulti_lista = true
		_actualizar_leccion()

func _completar() -> void:
	completado = true
	cerebro.atacar = false
	_actualizar_leccion()
	var destello := create_tween()
	destello.tween_property(titulo, "modulate:a", 0.5, 0.07)
	destello.tween_property(titulo, "modulate:a", 1.0, 0.15)

func _siguiente() -> void:
	if not _listo or pausado or finalizado:
		return
	if paso + 1 < LECCIONES.size():
		_iniciar_paso(paso + 1)
	else:
		_finalizar()

func _finalizar() -> void:
	finalizado = true
	cerebro.atacar = false
	progreso.texto = "TUTORIAL COMPLETADO"
	titulo.texto = "YA ESTAS EN EL JUEGO!"
	titulo.color = VERDE
	objetivo.texto = "Practica libremente. Cuando quieras, proba un duelo."
	texto_teclado.texto = "W A S D  /  H J K L"
	texto_mando.texto = "STICK + BOTONES + LB / LT"
	pista.texto = "ESC / START abre la pausa y la guia completa de controles."
	boton_siguiente.texto = "IR A MODOS >"
	boton_siguiente.color_normal = VERDE
	boton_siguiente.queue_redraw()
	boton_siguiente.pressed.disconnect(_siguiente)
	boton_siguiente.pressed.connect(_salir)
	for segmento in segmentos:
		segmento.color = VERDE

func _input(event: InputEvent) -> void:
	if not _listo or _saliendo or event.is_echo():
		return
	if event is InputEventJoypadButton and event.pressed:
		get_node("/root/EntradaMandos").asignar_principal(event.device)
	elif event is InputEventJoypadMotion and absf(event.axis_value) >= 0.5:
		get_node("/root/EntradaMandos").asignar_principal(event.device)
	if event.is_action_pressed(&"pausa"):
		get_viewport().set_input_as_handled()
		if pausado and mostrando_controles:
			_mostrar_pausa()
		else:
			_alternar_pausa()
	elif pausado:
		if event.is_action_pressed(&"ui_cancel"):
			get_viewport().set_input_as_handled()
			if mostrando_controles:
				_mostrar_pausa()
			else:
				_alternar_pausa()
	elif (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ENTER) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_RIGHT_SHOULDER):
		get_viewport().set_input_as_handled()
		if finalizado:
			_salir()
		else:
			_siguiente()

func _alternar_pausa() -> void:
	if _saliendo:
		return
	pausado = not pausado
	mundo.process_mode = Node.PROCESS_MODE_DISABLED if pausado else Node.PROCESS_MODE_INHERIT
	# Las ultis agregan sus proyectiles a la escena actual, fuera de Practica.
	for child in get_children():
		if child is Node2D and child != mundo:
			child.process_mode = Node.PROCESS_MODE_DISABLED if pausado else Node.PROCESS_MODE_INHERIT
	modal.visible = pausado
	if pausado:
		lienzo.focus_mode = Control.FOCUS_NONE
		_mostrar_pausa()
	else:
		# El botón derecho al cerrar la pausa no debe convertirse en una patada.
		Input.action_release(jugador.accion("patada"))
		lienzo.focus_mode = Control.FOCUS_ALL
		lienzo.grab_focus()

func _limpiar_modal() -> void:
	for child in _contenido_modal.get_children():
		child.hide()
		child.queue_free()

func _mostrar_pausa() -> void:
	mostrando_controles = false
	guia_controles.hide()
	_contenido_modal.show()
	_limpiar_modal()
	_panel(Rect2(530, 190, 860, 700), Color("0d172c"), AZUL, _contenido_modal)
	_texto("TOMA UN RESPIRO", Rect2(580, 235, 760, 60), 6, BLANCO, _contenido_modal).alineacion_horizontal = 1
	_texto("EL DOJO TE ESPERA.", Rect2(580, 315, 760, 30), 3, GRIS, _contenido_modal).alineacion_horizontal = 1
	var opciones := [
		["SEGUIR PRACTICANDO", _alternar_pausa],
		["VER CONTROLES", _mostrar_controles],
		["EMPEZAR DE NUEVO", _reiniciar],
		["VOLVER A MODOS", _salir],
	]
	var botones: Array[Button] = []
	for i in opciones.size():
		var boton := _boton(opciones[i][0], Rect2(620, 400 + i * 100, 680, 72), opciones[i][1], _contenido_modal)
		boton.focus_mode = Control.FOCUS_ALL
		botones.append(boton)
	for i in botones.size():
		var boton := botones[i]
		boton.focus_neighbor_top = botones[posmod(i - 1, botones.size())].get_path()
		boton.focus_neighbor_bottom = botones[(i + 1) % botones.size()].get_path()
		boton.focus_neighbor_left = boton.get_path()
		boton.focus_neighbor_right = boton.get_path()
		boton.focus_previous = boton.focus_neighbor_top
		boton.focus_next = boton.focus_neighbor_bottom
	botones[0].grab_focus()
	_texto("ESC / START / B: VOLVER", Rect2(580, 820, 760, 28), 3, GRIS, _contenido_modal).alineacion_horizontal = 1

func _mostrar_controles() -> void:
	mostrando_controles = true
	_contenido_modal.hide()
	guia_controles.abrir(true)

func _reiniciar() -> void:
	finalizado = false
	if boton_siguiente.pressed.is_connected(_salir):
		boton_siguiente.pressed.disconnect(_salir)
		boton_siguiente.pressed.connect(_siguiente)
	_alternar_pausa()
	jugador.carga_ulti = 0.0
	_ulti_cambiada(0.0)
	_iniciar_paso(0)

func _salir() -> void:
	if _saliendo:
		return
	_saliendo = true
	var error := get_tree().change_scene_to_file("res://escenas/menu/selector_modos.tscn")
	if error != OK:
		_saliendo = false
		push_error("No se pudo volver a los modos: " + error_string(error))

func _texto(valor: String, rect: Rect2, pixel: int, color: Color, padre: Control = null) -> Control:
	var texto := TEXTO.new()
	texto.texto = valor
	texto.tamano_pixel = pixel
	texto.color = color
	texto.alineacion_horizontal = 0
	texto.desplazamiento_sombra = Vector2(2, 2)
	texto.position = rect.position
	texto.size = rect.size
	(padre if padre != null else lienzo).add_child(texto)
	return texto

func _panel(rect: Rect2, fondo: Color, borde: Color, padre: Control = null) -> void:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", estilo)
	(padre if padre != null else lienzo).add_child(panel)

func _boton(valor: String, rect: Rect2, accion: Callable, padre: Control = null) -> Button:
	var boton := BOTON.new()
	boton.texto = valor
	boton.tamano_pixel = 3
	boton.dibujar_marco = true
	boton.color_normal = AZUL
	boton.position = rect.position
	boton.size = rect.size
	boton.focus_mode = Control.FOCUS_NONE
	boton.pressed.connect(accion)
	(padre if padre != null else lienzo).add_child(boton)
	return boton

func _barra(rect: Rect2, color: Color) -> ProgressBar:
	var barra := ProgressBar.new()
	barra.position = rect.position
	barra.size = rect.size
	barra.show_percentage = false
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color("26344c")
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = color
	barra.add_theme_stylebox_override("background", fondo)
	barra.add_theme_stylebox_override("fill", relleno)
	lienzo.add_child(barra)
	return barra
