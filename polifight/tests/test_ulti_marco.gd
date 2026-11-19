extends SceneTree

const NIVEL = preload("res://escenas/juego/nivelI.tscn")
const MARCO = preload("res://datos/seleccion/personajes/marco.tres")
var nivel: Node
var vista: SubViewport
var fallos := 0
var capturas := false


func _initialize() -> void:
	capturas = "--capturas" in OS.get_cmdline_user_args()
	call_deferred("_probar")


func exigir(valor: bool, mensaje: String) -> void:
	if not valor:
		fallos += 1
		push_error(mensaje)


func esperar(segundos: float) -> void:
	await create_timer(segundos, true, true).timeout


func preparar(numero: int, escala: float = 1.0, contra_ia: bool = false) -> Personaje:
	if is_instance_valid(nivel):
		nivel.free()
	var seleccion: EstadoSeleccionPartida = root.get_node("SeleccionPartida")
	seleccion.reiniciar()
	seleccion.jugadores[numero - 1] = MARCO
	seleccion.contra_ia = contra_ia
	seleccion.dificultad_ia = EstadoSeleccionPartida.Dificultad.DIFICIL
	nivel = NIVEL.instantiate()
	nivel.escala_personajes = escala
	for nombre in ["AparicionJ1", "AparicionJ2"]:
		nivel.get_node(nombre).position.y -= 200.0 * (escala - 1.0)
	(vista if vista != null else root).add_child(nivel)
	if vista == null:
		current_scene = nivel
	await esperar(0.4)
	nivel.jugador1.position.x = 700
	nivel.jugador2.position.x = 1400
	await physics_frame
	var marco: Personaje = nivel.jugador1 if numero == 1 else nivel.jugador2
	marco.set("carga_ulti", 100.0)
	return marco


func probar_carga(numero: int) -> void:
	var marco := await preparar(numero)
	var rival := marco.oponente
	marco.set("carga_ulti", 0.0)
	await esperar(0.2)
	exigir(is_zero_approx(marco.get("carga_ulti")), "Esperar no recarga la ulti")
	marco.maquina_estados.cambiar_a("Ulti")
	exigir(not marco.maquina_estados.es_estado_actual(&"Ulti"), "La ulti necesita la carga completa")
	for i in 5:
		marco.hitbox.iniciar_ataque()
		rival.hurtbox._cuando_entra_un_area(marco.hitbox)
		rival.hurtbox._cuando_entra_un_area(marco.hitbox)
		marco.hitbox.finalizar_ataque()
		exigir(is_equal_approx(marco.get("carga_ulti"), (i + 1) * 20.0), "Cada golpe carga una sola vez")
	var barra := nivel.hud.get_node("Barras/PanelJugador%d/UltiBar%d" % [numero, numero]) as ProgressBar
	exigir(barra.value == 100.0, "El HUD debe mostrar la carga de Marco")
	marco.set("carga_ulti", 0.0)
	Input.action_press(rival.accion("bloqueo"))
	rival.maquina_estados.cambiar_a("Bloqueando")
	marco.hitbox.iniciar_ataque()
	rival.hurtbox._cuando_entra_un_area(marco.hitbox)
	marco.hitbox.finalizar_ataque()
	exigir(is_zero_approx(marco.get("carga_ulti")), "Los golpes bloqueados no recargan")
	Input.action_release(rival.accion("bloqueo"))


func probar_lluvia(numero: int, escala: float) -> void:
	var marco := await preparar(numero, escala)
	var rival := marco.oponente
	Input.action_press(marco.accion("ulti"))
	await physics_frame
	await physics_frame
	Input.action_release(marco.accion("ulti"))
	exigir(marco.maquina_estados.es_estado_actual(&"Ulti"), "L/3 deben activar la ulti de cada jugador")
	exigir(is_zero_approx(marco.get("carga_ulti")), "La ulti consume la carga")
	await esperar(0.35)
	exigir(get_nodes_in_group("letras_marco").is_empty(), "Primero debe levantar las manos")
	await esperar(0.35)
	var letras := get_nodes_in_group("letras_marco")
	exigir(letras.size() == 3, "Cada oleada debe crear tres letras")
	var fuentes: Array = []
	var nombres: Array = []
	for letra in letras:
		if not fuentes.has(letra.fuente):
			fuentes.append(letra.fuente)
		nombres.append(letra.texto)
		exigir(letra.fuente.get_string_size(letra.texto, HORIZONTAL_ALIGNMENT_LEFT, -1, letra.tamano).x <= 600, "El nombre completo debe caber en su largo de lectura")
		exigir(letra.global_scale.is_equal_approx(marco.global_scale), "Las letras deben respetar la escala del mapa")
	exigir(fuentes.size() == 3, "La lluvia debe usar tres fuentes diferentes")
	exigir(nombres == ["Arial", "Times New Roman", "Sans Serif"], "Deben caer Arial, Times New Roman y Sans Serif")
	var primera: Node2D = letras[0]
	var altura := primera.position.y
	await esperar(0.08)
	exigir(primera.position.y > altura, "Las letras deben caer desde arriba")
	# Pausar debe congelar tanto la invocación como las letras ya creadas.
	var estado: Node = marco.maquina_estados.estado_actual
	var tiempo: float = estado.tiempo
	altura = primera.position.y
	paused = true
	await create_timer(0.15, true, false, true).timeout
	exigir(is_equal_approx(estado.tiempo, tiempo) and is_equal_approx(primera.position.y, altura), "La pausa debe congelar toda la ulti")
	paused = false
	await esperar(1.35)
	if capturas:
		await RenderingServer.frame_post_draw
		vista.get_texture().get_image().save_png("res://docs/marco/ulti-j%d.png" % numero)
	await esperar(4.3)
	exigir(rival.vida_actual == 76, "Cuatro letras centrales deben causar 24 de daño al rival quieto")
	exigir(marco.vida_actual == 100, "No debe haber autogolpes")
	exigir(is_zero_approx(marco.get("carga_ulti")), "Las letras no recargan su propia ulti")
	exigir(marco.maquina_estados.es_estado_actual(&"Idle"), "Debe recuperar idle al bajar los brazos")
	exigir(get_nodes_in_group("letras_marco").is_empty(), "Las letras deben desaparecer al impactar o llegar al suelo")
	exigir(marco.sprite.scale == Vector2.ONE and marco.sprite.position == Vector2.ZERO, "La ulti no debe alterar el tamaño ni el apoyo")
	marco.maquina_estados.cambiar_a("Ulti")
	exigir(not marco.maquina_estados.es_estado_actual(&"Ulti"), "No puede repetir sin recargar")


func _probar() -> void:
	if capturas and DisplayServer.get_name() != "headless":
		vista = SubViewport.new()
		vista.size = Vector2i(1920, 1080)
		vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(vista)
	else:
		capturas = false
	for numero in [1, 2]:
		await probar_carga(numero)
		await probar_lluvia(numero, 1.0 if numero == 1 else 1.1)
	# La guardia baja también recibe la lluvia vertical y al activar se recupera
	# la hurtbox de pie para acompañar la animación de brazos en alto.
	var marco := await preparar(1)
	Input.action_press(marco.oponente.accion("agacharse"))
	marco.oponente.maquina_estados.cambiar_a("Agacharse")
	marco.maquina_estados.cambiar_a("Agacharse")
	await physics_frame
	marco.maquina_estados.cambiar_a("Ulti")
	exigir(marco.hurtbox.get_node("CollisionShape2D").shape.size == Vector2(246, 392), "La invocación restaura la hurtbox de pie")
	await esperar(5.8)
	exigir(marco.oponente.vida_actual == 76, "La lluvia debe alcanzar un rival agachado")
	Input.action_release(marco.oponente.accion("agacharse"))
	# Interrupción temprana: no dejar oleadas programadas ni poses atascadas.
	marco = await preparar(1)
	marco.maquina_estados.cambiar_a("Ulti")
	await esperar(0.25)
	marco.recibir_golpe(10, marco.oponente)
	await esperar(2.0)
	exigir(marco.oponente.vida_actual == 100 and get_nodes_in_group("letras_marco").is_empty(), "Interrumpir la preparación cancela la lluvia")
	# Las letras ya invocadas persisten, pero no aparecen oleadas nuevas.
	marco = await preparar(1)
	marco.maquina_estados.cambiar_a("Ulti")
	await esperar(0.75)
	var estado: Node = marco.maquina_estados.estado_actual
	marco.recibir_golpe(10, marco.oponente)
	await esperar(3.5)
	exigir(estado.siguiente == 1 and marco.oponente.vida_actual == 94, "Interrumpir después de invocar conserva sólo la primera oleada")
	# Bloquear conserva vida y consume stamina con las reglas del combate.
	marco = await preparar(1)
	Input.action_press(marco.oponente.accion("bloqueo"))
	marco.oponente.maquina_estados.cambiar_a("Bloqueando")
	marco.maquina_estados.cambiar_a("Ulti")
	await esperar(5.8)
	exigir(marco.oponente.vida_actual == 100 and marco.oponente.stamina_actual < 30, "El bloqueo debe defenderse de la lluvia gastando stamina")
	Input.action_release(marco.oponente.accion("bloqueo"))
	# Un KO cancela la invocación y limpia los proyectiles en vuelo.
	marco = await preparar(1)
	marco.oponente.vida_actual = 6
	marco.maquina_estados.cambiar_a("Ulti")
	await esperar(3.0)
	exigir(marco.oponente.vida_actual == 0 and get_nodes_in_group("letras_marco").is_empty(), "La lluvia puede causar KO y debe limpiarse al terminar la pelea")
	marco = await preparar(2, 1.0, true)
	await esperar(0.5)
	exigir(marco.controlado_por_ia and marco.maquina_estados.es_estado_actual(&"Ulti") and is_zero_approx(marco.get("carga_ulti")), "La IA debe invocar la lluvia al disponer de carga")
	nivel.free()
	root.get_node("SeleccionPartida").reiniciar()
	print("ULTI MARCO: %d fallos" % fallos)
	quit(1 if fallos else 0)
