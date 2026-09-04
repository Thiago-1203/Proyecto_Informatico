# Hoja de ruta orientativa

Usar esta secuencia para recomendar el siguiente incremento, pero adaptarla a la prioridad explícita del equipo. Cada etapa debe terminar en algo jugable y verificable.

## 1. Consolidar el prototipo de combate

- Elegir una única composición base de personaje y eliminar la divergencia futura entre escenas.
- Corregir el despacho de eventos de la máquina de estados.
- Completar orientación hacia el oponente y límites del escenario.
- Validar que cada ataque impacte una vez y que sus hitboxes terminen desactivadas.
- Sincronizar controles y documentación.

Criterio de salida: dos jugadores pueden moverse, saltar y golpearse repetidamente sin estados bloqueados, autogolpes ni impactos fantasma.

## 2. Crear el bucle mínimo de partida

- Añadir señales claras de vida y derrota.
- Incorporar HUD, KO, reinicio y victoria de una ronda.
- Añadir un controlador de combate que sea la fuente de verdad para inicio, pausa y final.

Criterio de salida: una partida se puede iniciar desde el menú, jugar hasta una victoria y volver a jugar sin reiniciar el editor.

## 3. Completar el conjunto básico de acciones

- Implementar agacharse y patada usando los recursos existentes.
- Definir hitstun, retroceso y bloqueo solo después de acordar su comportamiento.
- Añadir feedback temporal de impacto, sonido y una depuración opcional de cajas.

Criterio de salida: todas las acciones documentadas responden para ambos jugadores y tienen ventanas/timing ajustables.

## 4. Escalar contenido sin duplicación

- Definir qué datos y escenas forman un luchador reutilizable.
- Crear un segundo personaje realmente distinto y un escenario coherente.
- Agregar selección de personaje cuando haya al menos dos opciones útiles.

Criterio de salida: agregar un luchador nuevo no exige copiar y modificar toda la lógica común.

## 5. Pulido y entrega

- Ajustar balance mediante pruebas registradas, no solo sensaciones aisladas.
- Añadir configuración de audio, controles y pausa.
- Probar relación de aspecto, rendimiento y exportaciones en las plataformas elegidas.
- Revisar licencias, créditos y consentimiento de personas representadas.

Criterio de salida: existe una build reproducible, probada por terceros y con instrucciones de ejecución.
