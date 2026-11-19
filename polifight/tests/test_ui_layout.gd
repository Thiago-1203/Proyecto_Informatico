extends SceneTree
## Tamaños lógicos resultantes de canvas_items + expand en 720p, ultrawide,
## 4:3 y teléfono vertical. Comprueba límites y foco real de cada pantalla.
const SIZES := [Vector2i(1920, 1080), Vector2i(2560, 1080), Vector2i(1920, 1440), Vector2i(1920, 4160)]
var fallos := 0

func _initialize() -> void:
	call_deferred("_probar")

func _comprobar(vp: SubViewport, ui: Node, foco: bool = true) -> void:
	await process_frame
	await process_frame
	var pantalla := Rect2(Vector2.ZERO, Vector2(vp.size)).grow(1)
	for node in ui.find_children("*", "Control", true, false):
		var c := node as Control
		if not c.is_visible_in_tree() or c.is_queued_for_deletion():
			continue
		var padre := c.get_parent()
		var en_scroll := false
		while padre != ui and padre != null:
			if padre is ScrollContainer:
				en_scroll = true
			padre = padre.get_parent()
		if not en_scroll and not pantalla.encloses(c.get_global_rect()):
			fallos += 1
			push_error("Fuera de pantalla %s a %s: %s" % [c.get_path(), vp.size, c.get_global_rect()])
	if foco and vp.gui_get_focus_owner() == null:
		fallos += 1
		push_error("Sin foco a %s" % vp.size)

func _probar() -> void:
	for tamano in SIZES:
		var vp := SubViewport.new()
		vp.size = tamano
		root.add_child(vp)
		var modos = load("res://escenas/menu/selector_modos.tscn").instantiate()
		vp.add_child(modos)
		await create_timer(0.7).timeout
		await _comprobar(vp, modos)
		modos.free()
		var tutorial = load("res://escenas/juego/tutorial.tscn").instantiate()
		vp.add_child(tutorial)
		await create_timer(0.2).timeout
		await _comprobar(vp, tutorial)
		tutorial._alternar_pausa()
		await _comprobar(vp, tutorial)
		tutorial._mostrar_controles()
		await _comprobar(vp, tutorial)
		tutorial.free()
		var selector = load("res://escenas/menu/selector_combate.tscn").instantiate()
		vp.add_child(selector)
		await selector.aparicion_finalizada
		await _comprobar(vp, selector)
		selector._confirmar_configuracion(1)
		await _comprobar(vp, selector)
		selector._confirmar_configuracion(1)
		await _comprobar(vp, selector)
		selector.listos.assign([true, true])
		selector._ir_escenarios()
		await selector.aparicion_finalizada
		await _comprobar(vp, selector)
		selector.free()
		var hud = load("res://escenas/ui/HUD.tscn").instantiate()
		vp.add_child(hud)
		await _comprobar(vp, hud, false)
		hud.free()
		var pausa = load("res://escenas/ui/menu_pausa.tscn").instantiate()
		vp.add_child(pausa)
		pausa.process_mode = Node.PROCESS_MODE_ALWAYS
		pausa.mostrar()
		await create_timer(0.3).timeout
		await _comprobar(vp, pausa)
		pausa.mostrar_controles()
		await _comprobar(vp, pausa)
		pausa.free()
		vp.free()
	print("UI LAYOUT: %d fallos" % fallos)
	quit(1 if fallos else 0)
