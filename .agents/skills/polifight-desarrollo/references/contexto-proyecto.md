# Contexto de PoliFight

Última inspección: 2026-09-28.

## Visión del producto

PoliFight es un juego de lucha 2D local con estética pixel art, inspirado en la claridad y el ritmo de los arcades clásicos y ambientado en un colegio. Sus luchadores pertenecen al entorno escolar. La referencia a otros juegos describe el género; no autoriza copiar personajes, arte, audio, escenarios ni marcas.

El alcance confirmado hoy es multijugador local para dos personas. No asumir red, IA, modo historia ni plataforma de publicación hasta que el equipo lo decida.

## Ubicación y tecnología

- Repositorio: directorio que contiene esta skill.
- Proyecto Godot: `polifight/project.godot`.
- Motor configurado: Godot 4.7, renderer GL Compatibility.
- Lenguaje actual: GDScript.
- Escena principal: `res://escenas/menu/menu.tscn`.
- Resolución de viewport: 1920 × 1080; modo de ventana configurado en pantalla completa y estiramiento `canvas_items` con aspecto `expand`.

## Estructura observada

- `polifight/escenas/menu/menu.tscn`: menú con JUGAR y SALIR.
- `polifight/escenas/juego/nivelI.tscn`: fondo, piso y dos instancias de Barbieri.
- `polifight/escenas/personajes/barbieri.tscn`: personaje actualmente jugable, animaciones, colisiones y máquina de estados.
- `polifight/escenas/personajes/personaje_base.tscn`: otra composición base similar; puede divergir de Barbieri y aún no debe asumirse como fuente canónica.
- `polifight/escenas/ui/menu_pausa.tscn` y `scripts/ui/menu_pausa.gd`: interfaz de pausa reutilizable que solicita continuar, reiniciar o volver al menú sin asumir las reglas del nivel.
- `polifight/scripts/juego/gestor_pausa.gd`: único nodo del combate que procesa siempre; escucha Escape y administra la pausa y navegación sin hacer que los luchadores hereden ese modo.
- `polifight/scripts/personajes/personaje_base/personaje.gd`: clase `Personaje`, vida, stamina, daño, seguimiento del oponente, acceso a entrada por jugador y referencias a hitbox/hurtbox.
- `polifight/scripts/personajes/personaje_base/Maquina_estados.gd` y `Estado_base.gd`: despacho del ciclo de Godot al estado activo.
- `polifight/scripts/personajes/personaje_base/estados/`: estados implementados para reposo, caminar, saltar, agacharse, puño, bloqueo y reacción al golpe.
- `polifight/scripts/personajes/personaje_base/hitbox.gd` y `hurtbox.gd`: transporte y recepción de golpes.
- `polifight/escenas/ui/HUD.tscn` y `scripts/ui/hud.gd`: HUD con barras de vida y stamina conectadas a ambos personajes; las barras de ulti son todavía visuales.
- `polifight/scripts/ui/fuente_pixel.gd` y `texto_pixel.gd`: alfabeto 5×7 reutilizable para textos y botones pixelados sin depender de fuentes externas ni del orden de registro de clases globales.

## Estado jugable observado

- Dos Barbieri aparecen enfrentados en el primer nivel.
- Cada luchador lleva sobre su cabeza un triángulo pixelado pequeño que apunta hacia abajo y lo sigue: naranja para el jugador 1 y azul para el jugador 2.
- Cada luchador actualiza su orientación horizontal para mirar al oponente cuando intercambian posiciones.
- Movimiento horizontal, salto, agacharse, puño y bloqueo están conectados a la máquina de estados.
- El puño activa/desactiva su forma de golpe mediante `AnimationPlayer`.
- Mantener la acción de bloqueo en el suelo evita el daño mientras haya stamina suficiente. Cada golpe bloqueado consume stamina y aplica un retroceso menor que un impacto directo; al soltar el bloqueo o agotar la stamina después del retroceso, la stamina se recupera con el tiempo. Si llega a cero, el bloqueo permanece deshabilitado hasta recuperar por defecto el 60 % de la barra.
- Un golpe no bloqueado reduce `vida_actual`, entra en `RecibirGolpe` durante la animación y luego retorna a un estado válido.
- Cada golpe no bloqueado aplica un retroceso horizontal breve en dirección opuesta al atacante; sus magnitudes y frenado son configurables desde `Personaje` para reutilizarlos entre luchadores.
- Al llegar a cero vida, el golpe final lanza al luchador hacia atrás y hacia arriba. El estado terminal `KO` desactiva ataque y recepción, reproduce su animación a velocidad reducida, aplica caída, un rebote contra el piso y conserva la pose final.
- Un shader compartido mezcla temporalmente los píxeles visibles del luchador con el color de impacto sin alterar su transparencia. Cada golpe no bloqueado y cada ruptura de defensa usan el mismo destello rojo intenso; el color y la duración son configurables desde `Personaje` y un nuevo impacto reinicia el tween.
- Cada bloqueo exitoso que no rompe la defensa produce con el mismo shader un destello blanco visible, configurable desde `Personaje`.
- Existe un HUD de vida y stamina para ambos jugadores y un controlador que lo conecta a las señales de los personajes.
- Cuando un luchador llega a cero vida, el controlador determina al oponente ganador, pero espera la señal de finalización de la secuencia física de KO antes de mostrar la placa pixelada compacta `JUGADOR 1/2 GANA`; no hay oscurecimiento global y se mantiene el ciclo cromático rojo, dorado y azul.
- El combate usa una escala de tiempo configurable de `0.8` por defecto y restaura la velocidad anterior al abandonar el nivel; el menú no queda ralentizado.
- Escape alterna una pausa real del árbol de escenas: los luchadores y la simulación dejan de procesar, mientras solo el gestor y la interfaz siguen activos. El menú permite continuar, recargar la pelea completa o regresar al menú principal; todas las salidas restauran pausa y escala temporal.
- Existen arte y acciones de entrada para patada, pero todavía no hay un estado de juego conectado para esa acción.
- No se observan todavía tiempo de combate, rondas ni selección de personaje.

## Controles configurados

| Acción | Jugador 1 | Jugador 2 |
|---|---|---|
| Izquierda | A | Flecha izquierda |
| Derecha | D | Flecha derecha |
| Salto | W | Flecha arriba |
| Agacharse | S | Flecha abajo |
| Puño / ataque | J | Tecla física configurada como `1` |
| Patada | K | Tecla física configurada como `2` |
| Bloqueo | H | Tecla física configurada como `3` |
| Pausa | Escape | Escape |

Confirmar los eventos del jugador 2 dentro de Godot en el sistema operativo objetivo: sus ataques figuran asociados al dispositivo 16, algo que puede afectar su detección. El `README.md` aún no documenta patada y dice que agacharse no está incluido.

## Capas de física

1. Mundo
2. Personajes
3. Hitboxes
4. Hurtboxes

Las escenas actuales usan la capa 2 para el cuerpo, la 3 para golpe y la 4 para recepción. Antes de cambiar colisiones, razonar en nombres de capa y comprobar tanto `collision_layer` como `collision_mask`.

## Riesgos y deuda visibles

- La escena base y la de Barbieri duplican estructura y animaciones, con diferencias en sus tiempos; decidir una fuente canónica antes de sumar luchadores.
- `_unhandled_input` llama a `on_unhadled_input`, con una errata que rompería ese callback si un estado intentara usarlo.
- `_unhandled_key_input` no reenvía el evento al estado.
- No existe una política explícita para impedir golpes repetidos del mismo ataque si las áreas vuelven a entrar.
- Hay dos archivos temporales `nivelI.tscn*.tmp`. Tratarlos como posibles recuperaciones del editor: inspeccionarlos y pedir confirmación antes de eliminarlos.
- El `README.md` y el `InputMap` no están totalmente sincronizados.

## Parámetros todavía no decididos

No inventar como hechos: resolución interna definitiva de pixel art, cuadros por segundo de animación/combate, cantidad de rondas, duración, bloqueo direccional o daño reducido, duración ajustable del hitstun, combos, roster, escenario final, audio, mandos, plataformas objetivo y clasificación por edad. Proponer alternativas con impacto jugable y técnico cuando alguna decisión sea necesaria.
