extends CanvasLayer

signal continuar_solicitado
signal reiniciar_solicitado
signal volver_al_menu_solicitado

@onready var interfaz: Control = $Interfaz
@onready var panel: PanelContainer = $Interfaz/Centro/Panel
@onready var boton_continuar: Button = %Continuar
@onready var boton_reiniciar: Button = %Reiniciar
@onready var boton_volver_menu: Button = %VolverMenu

var tween_entrada: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	interfaz.hide()
	boton_continuar.pressed.connect(continuar_solicitado.emit)
	boton_reiniciar.pressed.connect(reiniciar_solicitado.emit)
	boton_volver_menu.pressed.connect(volver_al_menu_solicitado.emit)


func mostrar() -> void:
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
