extends Node

const ESCENA_MENU_PRINCIPAL: String = "res://escenas/menu/menu.tscn"

@export var ruta_menu_pausa: NodePath = ^"../MenuPausa"

@onready var menu_pausa = get_node(ruta_menu_pausa)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu_pausa.continuar_solicitado.connect(_reanudar_combate)
	menu_pausa.reiniciar_solicitado.connect(_reiniciar_combate)
	menu_pausa.volver_al_menu_solicitado.connect(_volver_al_menu)


func _exit_tree() -> void:
	get_tree().paused = false


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pausa"):
		return

	get_viewport().set_input_as_handled()
	if get_tree().paused:
		_reanudar_combate()
	else:
		_pausar_combate()


func _pausar_combate() -> void:
	menu_pausa.mostrar()
	get_tree().paused = true


func _reanudar_combate() -> void:
	get_tree().paused = false
	menu_pausa.ocultar()


func _reiniciar_combate() -> void:
	get_tree().paused = false
	menu_pausa.ocultar()
	var error := get_tree().reload_current_scene()
	if error != OK:
		push_error("No se pudo reiniciar el combate: " + error_string(error))


func _volver_al_menu() -> void:
	get_tree().paused = false
	menu_pausa.ocultar()
	var error := get_tree().change_scene_to_file(ESCENA_MENU_PRINCIPAL)
	if error != OK:
		push_error("No se pudo volver al menú: " + error_string(error))
