# Marco

Personaje seleccionable para J1, J2 y rival IA, basado en la referencia aportada.
Conserva rulos, anteojos, remera beige sobre mangas negras, jeans y zapatillas oscuras.
Su ulti es una [lluvia de nombres de tipografías](Ulti/README.md),
con animación propia de levantar las manos y volver a la guardia.

## Arte y tamaño

48 PNG RGBA de **512 × 512**, cuatro cuadros para cada una de las doce acciones
base, más seis cuadros para la ulti. Los ciclos de retroceso usan los cuadros de caminata en orden inverso.
Cada animación fija textura, posición, escala y hurtbox para evitar heredar valores
del estado anterior. Las ventanas de impacto sólo se habilitan durante la extensión
del puño o la patada; preparación y recuperación no golpean.

Barbieri usa imágenes de 480, 500 y 512 píxeles. Marco normaliza ese formato a 512
con los pies en `(256, 456)` como referencia de apoyo: suela a `y=200` en el mundo,
igual que el cuerpo físico. Su primer idle tiene 392 píxeles de altura visible;
los de Barbieri tienen 351 y 380 (aproximadamente 7 % más alto que su promedio).
La escala anatómica es común a todo el lote: agachado y KO no se agrandan al recortar.
Salto y caída conservan el origen para que la física controle la altura.

Pixel art normalizado a una grilla de 4 × 4, paleta común extraída de la referencia,
alpha binario, filtrado nearest y sin mipmaps. Las colisiones son independientes
del espacio transparente: cuerpo con apoyo a 200, hurtbox de pie de 246 × 392 y
agachado de 246 × 332. Daño 8 y stamina 125: pega menos que Barbieri (10),
pero tiene más stamina que él (100).

## Fuentes y reproducción

Generado con la herramienta integrada **image_gen**, en tres planchas de 16 poses.
Los prompts completos están en [fuentes/prompts.json](fuentes/prompts.json).
Las fuentes originales se conservan en `fuentes/`, excluidas del importador con
`.gdignore`; el generador entregó planchas de 1254 × 1254, que se cortaron y
normalizaron de forma determinista. `manifest.json` registra procedencia y QA por cuadro.
La referencia fue suministrada por el usuario; no se usaron packs de terceros.

Para regenerar los cuadros desde las fuentes (requiere ImageMagick):

```sh
python3 scripts/assets/preparar_marco.py
python3 scripts/assets/preparar_ulti_marco.py
```

## Verificación

```sh
/home/agus/Desktop/Godot --headless --path . --script res://tests/test_marco.gd
/home/agus/Desktop/Godot --headless --path . --script res://tests/test_seleccion.gd
```

Para capturar la prueba en pantalla agregar `-- --capturas`, sin `--headless`.
La prueba cubre ambos jugadores, avance/retroceso, guardia baja, salto y caída,
preparación/impacto/recuperación, bloqueo, interrupción, KO y celebración.
La hoja de contacto y las capturas del juego están en `docs/marco/`.
