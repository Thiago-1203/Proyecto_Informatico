#!/usr/bin/env bash
set -euo pipefail

proyecto="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
salida="$proyecto/build/PoliFight-Linux"
motor="${GODOT_BIN:-}"
if [[ -z "$motor" ]]; then
    for candidato in godot godot4 "$HOME/Desktop/Godot"; do
        if command -v "$candidato" >/dev/null 2>&1; then
            motor="$(command -v "$candidato")"
            break
        fi
    done
fi
if [[ -z "$motor" ]]; then
    printf 'No se encontró Godot. Indicá su ruta con GODOT_BIN=/ruta/a/Godot.\n' >&2
    exit 1
fi

mkdir -p -- "$salida/licencias"
touch -- "$proyecto/build/.gdignore"
"$motor" --headless --path "$proyecto" --editor --import --quit
"$motor" --headless --path "$proyecto" --export-release Linux "$salida/PoliFight.x86_64"
chmod +x -- "$salida/PoliFight.x86_64"
install -m 755 -- "$proyecto/scripts/distribucion/instalar_linux.sh" "$salida/Instalar.sh"
install -m 644 -- "$proyecto/assets/ui/PoliFight_LOGO.png" "$salida/icono.png"
install -m 644 -- "$proyecto/docs/ejecutable_linux.txt" "$salida/LEEME.txt"
install -m 644 -- "$proyecto/docs/licencias/Godot.txt" "$salida/licencias/Godot.txt"
install -m 644 -- "$proyecto/docs/licencias/Godot-terceros.txt" "$salida/licencias/Godot-terceros.txt"
install -m 644 -- "$proyecto/assets/fonts/LICENSE-DejaVu.txt" "$salida/licencias/DejaVu.txt"
install -m 644 -- "$proyecto/assets/fonts/tipografias_marco/LICENSE-Arial-Times.txt" "$salida/licencias/Arial-Times.txt"
install -m 644 -- "$proyecto/assets/fonts/tipografias_marco/LICENSE.txt" "$salida/licencias/Tipografias-Marco.txt"
tar -czf "$proyecto/build/PoliFight-Linux.tar.gz" -C "$proyecto/build" PoliFight-Linux
printf '\nListo: %s/PoliFight.x86_64\n' "$salida"
printf 'Para compartir: %s/build/PoliFight-Linux.tar.gz\n' "$proyecto"
