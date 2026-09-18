extends Control

@onready var logo: TextureRect = $CenterContainer/MenuContent/LogoSlot/Logo
@onready var boton_jugar: Button = $CenterContainer/MenuContent/JugarRow/Jugar
@onready var boton_salir: Button = $CenterContainer/MenuContent/SalirRow/Salir
@onready var jugar_flecha_izquierda: Control = $CenterContainer/MenuContent/JugarRow/FlechaIzquierdaSlot/FlechaIzquierda
@onready var jugar_flecha_derecha: Control = $CenterContainer/MenuContent/JugarRow/FlechaDerechaSlot/FlechaDerecha
@onready var salir_flecha_izquierda: Control = $CenterContainer/MenuContent/SalirRow/FlechaIzquierdaSlot/FlechaIzquierda
@onready var salir_flecha_derecha: Control = $CenterContainer/MenuContent/SalirRow/FlechaDerechaSlot/FlechaDerecha

var animacion_flechas: Tween


func _on_cinematica_entrada_finalizada() -> void:
	logo.pivot_offset = logo.size * 0.5

	var entrada_frontal := create_tween()
	entrada_frontal.set_parallel(true)
	entrada_frontal.tween_property(logo, "modulate:a", 1.0, 0.18)
	entrada_frontal.tween_property(logo, "scale", Vector2(1.16, 1.16), 0.72).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await entrada_frontal.finished

	# El cambio de escala simula un impacto contra la pantalla sin mover el logo en vertical.
	var impacto := create_tween()
	impacto.tween_property(logo, "scale", Vector2(1.08, 0.9), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	impacto.tween_property(logo, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await impacto.finished

	_mostrar_botones()


func _mostrar_botones() -> void:
	boton_jugar.disabled = false
	boton_salir.disabled = false

	var aparicion := create_tween()
	aparicion.set_parallel(true)
	aparicion.tween_property(boton_jugar, "modulate:a", 1.0, 0.25)
	aparicion.tween_property(boton_salir, "modulate:a", 1.0, 0.25)
	await aparicion.finished
	boton_jugar.grab_focus()


func _seleccionar_boton(boton: Button) -> void:
	if animacion_flechas and animacion_flechas.is_valid():
		animacion_flechas.kill()

	var todas_las_flechas: Array[Control] = [
		jugar_flecha_izquierda,
		jugar_flecha_derecha,
		salir_flecha_izquierda,
		salir_flecha_derecha,
	]
	for flecha in todas_las_flechas:
		flecha.position = Vector2.ZERO
		flecha.modulate.a = 0.0

	var flecha_izquierda := jugar_flecha_izquierda if boton == boton_jugar else salir_flecha_izquierda
	var flecha_derecha := jugar_flecha_derecha if boton == boton_jugar else salir_flecha_derecha
	flecha_izquierda.modulate.a = 1.0
	flecha_derecha.modulate.a = 1.0

	animacion_flechas = create_tween().set_loops()
	animacion_flechas.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	animacion_flechas.set_parallel(true)
	animacion_flechas.tween_property(flecha_izquierda, "position:x", 8.0, 0.28)
	animacion_flechas.tween_property(flecha_derecha, "position:x", -8.0, 0.28)
	animacion_flechas.chain().tween_property(flecha_izquierda, "position:x", 0.0, 0.28)
	animacion_flechas.parallel().tween_property(flecha_derecha, "position:x", 0.0, 0.28)


func _on_jugar_focus_entered() -> void:
	_seleccionar_boton(boton_jugar)


func _on_salir_focus_entered() -> void:
	_seleccionar_boton(boton_salir)


func _on_jugar_mouse_entered() -> void:
	if is_instance_valid(boton_jugar) and not boton_jugar.disabled:
		boton_jugar.grab_focus()


func _on_salir_mouse_entered() -> void:
	if is_instance_valid(boton_salir) and not boton_salir.disabled:
		boton_salir.grab_focus()


func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://escenas/juego/nivelI.tscn")


func _on_salir_pressed() -> void:
	get_tree().quit()
