#!/usr/bin/env python3
"""Hoja de contacto de la tabla de patrones: los 768 patrones con su color.

Se dibuja cada tercio como una rejilla de 16x16 baldosas, tomando los bits de
la tabla de patrones y el par tinta/fondo de la tabla de colores en el offset
paralelo. Sirve para ver de un vistazo QUE hay en los 16 KB que la cinta
vuelca a la VRAM, sin tener que adivinar geometrias.

Uso: hoja.py <imagen64k> <base_patrones> <base_colores> <salida.png>
"""
import sys

from render_vram import PAL, png


def main():
    img = open(sys.argv[1], "rb").read()
    pbase = int(sys.argv[2], 0)
    cbase = int(sys.argv[3], 0)
    out = sys.argv[4]
    esc = 2

    # 3 tercios en horizontal, 16x16 baldosas cada uno, separados por 1 columna
    W = (3 * 16 * 8) + 2 * 4
    H = 16 * 8
    px = [[1] * W for _ in range(H)]
    for t in range(3):
        for n in range(256):
            fy, fx = (n // 16) * 8, (n % 16) * 8 + t * (16 * 8 + 4)
            for y in range(8):
                bits = img[pbase + t * 0x800 + n * 8 + y]
                c = img[cbase + t * 0x800 + n * 8 + y]
                tinta, fondo = c >> 4, c & 15
                for x in range(8):
                    v = tinta if (bits >> (7 - x)) & 1 else fondo
                    px[fy + y][fx + x] = v if v else 1
    rows = []
    for r in px:
        fila = []
        for p in r:
            fila += list(PAL[p]) * esc
        for _ in range(esc):
            rows.append(fila)
    png(out, W * esc, H * esc, rows)
    print(f"{out}: {W*esc}x{H*esc}")


if __name__ == "__main__":
    main()
