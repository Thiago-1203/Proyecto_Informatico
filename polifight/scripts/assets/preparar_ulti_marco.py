#!/usr/bin/env python3
"""Corta/normaliza las seis poses generadas de la ulti con ImageMagick."""
import tempfile
from pathlib import Path
from preparar_marco import ASSETS, convert


def main():
    with tempfile.TemporaryDirectory(prefix="marco-ulti-") as scratch:
        tmp = Path(scratch)
        palette = tmp / "palette.png"
        convert(ASSETS / "fuentes/referencia.jpeg", "-colors", 96, "-unique-colors", palette)
        for index in range(6):
            cell, grid, mask = [tmp / name for name in ("cell.png", "grid.png", "alpha.png")]
            convert(ASSETS / "fuentes/ulti.png", "-crop",
                    f"512x512+{index % 3 * 512}+{index // 3 * 512}", "+repage",
                    "-channel", "A", "-threshold", "75%", "+channel", cell)
            # Un mismo factor conserva el tamaño del cuerpo al levantar las manos.
            # 417 px del primer cuadro -> 392 px; apoyo y=456, como el idle.
            convert(cell, "-filter", "point", "-resize", f"{392 / 417 * 100}%",
                    "-background", "none", "-gravity", "NorthWest", "-splice", "15x5",
                    "-extent", "512x512", "-filter", "point", "-resize", "128x128!", grid)
            convert(grid, "-alpha", "extract", "-threshold", "50%", mask)
            convert(grid, "-alpha", "off", "+dither", "-remap", palette,
                    mask, "-alpha", "off", "-compose", "CopyOpacity", "-composite",
                    "-filter", "point", "-resize", "512x512!",
                    f"PNG32:{ASSETS / 'Ulti' / f'ulti_{index+1:02}.png'}")
    print("Ulti de Marco: seis cuadros RGBA 512x512 normalizados.")


if __name__ == "__main__":
    main()
