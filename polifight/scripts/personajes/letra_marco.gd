extends Hitbox
## Cada proyectil muestra el nombre de su tipografía con esa misma fuente.

const FUENTES: Array[Font] = [
	preload("res://assets/fonts/tipografias_marco/Arial-Bold.ttf"),
	preload("res://assets/fonts/tipografias_marco/TimesNewRoman-Regular.ttf"),
	preload("res://assets/fonts/DejaVuSans-Bold.ttf"),
]
const NOMBRES_TIPOGRAFIAS := ["Arial", "Times New Roman", "Sans Serif"]
var variante: int = 0
var velocidad: float = 400.0
var tiempo: float = 0.0
var tiempo_impacto: float = 0.0
var impactado: bool = false
var fuente: Font
var texto: String
var tamano: int
var color: Color
var colision: CollisionShape2D
var linea_base: Vector2


func _ready() -> void:
	add_to_group("letras_marco")
	z_index = 5
	collision_layer = 4
	collision_mask = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fuente = FUENTES[variante % FUENTES.size()]
	texto = NOMBRES_TIPOGRAFIAS[variante % FUENTES.size()]
	tamano = 64
	while fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x > 600.0:
		tamano -= 1
	color = Color.BLACK
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x
	linea_base = Vector2(-ancho * 0.5, (fuente.get_ascent(tamano) - fuente.get_descent(tamano)) * 0.5)
	colision = CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	# El nombre identifica el proyectil; su núcleo conserva el alcance del golpe.
	forma.size = Vector2(64, 72)
	colision.shape = forma
	add_child(colision)
	body_entered.connect(func(_cuerpo: Node2D): _impactar())
	# El empuje es corto para que las siguientes letras puedan alcanzar la misma zona.
	iniciar_ataque(0.3)


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
	queue_redraw()


func _physics_process(delta: float) -> void:
	tiempo += delta
	if not is_instance_valid(atacante) or atacante.vida_actual <= 0 or (
		is_instance_valid(atacante.oponente) and atacante.oponente.vida_actual <= 0
	) or tiempo > 5.0:
		queue_free()
		return
	if impactado:
		tiempo_impacto += delta
		modulate.a = maxf(0.0, 1.0 - tiempo_impacto / 0.24)
		if tiempo_impacto >= 0.24:
			queue_free()
	else:
		position.y += velocidad * absf(scale.y) * delta
	queue_redraw()


func _draw() -> void:
	if fuente == null:
		return
	if impactado:
		for i in 5:
			var direccion := Vector2.from_angle(TAU * i / 5.0)
			draw_circle(direccion * (12.0 + tiempo_impacto * 140.0), 4.0, color)
		return
	# Nombre completo girado 90°: se lee de arriba hacia abajo al caer.
	draw_set_transform(Vector2.ZERO, PI * 0.5)
	# Relleno negro y borde claro para conservar contraste sobre zonas oscuras.
	for borde in [Vector2(-3, 0), Vector2(3, 0), Vector2(0, -3), Vector2(0, 3)]:
		draw_string(fuente, linea_base + borde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, Color("f5f5f5"))
	draw_string(fuente, linea_base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, color)
