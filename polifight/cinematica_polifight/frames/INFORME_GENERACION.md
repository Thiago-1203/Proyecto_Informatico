# Animación por posiciones 640x360

- 16 fotogramas a 640x360, sin reducción de paleta.
- Los píxeles de las hojas cambian de coordenadas; no se modifican sus colores.
- Cada copa rota como una pieza rígida alrededor del tronco: sin deformación por filas.
- Desde y=118, todo píxel no perteneciente al follaje se restaura desde la imagen fija.
- Todas las nubes detectadas se extraen del fondo y avanzan en una capa independiente.
- Velocidad prevista: hojas 4 fps; nubes 4 px/s sobre un recorrido de 640 px.
- Frames únicos: 16/16.
- Pausas entre cuadros consecutivos: 0.
- Violaciones en zonas rígidas de control: 0.