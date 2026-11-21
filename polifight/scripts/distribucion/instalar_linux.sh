#!/usr/bin/env bash
set -euo pipefail

# Se distribuye junto al ejecutable; no necesita Godot ni permisos de administrador.
paquete="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
datos="${XDG_DATA_HOME:-$HOME/.local/share}"
destino="$datos/polifight"
aplicaciones="$datos/applications"

if [[ ! -f "$paquete/PoliFight.x86_64" ]]; then
    printf 'No se encontró PoliFight.x86_64 junto al instalador.\n' >&2
    exit 1
fi

mkdir -p -- "$destino" "$aplicaciones"
if [[ "$paquete" != "$(cd -- "$destino" && pwd)" ]]; then
    install -m 755 -- "$paquete/PoliFight.x86_64" "$destino/PoliFight.x86_64"
    install -m 644 -- "$paquete/icono.png" "$destino/icono.png"
    install -m 644 -- "$paquete/LEEME.txt" "$destino/LEEME.txt"
    if [[ -d "$paquete/licencias" ]]; then
        cp -R -- "$paquete/licencias" "$destino/"
    fi
fi

# Escapar rutas según Desktop Entry, incluyendo espacios y caracteres especiales.
python3 - "$destino" "$aplicaciones/polifight.desktop" <<'PY'
import pathlib
import sys

destino = pathlib.Path(sys.argv[1])
def valor(texto):
    return str(texto).replace('\\', '\\\\').replace('\n', '\\n').replace('\r', '\\r').replace('\t', '\\t')

ejecutable = str(destino / 'PoliFight.x86_64')
for caracter in ('\\', '"', '`', '$'):
    ejecutable = ejecutable.replace(caracter, '\\' + caracter)
ejecutable = ejecutable.replace('%', '%%')
entrada = '\n'.join([
    '[Desktop Entry]',
    'Version=1.0',
    'Type=Application',
    'Name=PoliFight',
    'Comment=Juego de lucha local',
    'Exec=' + valor('"' + ejecutable + '"'),
    'Path=' + valor(destino),
    'Icon=' + valor(destino / 'icono.png'),
    'Terminal=false',
    'Categories=Game;ActionGame;',
    'StartupNotify=false',
    '',
])
pathlib.Path(sys.argv[2]).write_text(entrada, encoding='utf-8')
PY

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$aplicaciones" || true
fi
printf 'PoliFight instalado. Buscá «PoliFight» en el menú de aplicaciones.\n'
printf 'Ejecutable: %s/PoliFight.x86_64\n' "$destino"
