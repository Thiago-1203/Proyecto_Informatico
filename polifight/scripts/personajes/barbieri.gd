extends Personaje

#Clase Hija de personaje.gd, cuando querramos agregarle funcionalidades particulares a Barbieri lo hacemos aca

const DANIO_BARBIERI : int = 10
const ESTADO_ULTI = preload("res://scripts/personajes/ulti_barbieri.gd")

signal ulti_cambiada(carga: float)
@export_range(0.0, 100.0) var carga_ulti: float = 0.0
@export_range(1.0, 100.0) var carga_ulti_por_golpe: float = 20.0


func _ready() -> void:
	super._ready()
	hitbox.impacto_con_danio.connect(_cargar_ulti_por_golpe)
	var estado := ESTADO_ULTI.new()
	estado.name = "Ulti"
	maquina_estados.add_child(estado)
	estado.nodo_controlado = self


func _physics_process(delta: float) -> void:
	# Mantener la orientación de la laptop durante toda la ráfaga.
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
	) and (not is_instance_valid(oponente) or oponente.vida_actual > 0)


func _init() -> void:
	danio = DANIO_BARBIERI
