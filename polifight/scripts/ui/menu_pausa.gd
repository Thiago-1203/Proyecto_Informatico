extends CanvasLayer

signal continuar_solicitado
signal reiniciar_solicitado
signal volver_al_menu_solicitado

const GUIA = preload("res://scripts/ui/guia_controles.gd")

@onready var interfaz: Control = $Interfaz
@onready var panel: PanelContainer = $Interfaz/Centro/Panel
@onready var boton_continuar: Button = %Continuar
@onready var boton_controles: Button = %Controles
@onready var boton_reiniciar: Button = %Reiniciar
@onready var boton_volver_menu: Button = %VolverMenu

var tween_entrada: Tween
var guia_controles: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	interfaz.hide()
	boton_continuar.pressed.connect(continuar_solicitado.emit)
	boton_reiniciar.pressed.connect(reiniciar_solicitado.emit)
	boton_volver_menu.pressed.connect(volver_al_menu_solicitado.emit)
	boton_controles.pressed.connect(mostrar_controles)
	guia_controles = GUIA.new()
	interfaz.add_child(guia_controles)
	guia_controles.volver_solicitado.connect(cerrar_controles)
	var botones := [boton_continuar, boton_controles, boton_reiniciar, boton_volver_menu]
	for i in botones.size():
		var boton: Button = botones[i]
		boton.focus_neighbor_top = botones[posmod(i - 1, botones.size())].get_path()
		boton.focus_neighbor_bottom = botones[(i + 1) % botones.size()].get_path()
		boton.focus_neighbor_left = boton.get_path()
		boton.focus_neighbor_right = boton.get_path()
		boton.focus_previous = boton.focus_neighbor_top
		boton.focus_next = boton.focus_neighbor_bottom


func mostrar() -> void:
	guia_controles.hide()
	$Interfaz/Centro.show()
	interfaz.show()
	interfaz.modulate.a = 0.0
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.86, 0.86)

	if tween_entrada != null and tween_entrada.is_valid():
		tween_entrada.kill()

	tween_entrada = create_tween()
	tween_entrada.set_parallel(true)
	tween_entrada.tween_property(interfaz, "modulate:a", 1.0, 0.14)
	tween_entrada.tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	boton_continuar.grab_focus()


func ocultar() -> void:
	if tween_entrada != null and tween_entrada.is_valid():
		tween_entrada.kill()
	interfaz.hide()
	guia_controles.hide()
	$Interfaz/Centro.show()


func mostrar_controles() -> void:
	$Interfaz/Centro.hide()
	guia_controles.abrir()


func cerrar_controles() -> void:
	guia_controles.hide()
	$Interfaz/Centro.show()
	boton_controles.grab_focus()


func controles_visibles() -> bool:
	return guia_controles.is_visible_in_tree()


func _input(event: InputEvent) -> void:
	if not interfaz.visible:
		return
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		get_viewport().set_input_as_handled()
		# B cierra el menú: esa pulsación no debe convertirse en una patada.
		var jugador: int = get_node("/root/EntradaMandos").jugador_para_dispositivo(event.device)
		if jugador >= 0:
			Input.action_release(StringName("j%d_patada" % (jugador + 1)))
		if controles_visibles():
			cerrar_controles()
		else:
			continuar_solicitado.emit()
