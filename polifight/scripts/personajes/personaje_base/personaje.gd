class_name Personaje
extends CharacterBody2D

#ATTENTION esta clase es la base para todos los proximos personajes lo que se modifique aqui se le agregara a todos los personajes 
# que extiendan de esta clase

signal vida_cambiada(vida_actual: int, vida_maxima: int)
signal vida_agotada(personaje: Personaje)
signal secuencia_ko_finalizada(personaje: Personaje)

@onready var sprite: Sprite2D = $Sprite2D
@onready var animacion = $AnimationPlayer
@onready var hitbox: Hitbox = $Hitboxes/Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var contenedor_hitboxes: Node2D = $Hitboxes
@onready var maquina_estados: Maquina_estados = $MaquinaEstados

# Numero de jugador y la direccion en la que ven
@export_range(1, 2, 1) var numero_jugador: int = 1
@export_enum("Izquierda:-1", "Derecha:1") var direccion_inicial: int = 1
var direccion_mirada: int = 1


var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")
const SPEED: float = 300.0
const JUMP_VELOCITY: float = -650.0

@export var vida_maxima: int = 100
@export var danio: int

@export_category("Retroceso de golpes")
@export_range(0.0, 1000.0, 10.0) var retroceso_golpe_horizontal: float = 180.0
@export_range(0.0, 2000.0, 10.0) var frenado_retroceso: float = 520.0

@export_category("Lanzamiento de KO")
@export_range(0.0, 1000.0, 10.0) var impulso_ko_horizontal: float = 260.0
@export_range(0.0, 1500.0, 10.0) var impulso_ko_vertical: float = 700.0
@export_range(0.0, 800.0, 10.0) var impulso_rebote_ko: float = 220.0
@export_range(0.1, 1.0, 0.05) var velocidad_animacion_ko: float = 0.5
@export_range(0.0, 1.0, 0.05) var conservacion_horizontal_rebote_ko: float = 0.45
@export_range(0.0, 1.0, 0.05) var demora_victoria_ko: float = 0.25

@export_category("Efecto visual de golpe")
@export var color_destello_golpe: Color = Color(1.0, 0.15, 0.15, 1.0)
@export_range(0.01, 1.0, 0.01) var duracion_destello_golpe: float = 0.2

var vida_actual: int
var color_sprite_original: Color
var tween_destello_golpe: Tween
var ko_final_notificado: bool = false


func _ready() -> void:
	vida_actual = vida_maxima
	color_sprite_original = sprite.self_modulate
	
	hitbox.configurar(self, danio)
	hurtbox.configurar(self)
	hurtbox.golpe_recibido.connect(recibir_golpe)
	mirar_hacia(direccion_inicial)
	
func recibir_golpe(cantidad: int, atacante: Personaje) -> void:
	if vida_actual <= 0:
		return
	if maquina_estados.es_estado_actual(&"Bloqueando"):
		print(name, " bloqueo el golpe")
		return
	
	vida_actual = clampi(vida_actual - cantidad, 0, vida_maxima)
	vida_cambiada.emit(vida_actual, vida_maxima)
	reproducir_destello_golpe()
	print(name, " recibio", cantidad, " de danio. Vida restante: ", vida_actual)

	if vida_actual == 0:
		aplicar_lanzamiento_ko(atacante)
		vida_agotada.emit(self)
		derrotado()
		return

	aplicar_retroceso_golpe(atacante)
	if maquina_estados.tiene_estado(&"RecibirGolpe"):
		maquina_estados.cambiar_a("RecibirGolpe")

func derrotado()-> void:
	print(name, " fue derrotado")
	if maquina_estados.tiene_estado(&"KO"):
		maquina_estados.cambiar_a("KO")
	else:
		push_warning(str(name) + " no tiene un estado KO configurado")
		notificar_secuencia_ko_finalizada()


func aplicar_retroceso_golpe(atacante: Personaje) -> void:
	velocity.x = _direccion_alejamiento(atacante) * retroceso_golpe_horizontal


func aplicar_lanzamiento_ko(atacante: Personaje) -> void:
	velocity = Vector2(
		_direccion_alejamiento(atacante) * impulso_ko_horizontal,
		-impulso_ko_vertical
	)


func notificar_secuencia_ko_finalizada() -> void:
	if ko_final_notificado:
		return

	ko_final_notificado = true
	secuencia_ko_finalizada.emit(self)


func _direccion_alejamiento(atacante: Personaje) -> float:
	if is_instance_valid(atacante):
		var diferencia_horizontal := global_position.x - atacante.global_position.x
		if not is_zero_approx(diferencia_horizontal):
			return 1.0 if diferencia_horizontal > 0.0 else -1.0

	return -float(direccion_mirada)


func reproducir_destello_golpe() -> void:
	if tween_destello_golpe != null and tween_destello_golpe.is_valid():
		tween_destello_golpe.kill()

	sprite.self_modulate = color_destello_golpe
	tween_destello_golpe = create_tween()
	tween_destello_golpe.set_trans(Tween.TRANS_SINE)
	tween_destello_golpe.set_ease(Tween.EASE_OUT)
	tween_destello_golpe.tween_property(
		sprite,
		"self_modulate",
		color_sprite_original,
		duracion_destello_golpe
	)


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
	
	
