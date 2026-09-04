#!/usr/bin/env python3
"""Dibuja la pantalla SCREEN 2 que trae la cinta, tal como la veria el VDP.

El juego no compone la pantalla: la trae hecha. Los 16 KB que van a 0x8000 son
una FOTO de la VRAM entera, y el cargador los vuelca de un LDIRVM (0x4010).
Asi que basta con leerlos con la geometria del TMS9918:

  0x0000-0x17FF  patrones   (tres tercios de 256 patrones x 8 filas)
  0x1800-0x1AFF  nombres    (32x24 indices de baldosa)
  0x1B00-0x1B7F  atributos de sprite (32 x 4 bytes)
  0x2000-0x37FF  colores    (tres tercios, un byte por FILA de patron:
                             nibble alto = tinta, nibble bajo = fondo)
  0x3800-0x3FFF  patrones de sprite

y recordar que el color 0 NO es negro: es transparente, y deja ver el color
del borde.

Uso: render_vram.py <imagen64k> <base> <salida.png> [--sprites]
"""
import sys

# Paleta del TMS9918 en RGB (la de openMSX). El 0 es transparente; aqui se
# pinta con el color del borde que el juego deja puesto.
PAL = [
    (0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
    (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
    (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
    (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255),
]


def png(path, w, h, rows):
    """PNG de color verdadero, sin dependencias: zlib + un chunk IDAT."""
    import struct
    import zlib
    raw = b"".join(b"\x00" + bytes(r) for r in rows)

    def chunk(tag, data):
        c = tag + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c))

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        f.write(chunk(b"IEND", b""))


def dibuja(v, borde=1, sprites=True, escala=2):
    """Devuelve las filas RGB de la pantalla de 256x192."""
    img = [[borde] * 256 for _ in range(192)]
    for fila in range(24):
        tercio = fila // 8
        for col in range(32):
            n = v[0x1800 + fila * 32 + col]
            pat = 0x0000 + tercio * 0x800 + n * 8
            colr = 0x2000 + tercio * 0x800 + n * 8
            for y in range(8):
                bits = v[pat + y]
                c = v[colr + y]
                tinta, fondo = c >> 4, c & 15
                for x in range(8):
                    px = tinta if (bits >> (7 - x)) & 1 else fondo
                    img[fila * 8 + y][col * 8 + x] = px if px else borde

    if sprites:
        for s in range(32):
            a = 0x1B00 + s * 4
            y, x, p, c = v[a], v[a + 1], v[a + 2], v[a + 3]
            if y == 0xD0:
                break
            y = (y + 1) & 0xFF
            if y > 192:
                y -= 256
            if c & 0x80:
                x -= 32
            c &= 15
            if not c:
                continue
            base = 0x3800 + (p & 0xFC) * 8
            for cuad in range(4):
                for r in range(8):
                    bits = v[base + cuad * 8 + r]
                    yy = y + r + (8 if cuad & 1 else 0)
                    xx = x + (8 if cuad & 2 else 0)
                    if not (0 <= yy < 192):
                        continue
                    for b in range(8):
                        if (bits >> (7 - b)) & 1 and 0 <= xx + b < 256:
                            img[yy][xx + b] = c

    rows = []
    for r in img:
        fila = []
        for p in r:
            fila += list(PAL[p])
        for _ in range(escala):
            rows.append(fila * 1 if escala == 1 else
                        [c for p in r for c in PAL[p] for _ in range(1)])
    # escala simple x2 en ambos ejes
    out = []
    for r in img:
        fila = []
        for p in r:
            fila += list(PAL[p]) * escala
        for _ in range(escala):
            out.append(fila)
    return out


def main():
    img = open(sys.argv[1], "rb").read()
    base = int(sys.argv[2], 0)
    v = img[base:base + 0x4000]
    borde = int(sys.argv[4], 0) if len(sys.argv) > 4 else 1
    rows = dibuja(v, borde=borde)
    png(sys.argv[3], 256 * 2, 192 * 2, rows)
    print(f"{sys.argv[3]}: 512x384 desde {base:#06x}")


if __name__ == "__main__":
    main()
