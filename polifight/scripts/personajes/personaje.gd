extends CharacterBody2D

@onready var animacion = $AnimationPlayer
const SPEED = 300.0
const JUMP_VELOCITY = -900.0
const GRAVITY = 1200

enum Estado {
	IDLE,
	RUN,
	JUMP,
}

var estado_actual = Estado.IDLE



func _ready() -> void:
	cambiar_estado(Estado.IDLE)

func _physics_process(delta: float) -> void:
	#Gravedad
	if not is_on_floor():
		gravity(delta)
	
	if Input.is_action_just_pressed("salto") and is_on_floor():
		jump()
		cambiar_estado(Estado.JUMP)
	
	#movimiento en x
	var directionX := Input.get_axis("atras", "adelante")
	move(directionX)
	
		# Determinar estado
	if not is_on_floor():
		if velocity.y < 0:
			cambiar_estado(Estado.JUMP)
			
	elif abs(velocity.x) > 0:
		cambiar_estado(Estado.RUN)
	else:
		cambiar_estado(Estado.IDLE)
	
	move_and_slide()
	
	
func move(direction) -> void:	
	if  direction:
		velocity.x = direction * SPEED
		#animacion de caminar
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		animacion.play("idle")
	if not is_on_floor():
		animacion.play("salto")
	elif velocity.x == 0:
		animacion.play("idle")
		
	
func jump() -> void:
	velocity.y = JUMP_VELOCITY
	
func gravity(delta) -> void:
	velocity.y += GRAVITY * delta



func cambiar_estado(nuevo_estado):
	if estado_actual == nuevo_estado:
		return
	
	estado_actual = nuevo_estado
	
	match estado_actual:
		Estado.IDLE:
			animacion.play("idle")
		
		Estado.RUN:
			animacion.play("run")
		
		Estado.JUMP:
			animacion.play("jump")
		
