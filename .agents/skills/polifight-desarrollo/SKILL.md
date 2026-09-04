---
name: polifight-desarrollo
description: Guiar, diseñar, implementar y revisar la evolución de PoliFight, el juego de lucha 2D pixel art en Godot de este repositorio. Usar cuando se trabaje en combate, personajes, estados, animaciones, escenarios, interfaz, balance, pruebas o planificación del proyecto; no aplicar a otros proyectos Godot.
---

# Desarrollo de PoliFight

Trabajar como diseñador y programador de juegos de lucha, manteniendo el proyecto comprensible para un equipo estudiantil. Comunicarse en español salvo que el usuario pida otro idioma.

## Antes de proponer o modificar

1. Confirmar la raíz real del juego (`polifight/project.godot`) y revisar el estado de Git. No asumir que este documento refleja cambios posteriores.
2. Leer [references/contexto-proyecto.md](references/contexto-proyecto.md). Contrastar su sección «Estado observado» con los archivos actuales y actualizarla si quedó desfasada.
3. Si la petición trata prioridades, alcance o siguiente funcionalidad, leer también [references/hoja-de-ruta.md](references/hoja-de-ruta.md).
4. Revisar las escenas, scripts y recursos directamente implicados antes de sugerir una solución. Preservar cambios ajenos y no tocar archivos `.import` ni `.godot/` manualmente.

## Forma de trabajo

- Empezar por el resultado jugable buscado y dividirlo en el incremento vertical más pequeño que se pueda probar.
- Explicar al equipo, paso por paso, qué se cambiará, para qué sirve cada cambio y cómo verificarlo. Cuando se implemente, cerrar con archivos modificados, resultado de pruebas y pasos manuales exactos en el editor si fueran necesarios.
- Distinguir siempre entre: comportamiento observado, problema comprobado, recomendación y decisión pendiente del equipo.
- No ampliar el alcance sin permiso. Una solicitud de diagnóstico o planificación no autoriza modificar el juego.
- Favorecer GDScript tipado, nombres coherentes con el código existente y componentes reutilizables. Evitar una gran reescritura si una mejora incremental consolida la base actual.
- Mantener la lógica común en `Personaje` o componentes compartidos y las diferencias de cada luchador en su escena/script/datos. Antes de editar, comprobar cuál escena de personaje es la fuente canónica, porque actualmente existen `personaje_base.tscn` y `barbieri.tscn` con contenido parcialmente duplicado.

## Criterios del combate

- Tratar entrada, simulación, presentación y reglas de ronda como responsabilidades separadas.
- Expresar controles mediante acciones del `InputMap` y el número de jugador; no consultar teclas físicas desde los estados.
- Hacer explícitas las fases de cada ataque: preparación, cuadros activos y recuperación. Activar hitboxes solamente durante los cuadros activos y garantizar como regla normal un solo impacto por objetivo y por ejecución.
- Conservar hurtboxes, hitboxes y colisión corporal como conceptos distintos. Revisar capas, máscaras, orientación y estado habilitado al agregar un ataque.
- Mantener la simulación de movimiento en `_physics_process`. Las transiciones deben dejar el estado anterior limpio: señales desconectadas, hitboxes apagadas y valores temporales restaurados.
- No confundir animación con lógica: `AnimationPlayer` puede sincronizar sprites y ventanas de golpe, pero vida, KO, ronda y victoria deben tener una fuente de verdad independiente.
- Priorizar legibilidad y respuesta: controles consistentes, feedback claro al impacto y valores ajustables. Medir y documentar tiempos antes de hablar de balance competitivo.

## Arte y temática escolar

- Respetar el pixel art: escalado entero cuando sea posible, filtrado desactivado para sprites pixelados, siluetas legibles y resolución/escala coherentes entre personajes.
- Mantener una identidad escolar humorística sin humillar ni acosar. Si los personajes representan personas reales, señalar la necesidad de consentimiento para usar nombres, imagen, voz o rasgos identificables antes de publicar.
- Reutilizar el arte existente antes de generar reemplazos. No inventar sprites finales cuando falten recursos: ofrecer un placeholder claramente identificado o pedir la dirección artística necesaria.

## Verificación proporcional

- Ejecutar las comprobaciones disponibles de Godot 4.7, preferentemente importación/arranque sin interfaz y detección de errores de GDScript. Si el binario no está disponible, decirlo y dar una prueba manual reproducible.
- Probar ambos jugadores y las transiciones de entrada relevantes. Para combate, verificar al menos: sin autogolpe, un impacto esperado, orientación izquierda/derecha, fin del ataque y retorno a un estado válido.
- No declarar terminada una función solo porque compila: indicar qué comportamiento jugable fue observado y qué sigue requiriendo validación en el editor.

## Actualización del conocimiento

Después de un cambio que altere arquitectura, controles, funcionalidades implementadas o deuda técnica relevante, actualizar únicamente los datos afectados de `references/contexto-proyecto.md`. Cambiar la hoja de ruta solo cuando el equipo tome una decisión de alcance o una etapa se complete.
