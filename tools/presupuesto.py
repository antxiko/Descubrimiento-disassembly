#!/usr/bin/env python3
"""Presupuesto de la cinta: ni un byte sin explicar.

Por que este control y no el porcentaje de codigo trazado: de los 66 KB de esta
cinta, el codigo son ocho mil bytes por parte y todo lo demas son graficos,
pantallas y tablas. Un porcentaje de codigo bajo suena a trabajo a medias
cuando puede estar entero. Lo que mide el avance de verdad es que cada byte sea
una de estas dos cosas:

  - codigo que el trazador alcanza siguiendo el flujo desde los puntos de
    entrada, o
  - un byte dentro de un rango de datos IDENTIFICADO con una directiva D del
    fichero de notas, o sea con nombre y explicacion.

Y ES UN CONTROL DISTINTO DEL DE REPRODUCIBILIDAD. Un byte puede reensamblar
perfecto y estar sin explicar; o peor, estar mal explicado: si unos graficos se
marcan como codigo, el binario reensamblado sigue saliendo identico -los bytes
no cambian, solo su lectura- y el listado miente igual.

El envoltorio del .cas (centinelas, cabeceras de fichero, sincronia y relleno)
se cuenta aparte: no es del juego, es del formato, y lo explica cas_parse.py.

Uso: presupuesto.py <dir_work> <dir_src> <cinta.cas>
"""
import json
import os
import sys

LISTADOS = ["carga", "p1bajo", "p1alto", "p2bajo", "p2alto"]
SIN, CODIGO, DATOS = 0, 1, 2


def rangos_de_notas(path):
    out = []
    if not os.path.exists(path):
        return out
    for ln in open(path, encoding="utf-8"):
        ln = ln.strip()
        if not ln.startswith("D "):
            continue
        p = ln.split(None, 3)
        out.append((int(p[1], 0), int(p[2], 0)))
    return out


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    work, src, cas = sys.argv[1:4]
    mod = json.load(open(os.path.join(work, "modulos.json")))

    tot_cod = tot_dat = tot_sin = tot = 0
    pendientes = []
    print("  %-9s %7s %8s %8s %8s" % ("listado", "bytes", "codigo",
                                      "datos", "sin expl."))
    print("  " + "-" * 46)
    for L in LISTADOS:
        org, n = mod[L]["org"], mod[L]["bytes"]
        estado = bytearray(n)
        tr = json.load(open(os.path.join(work, f"{L}.trace.json")))
        for tipo, a, b in tr["blocks"]:
            if tipo != "c":
                continue
            for i in range(max(0, a - org), min(n, b - org)):
                estado[i] = CODIGO
        for a, b in rangos_de_notas(os.path.join(src, f"{L}.notes")):
            for i in range(max(0, a - org), min(n, b - org)):
                if estado[i] == SIN:
                    estado[i] = DATOS
        c, dd, s = (estado.count(CODIGO), estado.count(DATOS),
                    estado.count(SIN))
        print("  %-9s %7d %8d %8d %8d" % (L, n, c, dd, s))
        tot_cod += c
        tot_dat += dd
        tot_sin += s
        tot += n
        ini = None
        for i in range(n + 1):
            v = estado[i] if i < n else CODIGO
            if v == SIN and ini is None:
                ini = i
            elif v != SIN and ini is not None:
                pendientes.append((L, org + ini, org + i))
                ini = None

    print("  " + "=" * 46)
    print("  %-9s %7d %8d %8d %8d" % ("TOTAL", tot, tot_cod, tot_dat, tot_sin))
    print()
    print("  explicado: %d de %d bytes (%.2f %%)"
          % (tot_cod + tot_dat, tot, 100.0 * (tot_cod + tot_dat) / tot))

    # --- el envoltorio del .cas -------------------------------------------
    tam = os.path.getsize(cas)
    env = tam - tot
    print("  envoltorio del .cas (centinelas, cabeceras, sincronia y "
          "relleno): %d bytes" % env)
    print("  la cinta entera son %d bytes" % tam)

    if pendientes:
        print()
        print("  Sin explicar, por rangos:")
        for L, a, b in pendientes:
            print("    %-8s 0x%04X..0x%04X  (%d bytes)" % (L, a, b - 1, b - a))
        print()
        print("  Cada uno tiene que acabar dentro de una directiva D del")
        print("  fichero de notas, con que es y como se sabe.")
        return 1

    print()
    print("  OK: ni un byte de la cinta sin asignar")
    return 0


if __name__ == "__main__":
    sys.exit(main())
