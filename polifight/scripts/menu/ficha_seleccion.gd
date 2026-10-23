class_name FichaSeleccion
extends Resource
## Una entrada del catálogo. La escena del personaje debe heredar de Personaje.

@export var id: StringName
@export var nombre: String
@export var subtitulo: String
@export_multiline var descripcion: String
@export var imagen: Texture2D
@export_file("*.tscn") var escena: String
@export var disponible: bool = true

@export_group("Vista animada del personaje")
@export var ruta_sprite: NodePath = ^"Sprite2D"
@export var ruta_animacion: NodePath = ^"AnimationPlayer"
@export var animacion_idle: StringName = &"idle"


var _escena_estadisticas: String = ""
var _estadisticas: Dictionary = {}


func obtener_estadisticas() -> Dictionary:
	# Una sola fuente de verdad: los valores que tendrá esta escena en combate.
	if _escena_estadisticas == escena and not _estadisticas.is_empty():
		return _estadisticas
	var personaje := (load(escena) as PackedScene).instantiate()
	_estadisticas = {}
	if personaje is Personaje:
		_estadisticas = {"danio": personaje.danio, "stamina": personaje.stamina_maxima}
	_escena_estadisticas = escena
	personaje.free()
	return _estadisticas
