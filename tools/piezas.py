#!/usr/bin/env python3
"""Parte el trazado de la imagen de 64K en los dos trozos que trae la cinta.

Cada parte del juego se traza sobre la imagen de memoria entera -el codigo de
0x4000 salta dentro de si mismo pero lee tablas de 0x8000 arriba, y hay que
verlo todo junto-, pero se PUBLICA en dos listados, uno por trozo de cinta:
0x4000-0x63FF y 0x8000-0xD2FF. Aqui se recorta el mapa codigo/datos a cada
trozo.

OJO con el convenio: z80trace emite los bloques con el extremo derecho
EXCLUSIVO, [ini,fin), y mkasm los consume igual. Tratarlos como cerrados pierde
el ultimo byte de cada trozo.

Uso: piezas.py <dir_work>
"""
import json
import os
import sys

TROZOS = [("bajo", 0x4000, 0x2400), ("alto", 0x8000, 0x5300)]


def recorta(tr, lo, fin):
    bloques = []
    for k, a, b in tr["blocks"]:
        if b <= lo or a >= fin:
            continue
        bloques.append([k, max(a, lo), min(b, fin)])
    bloques.sort(key=lambda x: x[1])
    completo, cursor = [], lo
    for k, a, b in bloques:
        if a > cursor:
            completo.append(["d", cursor, a])
        completo.append([k, a, b])
        cursor = b
    if cursor < fin:
        completo.append(["d", cursor, fin])
    return completo


def main():
    work = sys.argv[1]
    for parte in ("p1", "p2"):
        tr = json.load(open(os.path.join(work, parte + ".trace.json")))
        for nombre, lo, n in TROZOS:
            fin = lo + n
            bl = recorta(tr, lo, fin)
            ent = [a for a in tr["entries"] if lo <= a < fin]
            ciegos = [b for b in tr.get("blind", []) if lo <= int(b[0], 16) < fin]
            json.dump(dict(report=tr.get("report", {}), entries=sorted(ent),
                           blind=ciegos, blocks=bl),
                      open(os.path.join(work, f"{parte}{nombre}.trace.json"), "w"),
                      indent=1)
            cod = sum(b - a for k, a, b in bl if k == "c")
            print(f"  {parte}{nombre:5s} {lo:#06x}+{n:5d}  codigo {cod:5d} B "
                  f"({100.0*cod/n:5.1f}%)  {len(ent)} etiquetas")


if __name__ == "__main__":
    main()
