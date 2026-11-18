# Ulti de Barbieri: laptop y código

- J1: **L**. J2: **3**. Requiere la barra completa y estar en el suelo, quieto, caminando o agachado.
- La barra se llena de abajo hacia arriba y gana 20 puntos por puño o patada que cause daño: 5 golpes para completarla. No carga con el tiempo, golpes bloqueados, ataques fallados ni proyectiles de la propia ulti.
- Barbieri saca la laptop, la abre, escribe alternando dos poses y la cierra.
- Emite cuatro códigos (8 de daño cada uno) a los 0,65 / 0,95 / 1,25 / 1,55 segundos. Termina a los 2,1 segundos y conserva la recuperación de ataques habitual.
- Recibir daño interrumpe la escritura. Los códigos ya lanzados continúan; se eliminan al terminar el combate o salir del escenario. Bloquear usa las reglas de stamina existentes.
- La IA también puede usarla a distancia cuando tiene carga.

## Recursos

`barbieri_laptop.png`: atlas RGBA 1536 × 1024, 3 columnas × 2 filas; celdas 512 × 512. Poses: sacar, abrir, preparar, teclear A, teclear B, cerrar. `barbieri_frames.tres` define sus recortes. El estado `scripts/personajes/ulti_barbieri.gd` sincroniza poses y disparos, escala 0,82 y posición Y +8 para mantener los pies alineados con idle.

`codigo_efectos.png`: atlas RGBA del mismo tamaño y distribución. Fila superior: tres cuadros de vuelo; inferior: tres cuadros de impacto. `codigo_frames.tres` define ambas animaciones. El proyectil invierte todo el sprite al viajar a la izquierda.

Vista previa: abrir `escenas/pruebas/ulti_barbieri_preview.tscn` y ejecutar con F6. Prueba de combate: `Godot --headless --path . --script tests/test_ulti.gd`.

## Generación

Se utilizó ImageGen integrado con fondo transparente. Referencia de identidad: `assets/characters/Barbieri/idle/idle1.png`.

Prompt del personaje: crear un atlas pixel art de seis poses, 1536 × 1024, 3 × 2 celdas iguales; conservar pelo negro rizado, polo negro con cuello blanco, jeans y zapatos del personaje de referencia. Personaje completo mirando a la derecha, saca una laptop cerrada, abre su pantalla, la sostiene sobre un antebrazo, alterna dos poses de tipeo con reflejo cian y finalmente la cierra. Mantener escala y línea de pies, transparencia real, sin suelo, textos, bordes ni proyectiles independientes.

Prompt de proyectiles: atlas pixel art de seis cuadros, 1536 × 1024, 3 × 2 celdas iguales. Fila superior: tres variantes de un proyectil de energía cian con glifos </>, punta hacia la derecha y pequeños fragmentos binarios en la estela izquierda. Fila inferior: impacto compacto con glifos rotos, expansión angular de fragmentos y fragmentos dispersos que desaparecen. Transparencia real, paleta limitada, sin personajes, grillas ni rótulos.
