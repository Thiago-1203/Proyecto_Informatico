# Ulti de Marco: lluvia de nombres de tipografías

**J1: L. J2: 3.** Requiere la carga completa y estar en el suelo, quieto,
caminando o agachado. Cinco golpes acertados cargan la barra (20 puntos cada uno).
Esperar, fallar, bloquear o impactar con la propia lluvia no la recargan.

Marco abre las manos, levanta ambos brazos y mira hacia arriba. Mantiene las palmas
en alto durante la invocación y luego baja los brazos hasta recuperar la guardia.
Seis poses nuevas de 512 × 512, mismo tamaño, paleta y apoyo que sus otros sprites.
La animación `ulti` de `escenas/personajes/marco.tscn` dura 2,75 segundos.

Invoca cuatro oleadas a los 0,65 / 1,20 / 1,75 / 2,30 segundos: tres nombres por
oleada, una sobre la posición del rival y otras a 220 unidades de cada lado.
Cada posición se fija al invocar; los nombres caen verticalmente y se pueden esquivar.
No dependen de la dirección en que mire Marco ni se reflejan al usarlas como J2.
Cada proyectil hace 6 de daño una sola vez; un rival quieto recibe los cuatro centrales
(24 en total). Los carriles laterales cubren desplazamientos.

Caen los nombres **Arial**, **Times New Roman** y **Sans Serif**,
con sus fuentes empaquetadas con el proyecto. Sans Serif usa DejaVu Sans Bold.
Se dibujan en Godot con relleno negro y contorno claro,
rotados 90° para leerse de arriba hacia abajo y dispersión al impactar.
Bajan a 400 unidades por segundo (un tercio más lento que a 600),
con 100 unidades de separación vertical entre carriles y sin copias de texto en
la estela, para que las palabras se puedan leer. Los nombres usan un tamaño de fuente
de hasta 64 píxeles, con un máximo de 600 píxeles de largo (antes 30–36 y 300).
Las oleadas se separan 0,55 segundos y alternan sus columnas con un desfase de 88
unidades para que los nombres verticales no se superpongan. El núcleo de impacto es de 64 × 72 para conservar el alcance
del ataque aunque el texto ocupe más espacio que las letras sueltas anteriores.
Times New Roman, el nombre más largo, alterna tres columnas. La vida máxima de cada
proyectil es de 5 segundos para completar la caída a esta velocidad.

Arial Bold y Times New Roman Regular provienen de las versiones compatibles de
Proton Experimental, con licencia SIL OFL incluida en
`assets/fonts/tipografias_marco/LICENSE-Arial-Times.txt`.
La licencia de DejaVu acompaña las fuentes en `assets/fonts/tipografias_marco/LICENSE.txt`.

Bloquear usa las reglas de stamina existentes. Recibir daño cancela las oleadas
pendientes; los nombres ya invocados continúan. Al causar KO o perder al atacante
se limpian los proyectiles. La pausa congela tanto el personaje como la lluvia.
El tamaño de los nombres y las hitboxes respeta la escala de los escenarios. La IA utiliza
la misma carga y activación que las otras ultis.

## Verificación y vista previa

Abrir `escenas/pruebas/ulti_marco_preview.tscn` y ejecutar con F6 para verla en bucle.

```sh
/home/agus/Desktop/Godot --headless --path . --script res://tests/test_ulti_marco.gd
```

Sin `--headless`, agregar `-- --capturas` para guardar vistas a 1920 × 1080
en `docs/marco/ulti-j1.png` y `ulti-j2.png`. La prueba cubre carga, HUD,
ambos jugadores, escala 1,1, tres tipografías, daño, bloqueo, agachado, pausa,
interrupción, recuperación, limpieza y KO.

## Procedencia

Las seis poses se generaron con **image_gen integrado**, usando el idle existente
y la referencia original de Marco. Fuente: `../fuentes/ulti.png` (1536 × 1024,
3 columnas × 2 filas). Prompt completo: `../fuentes/ulti.prompt.txt`.
Normalización determinista con `scripts/assets/preparar_ulti_marco.py`: recorte,
alpha binario, escala común 392/417, apoyo y=456, paleta compartida y grilla 4 × 4.
No se generaron letras dentro de los sprites: la tipografía se mantiene como texto real.

QA de los seis cuadros: `docs/marco/ulti-asset-report.json`.
Hoja de contacto: `docs/marco/ulti-contacto.png`. Procedencia por cuadro en `../manifest.json`.
