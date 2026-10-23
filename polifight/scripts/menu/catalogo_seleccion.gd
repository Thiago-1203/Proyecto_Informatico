class_name CatalogoSeleccion
extends Resource
## El orden de estas listas es el orden del menú. Se edita desde el inspector.

@export var personajes: Array[FichaSeleccion] = []
@export var escenarios: Array[FichaSeleccion] = []


func disponibles(entradas: Array[FichaSeleccion]) -> Array[FichaSeleccion]:
	var resultado: Array[FichaSeleccion] = []
	var ids: Array[StringName] = []
	for ficha in entradas:
		if ficha == null or not ficha.disponible:
			continue
		if ficha.id == &"" or ficha.id in ids or ficha.nombre.is_empty() or not ResourceLoader.exists(ficha.escena, "PackedScene"):
			push_warning("Entrada de selección inválida o duplicada: " + str(ficha.id))
			continue
		ids.append(ficha.id)
		resultado.append(ficha)
	return resultado
