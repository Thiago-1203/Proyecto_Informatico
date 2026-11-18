# Mandos

El menú principal y la pausa usan `ui_accept` / `ui_cancel`, ahora con botón inferior y derecho además del teclado. El selector conserva sus dos cursores y consume los eventos que procesa para evitar que la GUI confirme o navegue dos veces.

`EntradaMandos` asigna los IDs de dispositivo disponibles a J1/J2. El mando que abre JUGAR ocupa J1. La desconexión libera sus acciones y conserva el puesto del otro jugador; al reconectar se reemplazan las asignaciones del dispositivo anterior. Se mantienen las teclas originales.

Godot 4.7 usa el mapeo de SDL para normalizar los dispositivos reconocidos. No se sobrescribe su base de modelos con mapas genéricos que puedan confundir botones. Un dispositivo no reconocido por el motor puede requerir su propio mapa SDL: [documentación oficial](https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html).

## Controles predeterminados

Los nombres A/B/X/Y corresponden a la distribución Xbox; en otras marcas se usan las posiciones equivalentes.

| Acción | Control |
| --- | --- |
| Menús | Cruceta o stick izquierdo |
| Confirmar | Inferior: A en Xbox, cruz en PlayStation |
| Volver | Derecho: B en Xbox, círculo en PlayStation |
| Moverse / saltar / agacharse | Cruceta o stick izquierdo |
| Saltar | Botón inferior (A) |
| Puño | Botón izquierdo (X) |
| Patada | Botón derecho (B) |
| Especial | Botón superior (Y) |
| Bloquear | LB o gatillo izquierdo |
| Pausa | START / Menu / Options |

Hay dos puestos de combate. Contra la IA, un mismo mando elige y confirma los dos personajes. En duelo local, cada mando mueve su propio cursor.

## Verificación

`Godot --headless --path . --script res://tests/test_mandos.gd`

Ejercita el Button real de JUGAR con A, navegación por menús, entrada mantenida, cursores independientes, acciones de combate, zona muerta, pausa y reconexión con IDs distintos de 0 y 1. El Xbox 360 conectado fue identificado por Godot como dispositivo conocido; la suite inyecta eventos y no sustituye una prueba física de todos los modelos.

Para cargar los nuevos autoloads y el Input Map hay que detener y volver a ejecutar el proyecto.
