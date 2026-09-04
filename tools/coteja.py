#!/usr/bin/env python3
"""Compara lo que dice el desensamblado con lo que hace la maquina de verdad.

Mirar la imagen no basta: un dibujo puede salir bonito y estar mal montado. Lo
que cierra el asunto es volcar la RAM y la VRAM de openMSX con el juego en
marcha y comparar byte a byte.

Se comprueban dos cosas:

  1. EL REPARTO DE LA CINTA. El cargador de 0xD369 dice que el bloque sin
     cabecera se parte en 0x2400 bytes a 0x4000 y 0x5300 a 0x8000. Si eso es
     cierto, la RAM de la maquina tiene que traer exactamente los bytes de la
     cinta en esas dos direcciones.

  2. LA GEOMETRIA DE LA PANTALLA. tools/dibuja.py monta la VRAM de la primera
     pantalla repitiendo las tres rutinas de volcado; aqui se compara con la
     VRAM real. Los sprites y la tabla de atributos se dejan fuera porque el
     juego los mueve en cada cuadro.

Uso: coteja.py <dir_work>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dibuja import COMUN, FASES, vram_de_fase   # noqa: E402


def compara(nombre, a, b, tolerancia=0):
    d = sum(1 for x, y in zip(a, b) if x != y)
    marca = "OK  " if d <= tolerancia else "MAL "
    print(f"  {marca} {nombre:38s} {len(a):6d} bytes, {d} distintos")
    return d <= tolerancia


def main():
    work = sys.argv[1]
    omsx = os.path.join(work, "omsx")
    ram = os.path.join(omsx, "ram64k.bin")
    vram = os.path.join(omsx, "vram.bin")
    if not (os.path.exists(ram) and os.path.exists(vram)):
        print("  no hay volcado de openMSX en work/omsx; nada que cotejar")
        print("  (se genera con tools/omsx_carga.tcl)")
        return 0

    ram = open(ram, "rb").read()
    vram = open(vram, "rb").read()
    bajo = open(os.path.join(work, "p1bajo.bin"), "rb").read()
    alto = open(os.path.join(work, "p1alto.bin"), "rb").read()
    img = open(os.path.join(work, "p1.img"), "rb").read()
    carga = open(os.path.join(work, "carga.bin"), "rb").read()

    print("=" * 70)
    print(" El reparto de la cinta, contra la RAM de la maquina")
    print("=" * 70)
    # El trozo alto y el cargador NO salen a cero diferencias, y esta bien que
    # sea asi: el juego escribe encima de una parte de sus propios datos.
    #   - 0x915B, una baldosa de la pantalla 5 que retoca el arranque;
    #   - 0x9E05-0x9E53, los sprites, que la rutina de 0x4B1E voltea EN MEMORIA
    #     para dibujar al muñeco mirando al otro lado;
    #   - 0xD3D5 y 0xD3D7, los dos punteros de trabajo del copiador de 0xD3B2.
    # Cualquier otra diferencia si seria una contradiccion.
    ok = True
    ok &= compara("0x4000-0x63FF = trozo bajo del bloque",
                  ram[0x4000:0x6400], bajo)
    ok &= compara("0x8000-0xD2FF = trozo alto (45 bytes que el juego pisa)",
                  ram[0x8000:0xD300], alto, tolerancia=45)
    ok &= compara("0xD300-0xD3DF = el cargador (2 bytes de trabajo)",
                  ram[0xD300:0xD3E0], carga[0xD300 - 0xC000:], tolerancia=2)
    pisados = [0x8000 + i for i in range(len(alto))
               if ram[0x8000 + i] != alto[i]]
    esperados = ([0x915B] + list(range(0x9E05, 0x9E07))
                 + list(range(0x9E0D, 0x9E0F))
                 + [a for k in range(8)
                    for a in range(0x9E17 + k * 8, 0x9E1C + k * 8)])
    igual = pisados == esperados
    print(f"  {'OK  ' if igual else 'MAL '} "
          f"{'y los pisados son los que se esperan':38s} "
          f"{len(pisados)} direcciones")
    if not igual:
        print("       sobran: " + " ".join(f"{a:#06x}" for a in pisados
                                           if a not in esperados)[:200])
    ok &= igual

    print()
    print("=" * 70)
    print(" La pantalla 0 montada desde la cinta, contra la VRAM")
    print("=" * 70)
    v = vram_de_fase(img, FASES[0][2])
    v[0x1800:0x1B00] = img[FASES[0][1]:FASES[0][1] + 0x300]

    # LO QUE SE DEJA FUERA, Y POR QUE. Tres cosas de la pantalla no vienen de
    # la cinta sino que las escribe el juego mientras corre, asi que compararlas
    # no diria nada:
    #   - las filas 18 y 19 de la tabla de nombres: el oleaje, que la rutina de
    #     0x4537 reescribe entre 0x1A40 y 0x1A60 en cada vuelta;
    #   - las baldosas 199 en adelante del tercer tercio: la franja de texto de
    #     abajo, que la rutina de 0x5A91 borra desde la VRAM 0x1638 -que es la
    #     baldosa 199 del tercio 2- y luego rellena con la fuente de la ROM;
    #   - los sprites y su tabla de atributos, que cambian en cada cuadro.
    OLAS = (18, 19)
    PRIMERA_DE_TEXTO = 0x638 // 8          # 199
    difp = difc = 0
    for fila in range(24):
        if fila in OLAS:
            continue
        t = fila // 8
        for col in range(32):
            n = vram[0x1800 + fila * 32 + col]
            if t == 2 and n >= PRIMERA_DE_TEXTO:
                continue
            for y in range(8):
                pa = t * 0x800 + n * 8 + y
                ca = 0x2000 + pa
                difp += v[pa] != vram[pa]
                difc += v[ca] != vram[ca]
    nombres = [0x1800 + f * 32 + c for f in range(24) if f not in OLAS
               for c in range(32)]
    ok &= compara("tabla de nombres, sin la franja del oleaje",
                  bytes(v[a] for a in nombres),
                  bytes(vram[a] for a in nombres))
    print(f"  {'OK  ' if not difp else 'MAL '} "
          f"{'patrones de las baldosas que se ven':38s} {difp} distintos")
    print(f"  {'OK  ' if not difc else 'MAL '} "
          f"{'colores de las baldosas que se ven':38s} {difc} distintos")
    ok &= (difp == 0 and difc == 0)

    ok &= segunda_parte(work, omsx)

    print()
    print("  " + ("OK: la maquina dice lo mismo que el desensamblado"
                  if ok else "HAY DIFERENCIAS: revisar"))
    return 0 if ok else 1


def segunda_parte(work, omsx):
    """El mapa del barco y las dos fuentes, contra la maquina.

    A la segunda parte no se llega jugando de forma automatica, pero tampoco
    hace falta: tools/omsx_parte2.tcl salta a (0xD300) en cuanto la primera
    esta en marcha, que es exactamente lo que hace el juego al terminarla.

    Aqui lo que de verdad se comprueba es el mapa: que la tabla de nombres que
    el juego tiene puesta es EL RECORTE de 32x24 del mapa de 128x52 por la
    columna 0xF88F y la fila 0xF890. Si el ancho de 128 estuviera mal, esto
    saldria a cientos de bytes de diferencia.
    """
    ram = os.path.join(omsx, "ram64k_2.bin")
    vram = os.path.join(omsx, "vram2.bin")
    if not (os.path.exists(ram) and os.path.exists(vram)):
        return True
    ram = open(ram, "rb").read()
    vram = open(vram, "rb").read()
    bajo = open(os.path.join(work, "p2bajo.bin"), "rb").read()
    alto = open(os.path.join(work, "p2alto.bin"), "rb").read()

    print()
    print("=" * 70)
    print(" La SEGUNDA parte, contra la maquina")
    print("=" * 70)
    ok = compara("0x4000-0x63FF = trozo bajo del bloque",
                 ram[0x4000:0x6400], bajo)
    # 0xB000-0xB001 es la ficha del barco que se lleva, y 0xB058-0xB357 es la
    # copia de trabajo de la pantalla: los dos los escribe el juego.
    pisados = [0x8000 + i for i in range(len(alto))
               if ram[0x8000 + i] != alto[i]]
    fuera = [a for a in pisados if not (0xB000 <= a <= 0xB001
                                        or 0xB058 <= a < 0xB358)]
    print(f"  {'OK  ' if not fuera else 'MAL '} "
          f"{'0x8000-0xD2FF: lo pisado cae en las dos zonas de trabajo':38s} "
          f"{len(pisados)} bytes")
    if fuera:
        print("       fuera de sitio: "
              + " ".join(f"{a:#06x}" for a in fuera[:12]))
    ok &= not fuera

    ok &= compara("patrones de la fuente del barco, los tres tercios",
                  vram[0x0000:0x1800], alto[0x0000:0x0800] * 3)

    col, fil = ram[0xF88F], ram[0xF890]
    mal = 0
    for f in range(24):
        for c in range(32):
            n = alto[0x9000 - 0x8000 + (f + fil) * 128 + (c + col)]
            mal += vram[0x1800 + f * 32 + c] != n
    print(f"  {'OK  ' if not mal else 'MAL '} "
          f"{'la ventana del mapa de 128x52':38s} "
          f"768 baldosas desde la columna {col} y la fila {fil}, "
          f"{mal} distintas")
    ok &= mal == 0
    return ok


if __name__ == "__main__":
    sys.exit(main())
