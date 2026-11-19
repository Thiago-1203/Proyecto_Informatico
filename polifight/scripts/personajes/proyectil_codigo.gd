extends Hitbox

const CUADROS = preload("res://assets/characters/Barbieri/Ulti/codigo_frames.tres")
var direccion: int = 1
var velocidad: float = 720.0
var tiempo: float = 0.0
var impactado: bool = false
var visual: AnimatedSprite2D
var colision: CollisionShape2D


func _ready() -> void:
	add_to_group("proyectiles_codigo")
	collision_layer = 4
	collision_mask = 1
	colision = CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	# Alcanza también la hurtbox agachada; conserva el límite superior y la trayectoria.
	forma.size = Vector2(110, 110)
	colision.shape = forma
	colision.position = Vector2(0, 28)
	add_child(colision)
	visual = AnimatedSprite2D.new()
	visual.sprite_frames = CUADROS
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2(0.4 * direccion, 0.4)
	add_child(visual)
	visual.play(&"vuelo")
	visual.animation_finished.connect(queue_free)
	body_entered.connect(func(_cuerpo: Node2D): _impactar())
	iniciar_ataque(1.35)


func registrar_impacto(objetivo: Personaje) -> bool:
	if impactado or not is_instance_valid(atacante):
		return false
	if not super.registrar_impacto(objetivo):
		return false
	_impactar()
	return true


func _impactar() -> void:
	if impactado:
		return
	impactado = true
	ataque_en_curso = false
	colision.set_deferred("disabled", true)
	visual.play(&"impacto")


func _physics_process(delta: float) -> void:
	tiempo += delta
	if not is_instance_valid(atacante) or atacante.vida_actual <= 0 or (
		is_instance_valid(atacante.oponente) and atacante.oponente.vida_actual <= 0
	) or tiempo > 3.0:
		queue_free()
		return
	if not impactado:
		position.x += direccion * velocidad * delta
