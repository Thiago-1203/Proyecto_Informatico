# Polifight Guion de exposición

Duración total: **15 minutos**, con **4 minutos de demostración en vivo**. El PowerPoint incluye notas del orador. Este documento sirve para ensayar y coordinar los cambios de pantalla.

## Distribución del tiempo

| Diapositiva | Tema | Tiempo | Reloj acumulado |
| --- | --- | --- | --- |
| 1 | Presentación | 45 s | 00:00–00:45 |
| 2 | Descripción del proyecto | 1 min | 00:45–01:45 |
| 3 | Mecánicas de combate | 1 min 15 s | 01:45–03:00 |
| 4 | Tecnologías utilizadas | 1 min 15 s | 03:00–04:15 |
| 5 | Historial del desarrollo | 1 min 30 s | 04:15–05:45 |
| 6 | Evolución de la interfaz | 45 s | 05:45–06:30 |
| 7 | División de tareas | 1 min 15 s | 06:30–07:45 |
| 8 | Errores y ajustes | 1 min 15 s | 07:45–09:00 |
| 9 | Demo en vivo | 4 min | 09:00–13:00 |
| 10 | Resultados y próximos pasos | 1 min | 13:00–14:00 |
| 11 | Preguntas | 1 min | 14:00–15:00 |

## Qué decir en cada diapositiva

### 1 Presentación

“Somos el equipo de Polifight. Desarrollamos un videojuego de combate en dos dimensiones, con estética pixel art y una ambientación vinculada al colegio. Vamos a explicar cómo funciona, cómo avanzamos desde el primer prototipo y qué problemas tuvimos que resolver. Después vamos a jugar en vivo para mostrar las mecánicas.”

### 2 Descripción del proyecto

“Polifight permite enfrentar a dos personas en la misma computadora o jugar contra un rival controlado por IA. Tenemos dos personajes, Barbieri y Marco, y cuatro escenarios: La Terraza, El Kiosko, El Escenario y El Poli. También incorporamos un tutorial de ocho ejercicios para aprender a jugar. El duelo y el tutorial están disponibles. Historia y 2 vs 2 aparecen como próximos desarrollos.”

### 3 Mecánicas de combate

“El jugador puede moverse, saltar, agacharse, golpear, patear y bloquear. El objetivo es reducir la vida del rival hasta el KO. La stamina regula la defensa: bloquear impactos consume esa reserva y después hay que recuperarla. Los golpes que causan daño también cargan el ataque especial. Barbieri tiene más daño base y Marco tiene más stamina. Sus especiales son distintos: uno lanza proyectiles de código y el otro invoca nombres de tipografías.”

### 4 Tecnologías utilizadas

“Usamos Godot como motor y GDScript para programar. Organizamos las acciones de los personajes con una máquina de estados: caminar, saltar, atacar o bloquear son estados con reglas de entrada y salida. La clase base reúne las reglas compartidas y cada personaje agrega sus particularidades. Para generar y preparar los sprites utilizamos PixelLab, SpriteFlow y LibreSprite. Git nos permitió conservar versiones. Los videos que incluimos en el informe fueron nuestras referencias de aprendizaje.”

### 5 Historial del desarrollo

“Comenzamos en agosto con el primer personaje, el menú y el movimiento básico. Después incorporamos dos jugadores. En septiembre sumamos vida, bloqueo, KO, pausa, victoria y stamina. En octubre agregamos y ajustamos acciones como la patada y la caminata agachada, y construimos la selección de modos, personajes y escenarios. En noviembre incorporamos la IA, mejoramos la interfaz y los mandos, e integramos el segundo personaje y el tutorial. Conservamos 26 commits que permiten consultar esos avances.”

### 6 Evolución de la interfaz

“Esta comparación muestra una captura real que conservamos de octubre y el selector actual. En la versión anterior el duelo era local y no aparecía el tutorial. La versión actual permite elegir un rival humano o IA y agrega el acceso a la práctica. La comparación muestra cómo el desarrollo fue ampliando las posibilidades del juego.”

### 7 División de tareas

“Dividimos el trabajo en cuatro áreas. Agustín Valledor se encargó del código del videojuego. Thiago Andreoli realizó las animaciones de los personajes. Lucca Rossatti diseñó los personajes junto con sus movimientos. Facundo Feistel diseñó los mapas y la interfaz de usuario. La integración requirió coordinar el aspecto visual con el funcionamiento de cada mecánica.”

### 8 Errores y ajustes

“Uno de los desafíos fue coordinar las animaciones con las zonas de impacto para aplicar el daño en el momento correcto. También ajustamos la postura agachada y el regreso al movimiento. En la interfaz corregimos proporciones y legibilidad. En los controles trabajamos las confirmaciones duplicadas entre pantallas. En la revisión de esta versión, las pruebas de tutorial e IA pasaron. La prueba de selección detectó que la entrada al combate excedió el límite de tiempo previsto, por lo que esa medición queda pendiente de revisión.”

### 9 Demostración en vivo

“Ahora vamos a mostrar el recorrido completo y las mecánicas principales. Mientras una persona juega, otra explica qué está ocurriendo.”

Cambiar con **Alt+Tab** al juego que debe estar abierto antes de comenzar. La diapositiva reserva el bloque de exposición y **no contiene un juego incrustado**.

| Tiempo de demo | Acción | Qué explicar |
| --- | --- | --- |
| 00:00–00:45 | Elegir 1 vs 1, rival humano, Barbieri y Marco, y La Terraza | Elección independiente de personajes y escenario compartido |
| 00:45–01:45 | Moverse, saltar, agacharse, dar un puño y una patada | Relación entre acción, animación y daño |
| 01:45–02:30 | Un jugador bloquea y el otro golpea | Consumo de stamina y recuperación al dejar de bloquear |
| 02:30–03:15 | Acertar cinco golpes que causen daño, lanzar la ulti y abrir pausa | Carga especial, ataque propio del personaje y guía de controles |
| 03:15–04:00 | Volver a modos, entrar al tutorial y realizar un ejercicio | Aprendizaje mediante acciones reales y práctica sin KO |

Ensayar la secuencia sin intentar ganar una partida completa. Para cargar la ulti, el rival debe recibir daño: bloquear los cinco golpes no cumple ese objetivo. Si la navegación ocupa demasiado tiempo, priorizar el combate y sus recursos. Volver a la presentación al llegar al minuto 13.

### 10 Resultados y próximos pasos

“El resultado es una versión jugable con duelo local o contra la computadora, dos personajes, cuatro escenarios y un tutorial. Aprendimos a integrar entrada, movimiento, animación, colisiones e interfaz. Para continuar, corresponde revisar el tiempo de entrada al combate, seguir probando el equilibrio de los personajes y ampliar el contenido. Historia y 2 vs 2 siguen pendientes.”

### 11 Preguntas

“Gracias. Abrimos el espacio de preguntas.”

Si consultan por la IA: decide acciones mediante reglas, distancias, probabilidades y tiempos de reacción. No ejecuta un modelo generativo durante la partida.

Si consultan por versiones antiguas: mostrar la cronología y los identificadores de commits del informe.

## Preparación de la demo

1. Abrir el proyecto y ejecutar la escena principal con **F5** desde Godot antes de iniciar la exposición.
2. Dejar la portada lista y abrir el PowerPoint en modo presentación.
3. Probar el cambio con Alt+Tab y confirmar que el juego recibe el foco.
4. Distribuir dos puestos de juego y una persona que explique. El cuarto integrante puede controlar el tiempo y el cambio entre el juego y la presentación.
5. Verificar el teclado o los mandos que usarán. Si J2 bloquea con teclado numérico, probar esa tecla en el equipo de la exposición.
6. Ensayar una vez con cronómetro, especialmente la carga del especial y el regreso al tutorial.

### Controles para el ensayo

| Acción | Jugador 1 | Jugador 2 |
| --- | --- | --- |
| Movimiento | A / D | Flechas izquierda / derecha |
| Saltar | W | Flecha arriba |
| Agacharse | S | Flecha abajo |
| Puño | J | 1 o teclado numérico 1 |
| Patada | K | 2 o teclado numérico 2 |
| Especial | L | 3 |
| Bloquear | H | Teclado numérico 3 |
| Pausa | Esc | Esc |

En la selección de personajes, J1 navega con WASD y confirma con F o Espacio. J2 navega con las flechas y confirma con Enter. Ambos deben confirmar para continuar. Consultar la guía del propio juego si se usa un mando.

## Alternativa si la demo se interrumpe

Usar las capturas del informe para explicar la elección de personajes, el HUD y el tutorial. Mostrar `capturas/especial_marco.png` si hace falta ilustrar el especial. Indicar que son capturas de ejecución conservadas en el proyecto. Reservar el último minuto para cerrar y evitar consumir todo el tiempo intentando reiniciar.
