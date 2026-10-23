# Selector de modos de PoliFight

Fecha: 22 de octubre de 2026. Motor: Godot 4.7.1.

## Resultado implementado

JUGAR abre `escenas/menu/selector_modos.tscn`. Un carrusel circular resalta el modo
central en dorado y reduce los vecinos azules. Hay tres ilustraciones independientes
y un título transparente en `assets/ui/selector_modos/`. Se reutilizan el logo,
el fondo escolar y las flechas pixeladas del juego. No hay botón de confirmación
ni franja de instrucciones, según el pedido.

1 VS 1 inicia el combate existente. HISTORIA y 2 VS 2 son vistas previas con
PROXIMAMENTE; al confirmar muestran MODO EN DESARROLLO, sin iniciar otro modo.

## Controles

- Flechas, WASD, cruceta o stick izquierdo: recorrer los modos.
- Enter, espacio o botón inferior A del mando: confirmar.
- Escape o botón derecho B del mando: volver al menú principal.
- Repetición de navegación: 0,35 s iniciales y luego 0,18 s.
- Zona muerta de los ejes: 0,55. Se admiten mandos de cualquier dispositivo.
- Mantener Enter al abrir JUGAR no confirma el modo automáticamente.

## Referencia y evidencia visual

- Fuente: `/home/agus/.codex/generated_images/01a165fe-4525-7560-8295-02894be577a7/exec-9e47c6f4-19a3-4f36-b634-6a283140da35.png` (1672 × 941).
- Implementación: `/home/agus/.codex/visualizations/2026/10/22/01a165fe-4525-7560-8295-02894be577a7/selector_modos.png` (1920 × 1080).
- Resolución adicional: `/home/agus/.codex/visualizations/2026/10/22/01a165fe-4525-7560-8295-02894be577a7/selector_modos_1280.png` (1280 × 720).
- Comparación conjunta: `/home/agus/.codex/visualizations/2026/10/22/01a165fe-4525-7560-8295-02894be577a7/selector_comparacion.png`.
- Comparación de título y tarjeta: `/home/agus/.codex/visualizations/2026/10/22/01a165fe-4525-7560-8295-02894be577a7/selector_detalles.png`.
- Estado comparado: 1 VS 1 seleccionado, sin aviso y con las transiciones terminadas.
- Capturas del viewport real de Godot con OpenGL; no son un montaje de la interfaz.
  Para la comparación general se normalizaron ambos lienzos a 960 × 540.
  No corresponde densidad CSS; las capturas originales tienen escala de píxeles 1:1.

## Revisión visual

- Tipografía: título arcade rasterizado independiente; nombres y descripciones
  editables con el alfabeto 5 × 7 existente. Se reforzó el peso de los nombres y
  se destacó VS en dorado. No hay truncamiento ni superposición a 1920 y 1280.
- Distribución: tarjeta central de 640 × 520, vecinos a escala 0,67, indicadores
  debajo y composición centrada de 1920 × 1080 que conserva su proporción.
  La ausencia del botón y del pie deja espacio inferior intencionalmente.
- Colores: azul/celeste para vecinos y subtítulos, fondo azul marino, selección
  dorada y acentos naranja. Fondo escolar oscurecido para mantener la lectura.
- Imágenes: las ilustraciones se generaron individualmente a partir de la primera
  propuesta. Se conservan sus proporciones y se usa filtrado nearest. El título
  se presenta con un AtlasTexture para omitir el margen transparente sobrante,
  sin modificar el PNG original. Fondo y logo provienen del juego.
- Contenido: el modo disponible dice DUELO LOCAL; los otros dos indican su estado
  real. Las instrucciones de entrada están documentadas aquí, fuera de la pantalla.

## Iteraciones de revisión

1. La primera captura mostraba un encabezado demasiado fino y arte estirado.
   Se sustituyó el encabezado por una imagen independiente y se corrigió el ajuste
   de las ilustraciones para conservar sus proporciones.
2. La comparación conjunta mostró poca jerarquía en los nombres y bajo contraste
   en los subtítulos pequeños. Se reforzó el alfabeto, se eliminó la sombra del
   texto oscuro sobre celeste y se agrandó la descripción central. Las capturas
   enlazadas corresponden a esta revisión final.

No quedan problemas P0/P1/P2 observados. Como refinamiento P3, los nombres usan
la fuente del juego y los marcos son controles nativos con decoración más simple
que la pintura del concepto. Esta entrega conserva su composición, temática,
ilustraciones y paleta; no es una copia píxel a píxel del dibujo inicial.

## Verificación

- Comprobación de carga: `Godot --headless --editor --path . --quit`.
- Prueba focalizada del motor con ventana y entradas sintéticas: 17 comprobaciones,
  cero fallos. Navegación WASD/flechas/cruceta, cierre del ciclo, repetición al
  mantener una dirección, stick de un segundo dispositivo, zona muerta, modos
  pendientes, apertura desde JUGAR, protección de Enter mantenido, Escape al
  menú e inicio del combate con A. Sin errores de scripts en el registro final.
- Capturas revisadas a 1920 × 1080 y 1280 × 720, y con 2 VS 2 seleccionado.
- `git diff --check`: sin errores.
- No se modificó el combate. La interacción con un mando físico y el playtest
  manual dentro del editor quedan para el equipo; se simularon sus eventos en el motor.

Para reproducir manualmente: ejecutar F5, elegir JUGAR, recorrer los tres modos,
confirmar los pendientes, volver con Escape y entrar a 1 VS 1 con Enter.

## Arte generado

Herramienta: Image Gen integrada; no se utilizó API ni CLI de pago separado.
Referencia visual común: primera propuesta elegida por el usuario.

Conjunto de prompts utilizado, resumido:

- `duelo_local.png`: ilustración independiente de dos puños azul y naranja que
  chocan sobre una explosión amarilla/roja, fondo azul marino, pixel art arcade,
  sin texto, marco, botones ni interfaz; composición horizontal 3:2.
- `historia.png`: cuaderno escolar en espiral, hojas y lapicera, portada ilustrada
  con un colegio en azules/celestes, fondo azul marino, mismo pixel art,
  sin texto ni interfaz; composición horizontal 3:2.
- `equipos.png`: cuatro siluetas de luchadores en dos equipos enfrentados,
  contornos celestes, patio escolar con reja y azotea, misma paleta y pixel art,
  sin texto ni interfaz; composición horizontal 3:2.
- `titulo_selector.png`: texto exacto SELECCIONA EL MODO en una línea, letras
  arcade blancas/celestes de gran peso, contorno marino y pincelada azul pixelada,
  con transparencia real; sin logo, tarjetas ni controles.

## Transición desde JUGAR

Se añadió una salida de 0,18 s para el menú inicial y una entrada de 0,48 s
para el selector. El fondo se mezcla gradualmente y las tarjetas se deslizan
desde abajo y desde los laterales hasta sus posiciones definitivas. Durante
la transición se bloquean navegación y confirmación; volver al menú restaura
su opacidad, foco y botones. La animación se puede repetir al reabrir JUGAR.

Verificación adicional: carga headless sin errores y prueba con ventana de
13 comprobaciones, cero fallos. Se comprobaron fundido gradual, entrada,
posiciones finales, protección ante pulsaciones repetidas, vuelta al menú,
reapertura y confirmación del combate después de la transición.

Captura animada de la ejecución:
`/home/agus/.codex/visualizations/2026/10/22/01a165fe-4525-7560-8295-02894be577a7/transicion_selector.webp`.
Los fotogramas se capturaron a 1280 × 720 y la vista previa se redujo a 960 × 540.

## Continuidad del fondo animado

El selector comparte la misma instancia de CinematicaColegio del menú y ya no
superpone la imagen fija del colegio. Su tiempo de animación, los fotogramas
y el desplazamiento de nubes continúan durante la transición, con los modos
abiertos y al regresar. Al ejecutar el selector por separado, crea una instancia
animada propia sin fundido inicial.

Verificación: carga headless sin errores y siete comprobaciones con ventana,
cero fallos; se confirmó la continuidad del reloj, fotogramas, nubes, instancia,
visibilidad y funcionamiento independiente de la escena.

## Entrada continua al colegio

La entrada usa una animación en tiempo real de Godot sobre la fachada original.
Camera2D avanza hacia el centro de la puerta con aumento continuo y las dos
hojas se abren progresivamente sobre sus goznes. Cada hoja reutiliza su región
de la textura original en un Polygon2D; el paño fijo superior queda intacto.
La geometría y el aumento se actualizan en cada fotograma del motor.

La apertura dura 0,30 s y el acercamiento 0,72 s, con una demora inicial de
0,08 s y una llegada negra de 0,08 s. En total la película dura 0,88 s;
sumando la salida de las tarjetas, la entrada al combate tarda unos 1,04 s.
Los tiempos se pueden ajustar desde las propiedades de entrada_colegio.gd.

El material y la textura del fondo animado se comparten con el menú para
mantener las nubes y los árboles en movimiento. La animación bloquea entradas
repetidas y emite su finalización una vez antes de iniciar el combate.
Los modos pendientes conservan su aviso.

### Cambio respecto de la versión anterior

Se reemplazó la secuencia de once imágenes y sus disoluciones por una sola
fachada animada con Camera2D y dos hojas texturadas. La oscuridad del acceso
reutiliza el PNG negro existente. Los cuadros generados anteriormente quedan
como referencias de arte, fuera de la reproducción. Sus prompts originales
siguen registrados en los archivos fuentes_*.json de entrada_colegio/.

### Evidencia y verificación

- Vista previa del motor: `/home/agus/.codex/visualizations/2026/10/22/01a165fe-4525-7560-8295-02894be577a7/entrada_colegio_continua.webp`.
- Revisión en seis instantes: `/home/agus/.codex/visualizations/2026/10/22/01a165fe-4525-7560-8295-02894be577a7/entrada_continua_revision.png`.
- 53 capturas del viewport a 960 × 540, avanzando la animación en pasos de 1/60 s.
- Inspección del plano inicial, apertura, aproximación y llegada negra: la misma
  fachada conserva su geometría y paleta; no hay superposiciones de puertas
  ni cambios de arquitectura. El zoom mantiene el filtrado nearest del pixel art.
- Sin tipografía ni controles nuevos. El paño fijo, las columnas y los goznes
  conservan sus posiciones en el mundo durante la apertura.
- Carga headless de Godot sin errores y doce comprobaciones con ventana,
  cero fallos: continuidad del zoom y las hojas entre instantes adyacentes,
  textura compartida, modos pendientes, material de nubes activo, protección
  de entradas, continuidad del fondo, finalización única e inicio del combate.
- `git diff --check`: sin incidencias.

Prueba manual: F5 → JUGAR → confirmar 1 VS 1; observar la apertura continua,
el avance rápido hacia la oscuridad y el comienzo del combate.

final result: passed
