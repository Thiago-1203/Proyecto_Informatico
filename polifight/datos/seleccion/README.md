# Selección de personajes y escenarios

El flujo es **JUGAR → 1 VS 1 → apertura de la puerta → selección simultánea → escenario → combate**.
La cinemática se reproduce antes de abrir la selección y no se repite al iniciar el combate.
La selección de personajes usa la misma textura negra de la oscuridad de la puerta.
La interfaz entra con un fundido y las vistas laterales se deslizan suavemente a su posición.
El primer escenario es **LA TERRAZA** y ocupa todo el fondo al pasar a escenarios;
cambiar su ficha actualiza el fondo. Al cambiar de paso también se aplica la aparición.

Al confirmar el mapa, `TransicionCombate` funde la selección a negro en 0.22 segundos,
carga la arena bajo esa cobertura y la revela con un fundido de 0.18 segundos.
Los luchadores permanecen inmóviles. Tras 0.1 segundos aparece brevemente **FIGTH**;
al retirarse el cartel se habilita la pelea. El fundido termina antes de mostrar el cartel.
El autoload permanece entre escenas. La pelea queda pausada durante la presentación;
los controles y la pausa se habilitan al retirar el cartel. Las duraciones de la
transición usan tiempo real y no cambian con `Engine.time_scale`.
El sprite transparente está en `assets/ui/combate/figth.png` y el prompt original en
`figth.prompt.txt`. Se generó con la herramienta integrada image_gen.

J1 navega con **WASD** y confirma con **F o Espacio**. J2 navega con **flechas** y
confirma con **Enter**. Cada jugador tiene su cursor, su foco y su botón **Listo**;
ambos pueden elegir el mismo personaje. Moverse a otro personaje cancela solamente
la confirmación de ese jugador. Al estar ambos listos, se habilita **Elegir escenario**.
Los mandos 0 y 1 también controlan sus respectivos cursores (cruceta/stick, A y B).

Arriba/abajo recorren la cuadrícula y los botones; izquierda/derecha recorren las casillas
y conectan las acciones inferiores. El borde y las marcas azules indican el foco de J1;
las doradas, el de J2. Esc vuelve. En escenarios cualquiera de los dos puede navegar.
Con mouse, clic izquierdo elige para J1 y clic derecho para J2; los botones Listo son
independientes. En escenarios cualquiera de los dos clics cambia la selección compartida.

Cada cuadrícula agrega una casilla **PROXIMAMENTE** al final del catálogo. Puede recibir
el cursor, pero no se puede confirmar como personaje ni escenario.

## Agregar un personaje

1. Crear una escena que herede de `Personaje` con el mismo contrato de nodos y estados
   que `escenas/personajes/barbieri.tscn`. Configurar sus ataques, animaciones y estadísticas.
2. Duplicar `personajes/barbieri.tres` en Godot y asignar un `id` único, nombre,
   subtítulo, descripción, imagen y ruta de la escena. La imagen puede ser una
   `AtlasTexture` para recortar el espacio transparente del sprite.
3. Abrir `datos/seleccion/catalogo.tres` y arrastrar la ficha al array **Personajes**.
   Su posición en el array determina el orden del menú. Aparece automáticamente.

## Agregar un escenario

1. Crear una escena heredada de `escenas/juego/nivelI.tscn`, conservando el controlador
   de combate, HUD, pausa, límites y suelo; reemplazar el fondo y la geometría.
2. Mover los `Marker2D` **AparicionJ1** y **AparicionJ2**. El controlador instancia los
   personajes elegidos en esos puntos y asigna número de jugador, orientación y oponente.
   También permite configurar rutas alternativas a los puntos desde el inspector.
3. Duplicar `escenarios/terraza.tres`, cambiar `id`, textos, imagen y ruta de escena;
   agregar la ficha al array **Escenarios** de `catalogo.tres`.

No hace falta modificar el menú ni el controlador al agregar contenido.
`disponible = false` oculta una ficha. El catálogo omite entradas nulas, duplicadas,
sin nombre o sin una escena existente y muestra un aviso en la consola.
Solo las vistas laterales reproducen las pistas visuales del idle de su escena real.
Los retratos de la cuadrícula central son estáticos.
`VistaPreviaPersonaje` extrae el Sprite2D y copia solamente las pistas visuales de
AnimationPlayer; no agrega cuerpos físicos, hitboxes, estados ni controles al menú.
Las vistas grandes se conservan al navegar para que el idle no se reinicie.
En la ficha pueden configurarse `ruta_sprite`, `ruta_animacion` y `animacion_idle`.
El contrato por defecto es Sprite2D, AnimationPlayer y la animación `idle`.
La imagen de la ficha sirve para definir el encuadre si es una AtlasTexture;
también se utiliza como retrato estático en la cuadrícula central. Los escenarios usan
su imagen como fondo.
La cuadrícula tiene desplazamiento para catálogos grandes.

Las cards laterales muestran **daño de ataque** y **stamina máxima** de la escena
seleccionada, mediante `FichaSeleccion.obtener_estadisticas()`. Se instancian fuera
del árbol y se leen `danio` y `stamina_maxima`, sin ejecutar lógica de combate.
Los datos se guardan en caché por ruta de escena; no se duplican valores en el catálogo.
Los atributos aparecen como dos barras apiladas con su número real. Cada barra usa
como escala el mayor valor de ese atributo dentro del catálogo disponible, para
comparar personajes; no representa vida o stamina gastada durante una partida.
Una casilla vacía muestra guiones en lugar de conservar las estadísticas anteriores.

`SeleccionPartida` conserva las fichas elegidas entre escenas y al reiniciar desde pausa.
Abrir un nuevo selector inicia las dos elecciones desde el primer personaje disponible.
Ejecutar un nivel directamente también usa ese personaje para los dos jugadores.

## Verificación

```sh
godot --headless --path . --log-file /tmp/polifight-seleccion.log --script res://tests/test_seleccion.gd
godot --headless --path . --log-file /tmp/polifight-patada.log --script res://tests/test_patada.gd
```

La prueba de selección agrega contenido temporal fuera del catálogo del juego y comprueba
orden de la cinemática, cursores simultáneos, foco de botones, fondo negro, entrada gradual, idle lateral y retrato central estático,
estadísticas iguales a las de combate, transición al mapa, bloqueo de entradas
durante FIGTH y recuperación del combate,
casillas vacías, navegación, volver, mouse, carga de otro nivel e instanciación de un
personaje con estadísticas distintas, reinicio y regreso al menú. Para generar capturas,
ejecutarla con pantalla, sin `--headless`, agregando `-- --capturas` al final.
