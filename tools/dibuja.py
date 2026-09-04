#!/usr/bin/env python3
"""Dibuja las pantallas del juego DESDE LA CINTA, repitiendo lo que hace el codigo.

No son capturas: aqui se ejecuta con papel y lapiz la misma secuencia de
volcados a VRAM que el juego, y luego se lee la VRAM resultante con la geometria
del TMS9918. Si el dibujo sale, es que el formato esta entendido; si sale ruido,
es que no.

Las tres rutinas de volcado que hay que reproducir (primera parte):

  sub_4497+l44f2 (0x4497)  copia BC bytes de patrones a VRAM DE, y REPITE la
                           copia en DE+0x800 y DE+0x1000: los tres tercios de
                           SCREEN 2 comparten la misma baldosa.
  sub_44ce (0x44CE)        lo anterior y, a continuacion, un byte de color POR
                           BALDOSA (no por fila) que se estira a las ocho filas
                           con FILVRM. Consume BC + BC/8 bytes.
  sub_446d (0x446D)        lo anterior pero con la tabla de colores COMPLETA,
                           fila a fila: consume 2*BC bytes.

Uso: dibuja.py <dir_work> <dir_salida>
"""
import os
import sys

from render_vram import PAL, png

# ---- primera parte: que carga cada una de las ocho pantallas ---------------
# (nombre, direccion de la tabla de nombres, [(rutina, origen, longitud, VRAM)])
COMUN = [("44ce", 0xAB60, 0x2A0, 0x0000), ("446d", 0xAE54, 0x40, 0x298)]
# Las descripciones NO son suposiciones: son lo que se ve en el PNG que sale de
# aqui, mirado uno a uno.
FASES = [
    ("0 la calle del puerto, con la taberna y el muelle", 0x82F5,
     [("44ce", 0xAED4, 0x1C0, 0x2D8), ("446d", 0xB0CC, 0x20, 0x498)]),
    ("1 el porton claveteado entre dos casas",            0x85F5,
     [("44ce", 0xB10C, 0x178, 0x2D8), ("446d", 0xB2B3, 0x40, 0x450)]),
    ("2 el patio con la escalera, los toneles y el ave",  0x88F5,
     [("44ce", 0xB333, 0x140, 0x2D8), ("446d", 0xB49B, 0x70, 0x418)]),
    ("3 la iglesia: crucifijo, altar y vidriera",         0x8BF5,
     [("44ce", 0xB57B, 0x1A0, 0x2D8), ("446d", 0xB74F, 0x68, 0x478)]),
    ("4 la sala del mapamundi, con su retrato y su mesa", 0x8EF5,
     [("44ce", 0xB81F, 0x1A8, 0x2D8), ("446d", 0xB9FC, 0xA0, 0x480)]),
    ("5 el interior de la taberna: barra, banquetas y un cuadro", 0x91F5,
     [("44ce", 0xBB3C, 0xF8, 0x2D8)]),
    ("6 la cubierta del barco, con las jarcias y los toneles", 0x94F5,
     [("44ce", 0xBC53, 0xA0, 0x2D8), ("446d", 0xBD07, 0x58, 0x378)]),
    ("7 el almacen del muelle: AGUA, VINO, COM...",       None,
     [("44ce", 0xBDB7, 0x198, 0x2D8), ("446d", 0xBF82, 0x48, 0x470)]),
]
MAPA_ANCHO = 0x97F5          # 64 columnas x 24 filas, la fase 7
PANTALLA_FIN = 0xC310        # la que queda mientras carga la segunda parte


def copia3(v, img, org, n, dst):
    """Los tres tercios comparten la misma baldosa (l44f2)."""
    for t in range(3):
        v[dst + t * 0x800:dst + t * 0x800 + n] = img[org:org + n]


def r44ce(v, img, org, n, dst):
    copia3(v, img, org, n, dst)
    col = org + n
    for i in range(n // 8):
        c = img[col + i]
        for t in range(3):
            a = 0x2000 + dst + t * 0x800 + i * 8
            v[a:a + 8] = bytes([c]) * 8
    return col + n // 8


def r446d(v, img, org, n, dst):
    copia3(v, img, org, n, dst)
    copia3(v, img, org + n, n, 0x2000 + dst)
    return org + 2 * n


def vram_de_fase(img, prog):
    v = bytearray(0x4000)
    for rut, org, n, dst in COMUN + prog:
        (r44ce if rut == "44ce" else r446d)(v, img, org, n, dst)
    return v


def pinta(v, out, borde=14, esc=2):
    px = [[borde] * 256 for _ in range(192)]
    for fila in range(24):
        t = fila // 8
        for col in range(32):
            n = v[0x1800 + fila * 32 + col]
            p, c = t * 0x800 + n * 8, 0x2000 + t * 0x800 + n * 8
            for y in range(8):
                bits, cc = v[p + y], v[c + y]
                tinta, fondo = cc >> 4, cc & 15
                for x in range(8):
                    q = tinta if (bits >> (7 - x)) & 1 else fondo
                    px[fila * 8 + y][col * 8 + x] = q if q else borde
    rows = []
    for r in px:
        f = []
        for q in r:
            f += list(PAL[q]) * esc
        for _ in range(esc):
            rows.append(f)
    png(out, 256 * esc, 192 * esc, rows)


# Las siete parejas de cifras del resumen, cada una de su color.
CIFRAS = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0),
          (255, 0, 255), (0, 255, 255), (255, 128, 0)]


def marca_las_cifras(v, out, esc=2):
    """La pantalla de resumen con cada contador pintado de un color.

    Es la comprobacion de que rotulo lleva cada contador, y no hay otra manera
    de saberlo: los rotulos son dibujo, no texto, asi que hay que mirar donde
    caen las baldosas que el bucle de 0x5D0C usa para las cifras.
    """
    rows = []
    for fila in range(24):
        t = fila // 8
        linea = []
        for col in range(32):
            n = v[0x1800 + fila * 32 + col]
            p, c = t * 0x800 + n * 8, 0x2000 + t * 0x800 + n * 8
            linea.append((n, p, c))
        for y in range(8):
            f = []
            for n, p, c in linea:
                bits, cc = v[p + y], v[c + y]
                tinta, fondo = cc >> 4, cc & 15
                for x in range(8):
                    q = tinta if (bits >> (7 - x)) & 1 else fondo
                    rgb = (CIFRAS[(n - 188) // 2] if 188 <= n <= 201
                           else PAL[q or 14])
                    f += list(rgb) * esc
            for _ in range(esc):
                rows.append(f)
    png(out, 256 * esc, 192 * esc, rows)


def primera_parte(work, sal):
    img = open(os.path.join(work, "p1.img"), "rb").read()
    for i, (nombre, name, prog) in enumerate(FASES):
        v = vram_de_fase(img, prog)
        if name is not None:
            v[0x1800:0x1B00] = img[name:name + 0x300]
        else:
            # sub_4729: 24 filas de 32 baldosas leidas con paso de 64
            for f in range(24):
                o = MAPA_ANCHO + f * 0x40
                v[0x1800 + f * 32:0x1800 + f * 32 + 32] = img[o:o + 32]
        f = os.path.join(sal, f"p1_fase{i}.png")
        pinta(v, f)
        print(f"  {f}  ({nombre})")
    # la pantalla que queda puesta mientras carga la segunda parte
    v = vram_de_fase(img, FASES[7][2])
    v[0x1800:0x1B00] = img[PANTALLA_FIN:PANTALLA_FIN + 0x300]
    f = os.path.join(sal, "p1_fin.png")
    pinta(v, f)
    print(f"  {f}  (el resumen: DINERO, COMIDA, AGUA, VINO, MADERA, TELA "
          "y MARINERO)")
    # La misma pantalla con cada pareja de cifras pintada de un color: es la
    # medida de que contador es cada rotulo. Las baldosas 188 a 201 son las
    # catorce cifras, en el orden en que las pinta el bucle de 0x5D0C.
    f = os.path.join(sal, "p1_fin_marcado.png")
    marca_las_cifras(v, f)
    print(f"  {f}  (que contador es cada rotulo: 0xF8B4 rojo, 0xF8B5 verde,"
          " 0xF8B6 azul, 0xF8B7 amarillo, 0xF8B8 magenta, 0xF8B9 cian,"
          " 0xF8BA naranja)")


def segunda_parte(work, sal):
    """El mapa de la travesia: 128 columnas x 52 filas, con scroll en las dos.

    El juego lo lee en 0x9000 con paso de 0x80 por fila (sub_4285) y vuelca 24
    filas de 32 baldosas. Aqui se dibuja ENTERO, que es lo que no se ve nunca en
    pantalla.
    """
    img = open(os.path.join(work, "p2.img"), "rb").read()
    v = bytearray(0x4000)
    v[0x0000:0x1800] = img[0x8000:0x8000 + 0x800] * 3
    v[0x2000:0x3800] = img[0x8800:0x8800 + 0x800] * 3

    ANCHO, ALTO = 128, 52
    px = [[14] * (ANCHO * 8) for _ in range(ALTO * 8)]
    for fila in range(ALTO):
        for col in range(ANCHO):
            n = img[0x9000 + fila * ANCHO + col]
            p, c = n * 8, 0x2000 + n * 8
            for y in range(8):
                bits, cc = v[p + y], v[c + y]
                tinta, fondo = cc >> 4, cc & 15
                for x in range(8):
                    q = tinta if (bits >> (7 - x)) & 1 else fondo
                    px[fila * 8 + y][col * 8 + x] = q if q else 14
    rows = []
    for r in px:
        f = []
        for q in r:
            f += list(PAL[q])
        rows.append(f)
    f = os.path.join(sal, "p2_mapa.png")
    png(f, ANCHO * 8, ALTO * 8, rows)
    print(f"  {f}  (mapa de la travesia, {ANCHO}x{ALTO} baldosas)")

    # La ventana con la que ARRANCA la segunda parte. La esquina no se elige a
    # ojo: son los dos primeros bytes de 0xCBC6, la tabla de posiciones de
    # partida que el arranque copia a 0xB02C, y coinciden con lo que tiene el
    # emulador nada mas cargar (columna 0x32, fila 0x10).
    col, fil = img[0xCBC6], img[0xCBC7]
    w = bytearray(v)
    for f_ in range(24):
        o = 0x9000 + (f_ + fil) * ANCHO + col
        w[0x1800 + f_ * 32:0x1800 + f_ * 32 + 32] = img[o:o + 32]
    f = os.path.join(sal, "p2_ventana.png")
    pinta(w, f, borde=7)
    print(f"  {f}  (lo que se ve al empezar: columna {col}, fila {fil})")

    # Los cuatro montones de carga de la bodega, con sus baldosas. Es lo que
    # demuestra que las rutinas de 0x4F94, 0x502A, 0x4FC0 y 0x4FF5 pintan
    # mercancia y no averias: salen toneles, sacos, tablones y rollos de tela.
    grupos = [("toneles de bebida", [0xBF, 0xC0, 0xC1, 0xC2, 0xC3, 0xC4]),
              ("sacos de comida", [0xB9, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE]),
              ("tablones de madera", [0xC6, 0xC7, 0xC8]),
              ("rollos de tela", [0xC5, 0xC9, 0xCA])]
    esc, ancho = 6, max(len(g[1]) for g in grupos) * 9
    px = [[15] * ancho for _ in range(len(grupos) * 9)]
    for gi, (_, bs) in enumerate(grupos):
        for bi, n in enumerate(bs):
            for y in range(8):
                bits, c = img[0x8000 + n * 8 + y], img[0x8800 + n * 8 + y]
                tinta, fondo = c >> 4, c & 15
                for x in range(8):
                    q = tinta if (bits >> (7 - x)) & 1 else fondo
                    px[gi * 9 + y][bi * 9 + x] = q or 14
    rows = []
    for r in px:
        fl = []
        for q in r:
            fl += list(PAL[q]) * esc
        for _ in range(esc):
            rows.append(fl)
    f = os.path.join(sal, "p2_carga.png")
    png(f, ancho * esc, len(grupos) * 9 * esc, rows)
    print(f"  {f}  (la carga de la bodega, una fila por monton: "
          + ", ".join(g[0] for g in grupos) + ")")

    # Las dos pantallas fijas de la segunda parte. Las dos se muestran DESPUES
    # de sub_5889 (0x5889), que cambia la fuente entera: patrones a 0xB958 y
    # colores a 0xC158. Dibujarlas con los patrones del mapa da un galimatias,
    # y ese fue el primer intento.
    for nombre, name, pat, col in (("p2_carta", 0xB358, 0xB958, 0xC158),
                                   ("p2_final", 0xB658, 0xB958, 0xC158)):
        w = bytearray(0x4000)
        w[0x0000:0x1800] = img[pat:pat + 0x800] * 3
        w[0x2000:0x3800] = img[col:col + 0x800] * 3
        w[0x1800:0x1B00] = img[name:name + 0x300]
        f = os.path.join(sal, nombre + ".png")
        pinta(w, f)
        print(f"  {f}")


def cargador(work, sal):
    """La pantalla de carga: 0xC000 patrones, 0xC800 colores, 0xD000 nombres."""
    c = open(os.path.join(work, "carga.bin"), "rb").read()
    v = bytearray(0x4000)
    v[0x0000:0x1800] = c[0x0000:0x0800] * 3
    v[0x2000:0x3800] = c[0x0800:0x1000] * 3
    v[0x1800:0x1B00] = c[0x1000:0x1300]
    f = os.path.join(sal, "carga.png")
    pinta(v, f, borde=7)
    print(f"  {f}  (pantalla de carga)")


def main():
    work, sal = sys.argv[1], sys.argv[2]
    os.makedirs(sal, exist_ok=True)
    cargador(work, sal)
    primera_parte(work, sal)
    segunda_parte(work, sal)


if __name__ == "__main__":
    main()
