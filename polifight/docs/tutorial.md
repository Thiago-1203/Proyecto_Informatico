# Tutorial / Dojo

Se abre desde **Jugar → Tutorial** y vuelve al selector de modos. Ocho ejercicios
breves enseñan movimiento, salto, agacharse, puño, patada, bloqueo, recuperación
de stamina y carga/uso de la ulti. Barbieri es el aprendiz y Marco su compañero.

Cada ejercicio muestra una consigna y sus controles de teclado J1 y mando.
El progreso se comprueba con movimiento, estados e impactos reales; golpear
al aire no aprueba los ejercicios de ataque. La última lección carga la ulti
con cinco impactos antes de enseñar el botón para lanzarla.

**Enter / RB / R1** continúa u omite el paso. La práctica no avanza sola ni tiene
tiempo límite o KO. Al terminar permite seguir practicando libremente.
**Esc / Start** abre una pausa con continuar, controles, reiniciar y volver
a modos. La guía incluye las teclas de J1/J2 y equivalencias Xbox/PlayStation.
La guía es compartida con **Ver controles** en la pausa de todos los combates.
El botón A sigue siendo salto durante la práctica; no avanza lecciones.

El tutorial usa escenas y reglas de combate existentes. Su rival tiene un
controlador local que sólo ataca durante defensa, con daño cero y una espera
entre golpes. Los impactos conservan la carga de ulti y se restaura la vida.
La pausa congela personajes y proyectiles sin pausar el árbol global. No cambia
el catálogo, las elecciones del duelo, la IA normal ni `Engine.time_scale`.

La interfaz usa un lienzo 1920×1080 que se ajusta conservando proporciones.
Una cámara encuadra la práctica sin cambiar la física; la guía y el fondo usan
capas de interfaz independientes para que el salto quede visible.
El arte de la tarjeta Tutorial es geometría nativa, sin archivos generados.

Verificación:

```sh
godot --headless --path . --script res://tests/test_tutorial.gd
godot --headless --path . --script res://tests/test_ui_layout.gd
godot --headless --path . --script res://tests/test_mandos.gd
```
