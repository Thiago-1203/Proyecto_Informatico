class_name Maquina_estados 
extends Node

@onready var nodo_controlado = self.owner

@export var default_state:Estado_base

var estado_actual:Estado_base = null


#ready se ejecuta cuando carga el nodo
func _ready() -> void:
	call_deferred("_iniciar_estado_default")
	
#Esta funcion se ejecuta en el nodo, se hace asi ya que asi nos aseguramos que haya cargado la maquina de estados
func _iniciar_estado_default() -> void:
	estado_actual = default_state
	_iniciar_estado()

#Funcion que prepara las variables para el nuevo estado y las inicia
func _iniciar_estado()->void:
	#Esto es para que se printee en la terminal y comprobar que estado se inicio
	prints("Maquina de estados", nodo_controlado.name, "iniciar estado", estado_actual.name)
	estado_actual.nodo_controlado = nodo_controlado
	estado_actual.maquina_estados = self
	estado_actual.start()

func cambiar_a(nuevo_estado:String) -> void:
	if estado_actual and estado_actual.has_method("end"): 
		estado_actual.end()
	estado_actual = get_node(nuevo_estado)
	_iniciar_estado()
	
	
func _process(delta: float) -> void:
	if estado_actual and estado_actual.has_method("on_process"):
		estado_actual.on_process(delta)
		
func _physics_process(delta: float) -> void:
	if estado_actual and estado_actual.has_method("on_physics_process"):
		estado_actual.on_physics_process(delta)
		
func _input(event: InputEvent) -> void:
	if estado_actual and estado_actual.has_method("on_input"):
		estado_actual.on_input(event)
		
func _unhandled_input(event: InputEvent) -> void:
	if estado_actual and estado_actual.has_method("on_unhandled_input"):
		estado_actual.on_unhadled_input(event)
		
func _unhandled_key_input(_event: InputEvent) -> void:
	if estado_actual and estado_actual.has_method("on_unhandled_key_input"):
		estado_actual.on_unhandled_key_input()
	
