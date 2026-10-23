extends Control
## Reproduce las pistas visuales del idle real, sin física, daño ni controles de combate.

var ficha: FichaSeleccion
var animacion: AnimationPlayer
var visual: Node2D


func configurar(nueva_ficha: FichaSeleccion, espejo: bool = false) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ficha == nueva_ficha and visual != null:
		return
	ficha = nueva_ficha
	if visual != null:
		visual.queue_free()
	visual = Node2D.new()
	add_child(visual)
	var escena := load(ficha.escena) as PackedScene
	var origen := escena.instantiate()
	var sprite_origen := origen.get_node_or_null(ficha.ruta_sprite) as Sprite2D
	var player_origen := origen.get_node_or_null(ficha.ruta_animacion) as AnimationPlayer
	if sprite_origen == null or player_origen == null or not player_origen.has_animation(ficha.animacion_idle):
		push_warning("Falta el sprite o la animación idle de " + ficha.nombre)
		origen.free()
		return
	var sprite := sprite_origen.duplicate() as Sprite2D
	sprite.name = "Sprite2D"
	sprite.set_script(null)
	visual.add_child(sprite)
	var idle := player_origen.get_animation(ficha.animacion_idle).duplicate() as Animation
	# Se reutilizan textura, posición, escala, etc.; se excluyen pistas de colisión y métodos.
	for i in range(idle.get_track_count() - 1, -1, -1):
		var ruta := idle.track_get_path(i)
		if idle.track_get_type(i) != Animation.TYPE_VALUE or not str(ruta).begins_with(str(ficha.ruta_sprite) + ":"):
			idle.remove_track(i)
		else:
			idle.track_set_path(i, NodePath("Sprite2D:" + ruta.get_concatenated_subnames()))
	idle.loop_mode = Animation.LOOP_LINEAR
	var biblioteca := AnimationLibrary.new()
	biblioteca.add_animation(&"idle", idle)
	animacion = AnimationPlayer.new()
	visual.add_child(animacion)
	animacion.add_animation_library(&"", biblioteca)
	animacion.play(&"idle")
	animacion.advance(0.0)
	var limites := sprite.get_rect()
	if ficha.imagen is AtlasTexture:
		limites = Rect2(ficha.imagen.region.position + limites.position, ficha.imagen.region.size)
	var factor := minf(size.x / limites.size.x, size.y / limites.size.y)
	visual.scale = Vector2(-factor if espejo else factor, factor)
	visual.position = size * 0.5 - limites.get_center() * visual.scale
	origen.free()
