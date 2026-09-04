# Contexto de PoliFight

Última inspección: 2026-09-04.

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
- `polifight/scripts/personajes/personaje_base/personaje.gd`: clase `Personaje`, vida, daño, dirección, acceso a entrada por jugador y referencias a hitbox/hurtbox.
- `polifight/scripts/personajes/personaje_base/Maquina_estados.gd` y `Estado_base.gd`: despacho del ciclo de Godot al estado activo.
- `polifight/scripts/personajes/personaje_base/estados/`: estados implementados para reposo, caminar, saltar y puño.
- `polifight/scripts/personajes/personaje_base/hitbox.gd` y `hurtbox.gd`: transporte y recepción de golpes.

## Estado jugable observado

- Dos Barbieri aparecen enfrentados en el primer nivel.
- Movimiento horizontal, salto y puño están conectados a la máquina de estados.
- El puño activa/desactiva su forma de golpe mediante `AnimationPlayer`.
- Un golpe reduce `vida_actual`; llegar a cero solo imprime el mensaje de derrota.
- Existen arte y acciones de entrada para agacharse y patada, pero no estados de juego conectados para esas acciones.
- No se observan todavía HUD de vida/tiempo, controlador de partida, rondas, KO, victoria, reinicio ni selección de personaje.

## Controles configurados

| Acción | Jugador 1 | Jugador 2 |
|---|---|---|
| Izquierda | A | Flecha izquierda |
| Derecha | D | Flecha derecha |
| Salto | W | Flecha arriba |
| Agacharse | S | Flecha abajo |
| Puño / ataque | J | Tecla física configurada como `1` |
| Patada | K | Tecla física configurada como `2` |

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
- La orientación solo respeta la dirección inicial; todavía no se observa giro automático hacia el rival.
- Hay dos archivos temporales `nivelI.tscn*.tmp`. Tratarlos como posibles recuperaciones del editor: inspeccionarlos y pedir confirmación antes de eliminarlos.
- El `README.md` y el `InputMap` no están totalmente sincronizados.

## Parámetros todavía no decididos

No inventar como hechos: resolución interna definitiva de pixel art, cuadros por segundo de animación/combate, cantidad de rondas, duración, bloqueo, retroceso, hitstun, combos, roster, escenario final, audio, mandos, plataformas objetivo y clasificación por edad. Proponer alternativas con impacto jugable y técnico cuando alguna decisión sea necesaria.
