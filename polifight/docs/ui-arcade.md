# UI arcade de PoliFight

Dirección elegida: composición de selección de Mortal Kombat II, color y energía de Street Fighter II, con el colegio y los personajes propios de PoliFight.

## Sistema visual

- Base lógica 1920 × 1080, escalada y centrada para conservar la composición de pelea. Los formatos verticales mantienen la misma composición; no se ha diseñado una experiencia táctil.
- Fondo escolar oscuro, mampostería lateral y piso en perspectiva. Los elementos decorativos se recortan dentro del lienzo.
- Letras 5 × 7, paleta azul marino, blanco cálido, celeste para J1 y dorado para J2/IA y confirmación.
- Selección de luchadores: retratos al centro, personajes animados enfrentados a los lados, nombres y confirmación. Sin estadísticas visibles.
- Rival y dificultad: filas compactas con cursor, borde activo y una explicación breve de la opción seleccionada.
- Menú principal y barras de combate originales conservados. Las flechas de JUGAR/SALIR mantienen su animación original.

## Movimiento

- Entrada de modos escalonada; selección se eleva 20 unidades en 180 ms.
- Ilustración activa flota 5 unidades; flechas se desplazan 3–5 unidades.
- Cambio de configuración con entrada lateral de 180–240 ms.
- Retratos seleccionados: pulso lento del borde, con período de 1,3 s.
- Confirmar luchador: tinte dorado que vuelve al color original en 220 ms.
- Vistas laterales: animación idle real del personaje, sin lógica de combate.
- Pausa: entrada de 200 ms; sus animaciones siguen funcionando con el juego pausado.

Los tweens pertenecen a sus controles y se liberan con ellos al cambiar de pantalla. Los textos permanecen estables y no hay destellos a pantalla completa.

## Procedencia

No se incorporaron imágenes, fuentes o packs externos ni se generaron nuevos recursos raster.

- `scripts/ui/fuente_arcade.gd`: alfabeto del propio proyecto recuperado de `007c206`, ampliado con símbolos de navegación. Hereda las condiciones del repositorio.
- `scripts/menu/estilo_arcade.gd`: marcos geométricos dibujados con la API nativa de Godot.
- Fondo, logo, ilustraciones de modos y sprites: recursos existentes del proyecto, reutilizados sin modificar sus archivos.
- `texto_arcade.gd` y `boton_arcade.gd` separan el estilo de preparación de los controles originales del menú principal y HUD.

## Verificación

Godot 4.7.1:

- `--headless --path . --script res://tests/test_ui_menus.gd`: 0 fallos.
- `--headless --path . --script res://tests/test_seleccion.gd`: 0 fallos.
- `--headless --path . --script res://tests/test_ui_layout.gd`: 0 fallos. Comprueba límites y foco a tamaños lógicos 1920×1080, 2560×1080, 1920×1440 y 1920×4160.
- Capturas revisadas con OpenGL; 720p, ultrawide y vertical. Para resoluciones mayores que el monitor se usan SubViewports a tamaño exacto.
- Falta el recorrido con un mando físico; las pruebas ejercitan navegación y selección en el motor.

## Victoria y entrada al colegio

La cinemática de la puerta se reproduce al confirmar JUGAR en el menú principal. Al finalizar aparece el selector de modos; elegir 1 VS 1 abre directamente la selección de rival. Durante la puerta se bloquean las entradas y los intentos de abrirla otra vez.

El resultado muestra un K.O. breve, el ganador con su animación de celebración real, rayos y un medallón dibujados con Godot. Los botones REVANCHA y MENU PRINCIPAL usan el mismo estilo arcade y el foco de mando. La confirmación espera a soltar cualquier botón mantenido al aparecer. B/Escape enfoca MENU PRINCIPAL y A/Enter confirma. La pausa no se superpone al resultado.

La revancha conserva la selección actual; el regreso al menú vuelve a mostrar JUGAR. Las barras conservan su arte durante el combate y se ocultan al presentar el resultado.

Verificación adicional: `tests/test_victoria_entrada.gd` (37 comprobaciones, 0 fallos), selección (0 fallos), IA (0 fallos), mandos (39 comprobaciones, 0 fallos). No se incorporan imágenes externas: la celebración reutiliza el sprite del ganador y el fondo del resultado usa geometría nativa.
