class_name Personaje
extends CharacterBody2D

#ATTENTION esta clase es la base para todos los proximos personajes lo que se modifique aqui se le agregara a todos los personajes 
# que extiendan de esta clase

const SHADER_DESTELLO_PERSONAJE: Shader = preload(
	"res://assets/shaders/destello_personaje.gdshader"
)

signal vida_cambiada(vida_actual: int, vida_maxima: int)
signal stamina_cambiada(stamina_actual: float, stamina_maxima: float)
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

@export_category("Stamina")
@export_range(1.0, 500.0, 1.0) var stamina_maxima: float = 100.0
@export_range(1.0, 100.0, 1.0) var costo_stamina_bloqueo: float = 25.0
@export_range(0.0, 100.0, 1.0) var recuperacion_stamina_por_segundo: float = 12.0
@export_range(0.5, 1.0, 0.05) var proporcion_reactivacion_bloqueo: float = 0.6

@export_category("Retroceso de golpes")
@export_range(0.0, 1000.0, 10.0) var retroceso_golpe_horizontal: float = 180.0
@export_range(0.0, 1000.0, 10.0) var retroceso_bloqueo_horizontal: float = 110.0
@export_range(0.0, 2000.0, 10.0) var frenado_retroceso: float = 520.0

@export_category("Lanzamiento de KO")
@export_range(0.0, 1000.0, 10.0) var impulso_ko_horizontal: float = 260.0
@export_range(0.0, 1500.0, 10.0) var impulso_ko_vertical: float = 700.0
@export_range(0.0, 800.0, 10.0) var impulso_rebote_ko: float = 220.0
@export_range(0.1, 1.0, 0.05) var velocidad_animacion_ko: float = 0.5
@export_range(0.0, 1.0, 0.05) var conservacion_horizontal_rebote_ko: float = 0.45
@export_range(0.0, 1.0, 0.05) var demora_victoria_ko: float = 0.25

@export_category("Efectos visuales de impacto")
@export var color_destello_rojo: Color = Color(1.0, 0.0, 0.0, 1.0)
@export_range(0.01, 1.0, 0.01) var duracion_destello_rojo: float = 0.35
@export var color_destello_bloqueo: Color = Color.WHITE
@export_range(0.01, 1.0, 0.01) var duracion_destello_bloqueo: float = 0.12

var vida_actual: int
var stamina_actual: float
var stamina_agotada: bool = false
var tween_destello: Tween
var material_destello: ShaderMaterial
var ko_final_notificado: bool = false
var oponente: Personaje


func _ready() -> void:
	vida_actual = vida_maxima
	stamina_actual = stamina_maxima
	material_destello = ShaderMaterial.new()
	material_destello.shader = SHADER_DESTELLO_PERSONAJE
	material_destello.set_shader_parameter(&"intensidad_destello", 0.0)
	sprite.material = material_destello
	
	hitbox.configurar(self, danio)
	hurtbox.configurar(self)
	hurtbox.golpe_recibido.connect(recibir_golpe)
	mirar_hacia(direccion_inicial)


func _process(delta: float) -> void:
	if vida_actual <= 0 or maquina_estados.es_estado_actual(&"Bloqueando"):
		return
	if stamina_actual >= stamina_maxima:
		return

	_cambiar_stamina(stamina_actual + recuperacion_stamina_por_segundo * delta)


func _physics_process(_delta: float) -> void:
	_actualizar_direccion_hacia_oponente()


func configurar_oponente(nuevo_oponente: Personaje) -> void:
	oponente = nuevo_oponente
	_actualizar_direccion_hacia_oponente()
	
func recibir_golpe(cantidad: int, atacante: Personaje) -> void:
	if vida_actual <= 0:
		return
	if maquina_estados.es_estado_actual(&"Bloqueando") and puede_bloquear():
		_cambiar_stamina(stamina_actual - costo_stamina_bloqueo)
		aplicar_retroceso_bloqueo(atacante)
		if stamina_agotada:
			reproducir_destello_rojo()
			print(name, " sufrio una ruptura de defensa")
		else:
			reproducir_destello_bloqueo()
			print(name, " bloqueo el golpe")
		return
	
	vida_actual = clampi(vida_actual - cantidad, 0, vida_maxima)
	vida_cambiada.emit(vida_actual, vida_maxima)
	reproducir_destello_rojo()
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


func aplicar_retroceso_bloqueo(atacante: Personaje) -> void:
	velocity.x = _direccion_alejamiento(atacante) * retroceso_bloqueo_horizontal


func puede_bloquear() -> bool:
	if vida_actual <= 0 or stamina_agotada:
		return false

	return stamina_actual >= costo_stamina_bloqueo


func _cambiar_stamina(nueva_stamina: float) -> void:
	var stamina_anterior := stamina_actual
	stamina_actual = clampf(nueva_stamina, 0.0, stamina_maxima)
	if is_zero_approx(stamina_actual):
		stamina_agotada = true
	elif stamina_agotada and stamina_actual >= stamina_maxima * proporcion_reactivacion_bloqueo:
		stamina_agotada = false

	if not is_equal_approx(stamina_actual, stamina_anterior):
		stamina_cambiada.emit(stamina_actual, stamina_maxima)


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


func reproducir_destello_rojo() -> void:
	_reproducir_destello(color_destello_rojo, duracion_destello_rojo)


func reproducir_destello_bloqueo() -> void:
	_reproducir_destello(color_destello_bloqueo, duracion_destello_bloqueo)


func _reproducir_destello(color_destello: Color, duracion: float) -> void:
	if tween_destello != null and tween_destello.is_valid():
		tween_destello.kill()

	material_destello.set_shader_parameter(&"color_destello", color_destello)
	material_destello.set_shader_parameter(&"intensidad_destello", 1.0)
	tween_destello = create_tween()
	tween_destello.set_trans(Tween.TRANS_SINE)
	tween_destello.set_ease(Tween.EASE_OUT)
	tween_destello.tween_method(
		_actualizar_intensidad_destello,
		1.0,
		0.0,
		duracion
	)


func _actualizar_intensidad_destello(intensidad: float) -> void:
	material_destello.set_shader_parameter(&"intensidad_destello", intensidad)


func play_animation(nombre: StringName) -> void:
	if animacion.has_animation(nombre):
		animacion.play(nombre)
	else:
		push_warning("No existe la animación: " + str(nombre))

#Funcion que construye la accion dependiendo del jugador que la activo
func accion(nombre: String) -> StringName:
	return StringName("j%d_%s" % [numero_jugador, nombre])


func _actualizar_direccion_hacia_oponente() -> void:
	if vida_actual <= 0 or not is_instance_valid(oponente):
		return

	var diferencia_horizontal := oponente.global_position.x - global_position.x
	if is_zero_approx(diferencia_horizontal):
		return

	var nueva_direccion := 1 if diferencia_horizontal > 0.0 else -1
	if nueva_direccion != direccion_mirada:
		mirar_hacia(nueva_direccion)

#funcion que determina a donde miran los personajes
func mirar_hacia(direccion: int) -> void:
	if direccion < 0:
		direccion_mirada = -1
	else:
		direccion_mirada = 1

	sprite.flip_h = direccion_mirada == -1
	contenedor_hitboxes.scale.x = direccion_mirada
	
	
