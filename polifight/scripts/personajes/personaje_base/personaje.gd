class_name Personaje
extends CharacterBody2D

#ATTENTION esta clase es la base para todos los proximos personajes lo que se modifique aqui se le agregara a todos los personajes 
# que extiendan de esta clase


@onready var sprite: Sprite2D = $Sprite2D
@onready var animacion = $AnimationPlayer
@onready var hitbox: Hitbox = $Hitboxes/Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var contenedor_hitboxes: Node2D = $Hitboxes

# Numero de jugador y la direccion en la que ven
@export_range(1, 2, 1) var numero_jugador: int = 1
@export_enum("Izquierda:-1", "Derecha:1") var direccion_inicial: int = 1
var direccion_mirada: int = 1


var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")
const SPEED: float = 300.0
const JUMP_VELOCITY: float = -650.0

@export var vida_maxima: int = 100
@export var danio: int = 15


var vida_actual: int


func _ready() -> void:
	vida_actual = vida_maxima
	
	hitbox.configurar(self, danio)
	hurtbox.configurar(self)
	hurtbox.golpe_recibido.connect(recibir_golpe)
	mirar_hacia(direccion_inicial)
	
func recibir_golpe(cantidad: int, _atacante: Personaje) -> void:
	vida_actual = maxi(vida_actual - cantidad, 0)
	print(name," recibió ",cantidad," de daño. Vida restante: ",vida_actual)
	if vida_actual == 0:
		derrotado()

func derrotado()-> void:
	print(name, " fue derrotado")

func play_animation(nombre: StringName) -> void:
	if animacion.has_animation(nombre):
		animacion.play(nombre)
	else:
		push_warning("No existe la animación: " + str(nombre))

#Funcion que construye la accion dependiendo del jugador que la activo
func accion(nombre: String) -> StringName:
	return StringName("j%d_%s" % [numero_jugador, nombre])

#funcion que determina a donde miran los personajes
func mirar_hacia(direccion: int) -> void:
	if direccion < 0:
		direccion_mirada = -1
	else:
		direccion_mirada = 1

	sprite.flip_h = direccion_mirada == -1
	contenedor_hitboxes.scale.x = direccion_mirada
	
	
