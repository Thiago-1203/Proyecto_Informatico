extends Personaje
## Luchador defensivo: invoca nombres de tipografías al levantar las manos.

const ESTADO_ULTI = preload("res://scripts/personajes/ulti_marco.gd")

signal ulti_cambiada(carga: float)
@export_range(0.0, 100.0) var carga_ulti: float = 0.0
@export_range(1.0, 100.0) var carga_ulti_por_golpe: float = 20.0


func _init() -> void:
	danio = 8
	stamina_maxima = 125.0


func _ready() -> void:
	super._ready()
	hitbox.impacto_con_danio.connect(_cargar_ulti_por_golpe)
	var estado := ESTADO_ULTI.new()
	estado.name = "Ulti"
	maquina_estados.add_child(estado)
	estado.nodo_controlado = self


func _physics_process(delta: float) -> void:
	if maquina_estados.es_estado_actual(&"Ulti"):
		cooldown_ataque_restante = maxf(0.0, cooldown_ataque_restante - delta)
		return
	super._physics_process(delta)
	if entrada_recien_presionada(accion("ulti")) and puede_usar_ulti():
		maquina_estados.cambiar_a("Ulti")


func _cargar_ulti_por_golpe(_objetivo: Personaje) -> void:
	if vida_actual <= 0:
		return
	carga_ulti = minf(100.0, carga_ulti + carga_ulti_por_golpe)
	ulti_cambiada.emit(carga_ulti)


func puede_usar_ulti() -> bool:
	return carga_ulti >= 100.0 and puede_atacar() and is_on_floor() and (
		maquina_estados.es_estado_actual(&"Idle")
		or maquina_estados.es_estado_actual(&"Caminar")
		or maquina_estados.es_estado_actual(&"Agacharse")
		or maquina_estados.es_estado_actual(&"CaminarAgachado")
	) and is_instance_valid(oponente) and oponente.vida_actual > 0


func play_animation(nombre: StringName) -> void:
	# Los pasos se invierten al alejarse sin dar la espalda al oponente.
	if nombre == &"caminar_adelante" or nombre == &"Caminar_Agachado":
		var direccion := eje_entrada(accion("izquierda"), accion("derecha"))
		if direccion * direccion_mirada < 0.0:
			nombre = &"caminar_atras" if nombre == &"caminar_adelante" else &"Caminar_Agachado_atras"
	super.play_animation(nombre)
