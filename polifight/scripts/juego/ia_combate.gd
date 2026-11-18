extends RefCounted
## Decide entradas locales. La máquina de estados conserva las reglas del combate.

const PERFILES := [
	{"reaccion": 0.65, "ataque": 0.45, "defensa": 0.15, "salto": 0.04, "retroceso": 0.08, "descanso": 0.75},
	{"reaccion": 0.30, "ataque": 0.75, "defensa": 0.50, "salto": 0.07, "retroceso": 0.12, "descanso": 0.35},
	{"reaccion": 0.13, "ataque": 0.95, "defensa": 0.82, "salto": 0.10, "retroceso": 0.16, "descanso": 0.12},
]

var perfil: Dictionary
var acciones: Array[StringName] = []
var recien_presionadas: Array[StringName] = []
var espera: float = 0.0
var descanso_ataque: float = 0.0
var descanso_salto: float = 2.0
var descanso_retroceso: float = 0.0
var movimiento_restante: float = 0.0
var azar := RandomNumberGenerator.new()


func _init(dificultad: int = 1) -> void:
	perfil = PERFILES[clampi(dificultad, 0, 2)]
	espera = perfil.reaccion
	azar.randomize()


func actualizar(personaje: Personaje, delta: float) -> void:
	recien_presionadas.clear()
	var rival := personaje.oponente
	if personaje.vida_actual <= 0 or not is_instance_valid(rival) or rival.vida_actual <= 0:
		acciones.clear()
		return
	espera -= delta
	descanso_ataque = maxf(0.0, descanso_ataque - delta)
	descanso_salto = maxf(0.0, descanso_salto - delta)
	descanso_retroceso = maxf(0.0, descanso_retroceso - delta)
	movimiento_restante = maxf(0.0, movimiento_restante - delta)
	var estados := personaje.maquina_estados
	if estados.es_estado_actual(&"Saltar"):
		# Mantener el impulso horizontal hasta aterrizar, sin repetir el salto.
		acciones.erase(personaje.accion("salto"))
		return
	if not (estados.es_estado_actual(&"Idle") or estados.es_estado_actual(&"Caminar") or estados.es_estado_actual(&"Bloqueando")):
		acciones.clear()
		return
	var distancia := absf(rival.global_position.x - personaje.global_position.x)
	var hacia := "derecha" if rival.global_position.x > personaje.global_position.x else "izquierda"
	var lejos := "izquierda" if hacia == "derecha" else "derecha"
	# Avances y retrocesos cortos: no seguir corriendo hasta la próxima decisión.
	if movimiento_restante <= 0.0 or (distancia <= 355.0 and acciones.has(personaje.accion(hacia))) or (distancia >= 560.0 and acciones.has(personaje.accion(lejos))):
		acciones.erase(personaje.accion("izquierda"))
		acciones.erase(personaje.accion("derecha"))
	var rival_ataca := rival.maquina_estados.es_estado_actual(&"Puño") or rival.maquina_estados.es_estado_actual(&"Patada")
	var caminando := acciones.has(personaje.accion("izquierda")) or acciones.has(personaje.accion("derecha"))
	# Completar cada paso corto, salvo que un ataque rival requiera reaccionar.
	if espera > 0.0 or (movimiento_restante > 0.0 and caminando and not rival_ataca):
		return
	espera = float(perfil.reaccion) * azar.randf_range(0.85, 1.15)
	acciones.clear()
	if distancia < 460.0 and rival_ataca and personaje.puede_bloquear() and azar.randf() < float(perfil.defensa):
		_presionar(personaje, "bloqueo")
	# A distancia de golpe, aprovechar la apertura antes de decidir moverse.
	elif distancia >= 380.0 and distancia <= 1000.0 and personaje.has_method("puede_usar_ulti") and personaje.call("puede_usar_ulti"):
		_presionar(personaje, "ulti")
	elif distancia <= 355.0 and personaje.is_on_floor() and personaje.puede_atacar() and descanso_ataque <= 0.0 and azar.randf() < float(perfil.ataque):
		_presionar(personaje, "patada" if distancia > 325.0 or azar.randf() < 0.4 else "ataque")
		descanso_ataque = float(perfil.descanso)
	elif distancia < 450.0 and descanso_retroceso <= 0.0 and (rival_ataca or not personaje.puede_bloquear()) and azar.randf() < 0.35:
		_esquivar(personaje, lejos)
	elif distancia < 650.0 and descanso_salto <= 0.0 and azar.randf() < float(perfil.salto):
		_saltar(personaje, lejos if distancia < 420.0 else hacia)
	elif distancia < 420.0 and descanso_retroceso <= 0.0 and azar.randf() < float(perfil.retroceso):
		_retroceder(personaje, lejos)
	elif distancia > 355.0:
		if azar.randf() > 0.15:
			_mover(personaje, hacia)



func _esquivar(personaje: Personaje, lejos: String) -> void:
	if descanso_salto <= 0.0 and azar.randf() < float(perfil.salto):
		_saltar(personaje, lejos)
	else:
		_retroceder(personaje, lejos)


func _retroceder(personaje: Personaje, lejos: String) -> void:
	var direccion := -1.0 if lejos == "izquierda" else 1.0
	# Evitar insistir contra la pared; puede saltar en el sitio si está acorralada.
	if personaje.test_move(personaje.global_transform, Vector2(direccion * 80.0, 0)):
		if descanso_salto <= 0.0:
			_saltar(personaje, "")
		return
	_mover(personaje, lejos)
	movimiento_restante = azar.randf_range(0.18, 0.30)
	descanso_retroceso = azar.randf_range(1.5, 2.5)


func _saltar(personaje: Personaje, direccion: String) -> void:
	if not personaje.is_on_floor():
		return
	_presionar(personaje, "salto")
	if not direccion.is_empty():
		_mover(personaje, direccion)
	descanso_salto = azar.randf_range(4.0, 6.0)


func _mover(personaje: Personaje, direccion: String) -> void:
	_presionar(personaje, direccion)
	movimiento_restante = azar.randf_range(0.25, 0.50)


func _presionar(personaje: Personaje, nombre: String) -> void:
	var accion := personaje.accion(nombre)
	acciones.append(accion)
	recien_presionadas.append(accion)
