extends Personaje

#Clase Hija de personaje.gd, cuando querramos agregarle funcionalidades particulares a Barbieri lo hacemos aca

const DANIO_BARBIERI : int = 10


func _init() -> void:
	danio = DANIO_BARBIERI
