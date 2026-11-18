extends Node
## Godot/SDL normaliza Xbox, PlayStation, Nintendo y mandos compatibles.
## Los números de dispositivo son dinámicos; se asignan a dos puestos de jugador.
signal asignacion_cambiada
const SUFIJOS := ["izquierda", "derecha", "salto", "agacharse", "ataque", "patada", "ulti", "bloqueo"]
const ZONA_MUERTA := 0.5
var dispositivos: Array[int] = [-1, -1]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_conexion_cambiada)
	for dispositivo in Input.get_connected_joypads():
		registrar_dispositivo(dispositivo)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		registrar_dispositivo(event.device)
	elif event is InputEventJoypadMotion and absf(event.axis_value) >= ZONA_MUERTA:
		registrar_dispositivo(event.device)

func registrar_dispositivo(dispositivo: int) -> int:
	if dispositivo < 0:
		return -1
	var jugador := dispositivos.find(dispositivo)
	if jugador >= 0:
		return jugador
	jugador = dispositivos.find(-1)
	if jugador < 0:
		return -1
	dispositivos[jugador] = dispositivo
	_configurar_jugador(jugador)
	asignacion_cambiada.emit()
	return jugador

func asignar_principal(dispositivo: int) -> void:
	# El mando que abre JUGAR controla al humano, también si antes tenía ID/J2.
	var jugador := registrar_dispositivo(dispositivo)
	if jugador <= 0:
		return
	var anterior := dispositivos[0]
	dispositivos[0] = dispositivo
	dispositivos[jugador] = anterior
	for puesto in 2:
		for sufijo in SUFIJOS:
			Input.action_release(_accion(puesto, sufijo))
		_configurar_jugador(puesto)
	asignacion_cambiada.emit()

func jugador_para_dispositivo(dispositivo: int) -> int:
	return dispositivos.find(dispositivo)

func _conexion_cambiada(dispositivo: int, conectado: bool) -> void:
	if conectado:
		registrar_dispositivo(dispositivo)
		return
	var jugador := jugador_para_dispositivo(dispositivo)
	if jugador < 0:
		return
	dispositivos[jugador] = -1
	for sufijo in SUFIJOS:
		Input.action_release(_accion(jugador, sufijo))
	_configurar_jugador(jugador)
	# Si había un tercer mando esperando, ocupa el puesto libre.
	for conectado_id in Input.get_connected_joypads():
		registrar_dispositivo(conectado_id)
	asignacion_cambiada.emit()

func _accion(jugador: int, sufijo: String) -> StringName:
	return StringName("j%d_%s" % [jugador + 1, sufijo])

func _configurar_jugador(jugador: int) -> void:
	for sufijo in SUFIJOS:
		var accion := _accion(jugador, sufijo)
		for evento in InputMap.action_get_events(accion):
			if evento is InputEventJoypadButton or evento is InputEventJoypadMotion:
				InputMap.action_erase_event(accion, evento)
		InputMap.action_set_deadzone(accion, ZONA_MUERTA)
	var dispositivo := dispositivos[jugador]
	if dispositivo < 0:
		return
	_boton(jugador, "izquierda", JOY_BUTTON_DPAD_LEFT)
	_boton(jugador, "derecha", JOY_BUTTON_DPAD_RIGHT)
	_boton(jugador, "salto", JOY_BUTTON_DPAD_UP)
	_boton(jugador, "agacharse", JOY_BUTTON_DPAD_DOWN)
	_eje(jugador, "izquierda", JOY_AXIS_LEFT_X, -1.0)
	_eje(jugador, "derecha", JOY_AXIS_LEFT_X, 1.0)
	_eje(jugador, "salto", JOY_AXIS_LEFT_Y, -1.0)
	_eje(jugador, "agacharse", JOY_AXIS_LEFT_Y, 1.0)
	_boton(jugador, "salto", JOY_BUTTON_A)
	_boton(jugador, "ataque", JOY_BUTTON_X)
	_boton(jugador, "patada", JOY_BUTTON_B)
	_boton(jugador, "ulti", JOY_BUTTON_Y)
	_boton(jugador, "bloqueo", JOY_BUTTON_LEFT_SHOULDER)
	_eje(jugador, "bloqueo", JOY_AXIS_TRIGGER_LEFT, 1.0)

func _boton(jugador: int, sufijo: String, indice: JoyButton) -> void:
	var evento := InputEventJoypadButton.new()
	evento.device = dispositivos[jugador]
	evento.button_index = indice
	InputMap.action_add_event(_accion(jugador, sufijo), evento)

func _eje(jugador: int, sufijo: String, eje: JoyAxis, valor: float) -> void:
	var evento := InputEventJoypadMotion.new()
	evento.device = dispositivos[jugador]
	evento.axis = eje
	evento.axis_value = valor
	InputMap.action_add_event(_accion(jugador, sufijo), evento)

func direccion_menu(jugador: int) -> Vector2i:
	var dispositivo := dispositivos[jugador]
	if dispositivo < 0:
		return Vector2i.ZERO
	var direccion := Vector2i(
		int(Input.is_joy_button_pressed(dispositivo, JOY_BUTTON_DPAD_RIGHT)) - int(Input.is_joy_button_pressed(dispositivo, JOY_BUTTON_DPAD_LEFT)),
		int(Input.is_joy_button_pressed(dispositivo, JOY_BUTTON_DPAD_DOWN)) - int(Input.is_joy_button_pressed(dispositivo, JOY_BUTTON_DPAD_UP)))
	var eje := Vector2(Input.get_joy_axis(dispositivo, JOY_AXIS_LEFT_X), Input.get_joy_axis(dispositivo, JOY_AXIS_LEFT_Y))
	if eje.length() > ZONA_MUERTA:
		direccion = Vector2i(signf(eje.x), 0) if absf(eje.x) > absf(eje.y) else Vector2i(0, signf(eje.y))
	# Una diagonal produce un solo paso por repetición, incluso con cruceta.
	if direccion.x != 0 and direccion.y != 0:
		direccion.y = 0
	return direccion
