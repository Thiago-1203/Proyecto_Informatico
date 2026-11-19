#!/usr/bin/env python3
"""Normaliza las tres fuentes de Marco con ImageMagick, sin dibujar poses.

Ejecutar desde cualquier directorio: python3 scripts/assets/preparar_marco.py
Las fuentes y los prompts originales permanecen en Marco/fuentes (sin importar).
"""
from pathlib import Path
import json
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets/characters/Marco"
SHEETS = {
    "movimiento": ["idle", "caminar", "salto", "caida"],
    "combate": ["agacharse", "caminar_agachado", "punio", "patada"],
    "reacciones": ["bloqueo", "recibir_golpe", "ko", "victoria"],
}


def convert(*args):
    subprocess.run(["convert", *map(str, args)], check=True)


def identify(path, fmt):
    return subprocess.check_output(["identify", "-format", fmt, str(path)], text=True)


def main():
    records = []
    with tempfile.TemporaryDirectory(prefix="polifight-marco-") as scratch:
        tmp = Path(scratch)
        palette = tmp / "palette.png"
        # Una misma paleta de la referencia evita cambios de ropa entre planchas.
        convert(ASSETS / "fuentes/referencia.jpeg", "-colors", 96, "-unique-colors", palette)
        for sheet, actions in SHEETS.items():
            source = ASSETS / "fuentes" / f"{sheet}.png"
            width, height = map(int, identify(source, "%w %h").split())
            for row, action in enumerate(actions):
                for col in range(4):
                    x0, y0 = round(col * width / 4), round(row * height / 4)
                    x1, y1 = round((col + 1) * width / 4), round((row + 1) * height / 4)
                    cell = tmp / "cell.png"
                    convert(source, "-crop", f"{x1-x0}x{y1-y0}+{x0}+{y0}", "+repage",
                            "-channel", "A", "-threshold", "75%", "+channel", cell)
                    # Medir sólo alpha real, sin ruido casi transparente del generador.
                    bounds = subprocess.check_output([
                        "convert", str(cell), "-alpha", "extract", "-format", "%@", "info:"
                    ], text=True)
                    bw, bh, bx, by = map(int, re.fullmatch(r"(\d+)x(\d+)\+(\d+)\+(\d+)", bounds).groups())
                    # Escala común 1.457: idle de 269 px -> 392 px; nunca estirar
                    # cada pose al alto de idle (eso agrandaría agachados y KO).
                    scale = 392 / 269
                    left = round(256 - (x1-x0) * scale / 2)
                    top = round(456 - (by + bh) * scale)
                    if action in ("salto", "caida"):
                        top = round(456 - 300 * scale)
                    frame = ASSETS / action / f"{action}_{col+1:02}.png"
                    frame.parent.mkdir(exist_ok=True)
                    grid, mask = tmp / "grid.png", tmp / "alpha.png"
                    convert(cell, "-filter", "point", "-resize", f"{scale*100}%",
                            "-background", "none", "-gravity", "NorthWest",
                            "-splice", f"{left}x{max(0,top)}", "-gravity", "NorthWest",
                            "-extent", "512x512", "-filter", "point", "-resize", "128x128!", grid)
                    # remap toma el alpha de la paleta RGB: restaurar la máscara
                    # por separado para conservar transparencia real en el PNG.
                    convert(grid, "-alpha", "extract", "-threshold", "50%", mask)
                    convert(grid, "-alpha", "off", "+dither", "-remap", palette,
                            mask, "-alpha", "off", "-compose", "CopyOpacity", "-composite",
                            "-filter", "point", "-resize", "512x512!", f"PNG32:{frame}")
                    records.append({"path": str(frame.relative_to(ROOT)), "source": sheet,
                                    "row": row, "column": col, "source_alpha_bounds": [bx, by, bw, bh],
                                    "scale": scale, "offset": [left, top]})
        (ASSETS / "fuentes/normalizacion.json").write_text(json.dumps(records, indent=2) + "\n")
    print(f"Marco: {len(records)} cuadros de 512x512, grilla de píxel 4x4 y alpha binario.")


if __name__ == "__main__":
    main()
