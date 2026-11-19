extends RefCounted
## Compañero de práctica: espera; sólo se acerca y golpea en la lección de defensa.
var acciones: Array[StringName] = []
var recien_presionadas: Array[StringName] = []
var atacar := false
var espera := 1.8

func actualizar(personaje: Personaje, delta: float) -> void:
	acciones.clear()
	recien_presionadas.clear()
	if not atacar:
		return
	if not personaje.maquina_estados.es_estado_actual(&"Idle") and not personaje.maquina_estados.es_estado_actual(&"Caminar"):
		return
	var distancia := personaje.oponente.position.x - personaje.position.x
	if absf(distancia) > 310.0:
		acciones.append(personaje.accion("derecha" if distancia > 0 else "izquierda"))
		return
	espera -= delta
	if espera <= 0.0 and personaje.puede_atacar():
		var accion := personaje.accion("ataque")
		acciones.append(accion)
		recien_presionadas.append(accion)
		espera = 2.6
