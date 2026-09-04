#!/usr/bin/env python3
"""Dibuja un rango de la cinta como baldosas de 8x8 en blanco y negro.

Sirve para decidir si unos bytes son un dibujo o no ANTES de declararlos. Ojo
con la trampa de siempre: una racha corta de bits no significa "esto no es un
dibujo", porque un tramado en damero alterna a cada pixel. Lo que se mira aqui
es la FORMA.

Uso: tiles.py <imagen> <ini> <fin> <salida.png> [columnas]
"""
import sys

from render_vram import png


def main():
    d = open(sys.argv[1], "rb").read()
    a, b = int(sys.argv[2], 0), int(sys.argv[3], 0)
    out = sys.argv[4]
    cols = int(sys.argv[5]) if len(sys.argv) > 5 else 32
    n = (b - a + 7) // 8
    filas = (n + cols - 1) // cols
    W, H, esc = cols * 9, filas * 9, 2
    px = [[0] * W for _ in range(H)]
    for t in range(n):
        fy, fx = (t // cols) * 9, (t % cols) * 9
        for y in range(8):
            o = a + t * 8 + y
            bits = d[o] if o < b else 0
            for x in range(8):
                px[fy + y][fx + x] = 255 if (bits >> (7 - x)) & 1 else 40
    rows = []
    for r in px:
        fila = []
        for p in r:
            fila += [p, p, p] * esc
        for _ in range(esc):
            rows.append(fila)
    png(out, W * esc, H * esc, rows)
    print(f"{out}: {n} baldosas de {a:#06x} a {b:#06x}")


if __name__ == "__main__":
    main()
