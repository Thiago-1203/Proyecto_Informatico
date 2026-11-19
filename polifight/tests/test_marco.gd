extends SceneTree
## Integración de Marco: selección, física, golpes reales y estados compartidos.

const NIVEL = preload("res://escenas/juego/nivelI.tscn")
const MARCO = preload("res://datos/seleccion/personajes/marco.tres")
var fallos := 0
var capturas := false
var viewport_captura: SubViewport


func _initialize() -> void:
	capturas = "--capturas" in OS.get_cmdline_user_args()
	if capturas and DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1920, 1080)
	call_deferred("_probar")


func exigir(valor: bool, mensaje: String) -> void:
	if not valor:
		fallos += 1
		push_error(mensaje)


func esperar(segundos: float) -> void:
	await create_timer(segundos, true, true).timeout


func capturar(nombre: String) -> void:
	if capturas and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		viewport_captura.get_texture().get_image().save_png("res://docs/marco/" + nombre + ".png")


func agregar_nivel(nivel: Node) -> void:
	# El monitor puede limitar la ventana a 1366 px. El viewport conserva
	# la resolución real del juego para revisar los sprites sin reducirlos.
	(viewport_captura if viewport_captura != null else root).add_child(nivel)
	if viewport_captura == null:
		current_scene = nivel


func colocar(marco: Personaje) -> void:
	marco.position.x = 800 if marco.numero_jugador == 1 else 1110
	marco.oponente.position.x = 1110 if marco.numero_jugador == 1 else 800
	marco.velocity = Vector2.ZERO
	marco.oponente.velocity = Vector2.ZERO


func probar_salto(marco: Personaje) -> void:
	var cuadros: Dictionary = {&"salto": [], &"caida": []}
	marco.maquina_estados.cambiar_a("Saltar")
	var salto: Animation = marco.animacion.get_animation(&"salto")
	var pista := salto.find_track(^"Sprite2D:texture", Animation.TYPE_VALUE)
	exigir(marco.sprite.texture == salto.track_get_key_value(pista, 0), "El despegue debe mostrar el primer cuadro inmediatamente")
	var subio := false
	for i in 180:
		await physics_frame
		subio = subio or (not marco.is_on_floor() and marco.velocity.y < 0)
		var fase: StringName = marco.animacion.assigned_animation
		if cuadros.has(fase) and marco.sprite.texture.resource_path.begins_with("res://assets/characters/Marco/" + str(fase) + "/"):
			var vistas: Array = cuadros[fase]
			if vistas.is_empty() or vistas.back() != marco.sprite.texture:
				vistas.append(marco.sprite.texture)
		if marco.is_on_floor() and i > 3:
			break
	exigir(subio and marco.is_on_floor(), "Marco debe saltar y aterrizar")
	for fase in cuadros:
		var anim: Animation = marco.animacion.get_animation(fase)
		var track := anim.find_track(^"Sprite2D:texture", Animation.TYPE_VALUE)
		var esperadas: Array = []
		for i in anim.track_get_key_count(track):
			esperadas.append(anim.track_get_key_value(track, i))
		exigir(cuadros[fase] == esperadas, str(fase) + " debe mostrar los cuatro cuadros en orden, una sola vez durante el salto real")
	await esperar(0.05)
	exigir(marco.maquina_estados.es_estado_actual(&"Idle"), "Aterrizar debe recuperar idle")


func _probar_jugador(numero: int) -> void:
	var seleccion: EstadoSeleccionPartida = root.get_node("SeleccionPartida")
	seleccion.reiniciar()
	seleccion.jugadores[numero - 1] = MARCO
	var nivel := NIVEL.instantiate()
	agregar_nivel(nivel)
	await esperar(0.4)
	var marco: Personaje = nivel.jugador1 if numero == 1 else nivel.jugador2
	var rival := marco.oponente
	exigir(marco.is_on_floor(), "Marco debe apoyar el cuerpo sobre el suelo")
	exigir(marco.maquina_estados.tiene_estado(&"Ulti") and marco.has_signal("ulti_cambiada") and is_zero_approx(marco.get("carga_ulti")), "Marco debe comenzar con la ulti descargada")
	exigir(MARCO.obtener_estadisticas() == {"danio": marco.danio, "stamina": marco.stamina_maxima}, "La ficha debe reflejar sus atributos reales")
	colocar(marco)
	await physics_frame
	await capturar("combate-j%d" % numero)
	# El retroceso reproduce el ciclo opuesto y conserva la mirada al rival.
	Input.action_press(marco.accion("izquierda" if numero == 1 else "derecha"))
	marco.maquina_estados.cambiar_a("Caminar")
	await esperar(0.08)
	exigir(marco.animacion.current_animation == &"caminar_atras", "El retroceso debe invertir los pasos")
	exigir(marco.sprite.flip_h == (numero == 2), "Marco debe mirar al rival desde ambos lados")
	Input.action_press(marco.accion("agacharse"))
	marco.maquina_estados.cambiar_a("Agacharse")
	await esperar(0.1)
	exigir(marco.maquina_estados.es_estado_actual(&"CaminarAgachado"), "La diagonal debe activar la caminata agachada")
	exigir(marco.animacion.current_animation == &"Caminar_Agachado_atras", "También debe poder retroceder agachado")
	Input.action_release(marco.accion("izquierda" if numero == 1 else "derecha"))
	await esperar(0.4)
	exigir(marco.maquina_estados.es_estado_actual(&"Agacharse"), "Soltar el paso conserva la guardia baja")
	exigir(marco.hurtbox.get_node("CollisionShape2D").shape.size.y < 392, "La guardia baja debe reducir la hurtbox")
	Input.action_release(marco.accion("agacharse"))
	await esperar(0.1)
	exigir(marco.maquina_estados.es_estado_actual(&"Idle"), "Soltar agacharse debe recuperar idle")
	exigir(marco.hurtbox.get_node("CollisionShape2D").shape.size == Vector2(246, 392), "Idle restaura la hurtbox")
	colocar(marco)
	await probar_salto(marco)
	colocar(marco)
	var forma := marco.hitbox.get_node("CollisionShape2D") as CollisionShape2D
	for ataque in ["Puño", "Patada"]:
		await esperar(marco.cooldown_ataque + 0.05)
		colocar(marco)
		var vida := rival.vida_actual
		marco.maquina_estados.cambiar_a(ataque)
		await esperar(0.06)
		exigir(forma.disabled and rival.vida_actual == vida, "La preparación de " + ataque + " no debe golpear")
		await esperar(0.17)
		exigir(rival.vida_actual == vida - marco.danio, ataque + " debe hacer daño una sola vez")
		await capturar(ataque.to_lower().replace("ñ", "n") + "-j%d" % numero)
		await esperar(0.55)
		exigir(forma.disabled and not marco.hitbox.ataque_en_curso, "El fin del ataque debe limpiar la hitbox")
		exigir(marco.maquina_estados.es_estado_actual(&"Idle"), "El ataque debe recuperar el movimiento")
	# Bloqueo y ruptura de la animación de ataque al recibir daño.
	colocar(marco)
	Input.action_press(marco.accion("bloqueo"))
	marco.maquina_estados.cambiar_a("Bloqueando")
	rival.maquina_estados.cambiar_a("Puño")
	await esperar(0.3)
	exigir(marco.vida_actual == 100 and marco.stamina_actual < marco.stamina_maxima, "Bloquear debe gastar stamina y evitar daño")
	await capturar("bloqueo-j%d" % numero)
	Input.action_release(marco.accion("bloqueo"))
	await esperar(0.8)
	colocar(marco)
	marco.maquina_estados.cambiar_a("Patada")
	await esperar(0.05)
	marco.recibir_golpe(10, rival)
	await physics_frame
	exigir(marco.maquina_estados.es_estado_actual(&"RecibirGolpe") and forma.disabled and not marco.hitbox.ataque_en_curso, "Recibir daño debe interrumpir y limpiar el ataque")
	await esperar(0.6)
	# La derrota real debe completar caída, rebote y pantalla de victoria.
	colocar(marco)
	marco.recibir_golpe(100, rival)
	await esperar(4.8)
	exigir(marco.ko_final_notificado and rival.maquina_estados.es_estado_actual(&"Victoria"), "KO debe completar el combate")
	await capturar("ko-j%d" % numero)
	nivel.free()
	await process_frame
	await process_frame
	print("MARCO J", numero, ": movimientos, ataques, defensa, interrupción y KO verificados")


func _probar() -> void:
	if capturas and DisplayServer.get_name() != "headless":
		viewport_captura = SubViewport.new()
		viewport_captura.size = Vector2i(1920, 1080)
		viewport_captura.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport_captura)
	var escena := (load(MARCO.escena) as PackedScene).instantiate()
	var player := escena.get_node("AnimationPlayer") as AnimationPlayer
	for nombre in ["idle", "caminar_adelante", "caminar_atras", "salto", "caida", "agacharse", "Caminar_Agachado", "Caminar_Agachado_atras", "puño", "patada", "bloqueo", "recibirGolpe", "KO", "victoria"]:
		exigir(player.has_animation(nombre), "Falta animación: " + nombre)
		var anim := player.get_animation(nombre)
		var pista := anim.find_track(^"Sprite2D:texture", Animation.TYPE_VALUE)
		exigir(pista >= 0 and anim.track_get_key_count(pista) == 4, "Cada movimiento debe tener cuatro cuadros")
		for i in 4:
			var textura: Texture2D = anim.track_get_key_value(pista, i)
			exigir(textura.get_size() == Vector2(512, 512), "Todos los cuadros deben medir 512x512")
	escena.free()
	for numero in [1, 2]:
		await _probar_jugador(numero)
	# Marco también debe celebrar en el mundo y en la pantalla final.
	var seleccion: EstadoSeleccionPartida = root.get_node("SeleccionPartida")
	seleccion.reiniciar()
	seleccion.jugadores.assign([MARCO, MARCO])
	var nivel := NIVEL.instantiate()
	agregar_nivel(nivel)
	await esperar(0.4)
	colocar(nivel.jugador1)
	nivel.jugador2.recibir_golpe(100, nivel.jugador1)
	await esperar(4.8)
	exigir(nivel.jugador1.maquina_estados.es_estado_actual(&"Victoria") and nivel.jugador1.animacion.assigned_animation == &"victoria", "Marco debe reproducir su celebración")
	exigir(nivel.hud.anuncio_ganador.nombre.texto == "MARCO", "La pantalla de victoria debe mostrar MARCO")
	await capturar("victoria")
	nivel.free()
	seleccion.reiniciar()
	print("MARCO: %d fallos" % fallos)
	quit(1 if fallos else 0)
