CONTROLES de personajes

Jugador 1:
salto: W,
izquierda: A,
agacharse: S,
derecha: D,
ataque basico: J
patada: K

Jugador 2:
salto: flecha arriba,
izquierda: flecha izquierda,
agacharse flecha abajo,
derecha: flecha derecha,
ataque basico: 1
patada: 2 (fila superior o teclado numérico)

La patada se ejecuta desde el suelo, parado, caminando o agachado. Usa tres sprites y dura 0,7 segundos de simulación: preparación hasta 0,18 s, golpe activo hasta 0,36 s y recuperación hasta 0,7 s. Aplica un solo impacto por ejecución y conserva el daño del puño. Su impulso horizontal es el doble: 360 frente a 180 al recibir daño, 220 frente a 110 al bloquear y 520 frente a 260 en el lanzamiento de KO. El multiplicador se ajusta en `Personaje > Retroceso de golpes > Multiplicador retroceso patada`.

Prueba automatizada desde este directorio:

```bash
godot --headless --path polifight --script res://tests/test_patada.gd
```

Revisión manual: abrir `polifight/escenas/juego/nivelI.tscn` y ejecutar F6. Acercar a los jugadores, usar K/2 y comparar con J/1; intercambiar posiciones, bloquear con H/3, terminar la pelea con una patada y revisar la celebración. Durante la preparación o recuperación, usar Escape y comprobar continuar, reiniciar y volver al menú.
