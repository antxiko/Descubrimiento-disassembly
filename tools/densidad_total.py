#!/usr/bin/env python3
"""Densidad de comentarios de TODOS los listados, y el liston de la serie.

El liston, que cumplen los desensamblados publicados: la densidad global tiene
que llegar al 22 % de las instrucciones comentadas Y no puede quedar ninguna
rutina por debajo del 10 %. Lo segundo es lo que impide aprobar por la via de
comentar mucho tres rutinas y nada las demas.

Una rutina con nombre y cero comentarios esta BAUTIZADA, no explicada.

Uso: densidad_total.py <dir_src> [minimo_instrucciones_por_rutina]
Codigo de salida 1 si no se llega al liston.
"""
import os
import re
import sys

LISTON = 22.0
FLOJA = 10.0


def mide(path, minimo):
    lineas = open(path, encoding="utf-8").read().splitlines()
    bloques, nombre, n, c = [], "(cabecera)", 0, 0
    for ln in lineas:
        m = re.match(r"^([A-Za-z_][A-Za-z_0-9]*):\s*(;.*)?$", ln)
        if m:
            if n:
                bloques.append((nombre, n, c))
            nombre, n, c = m.group(1), 0, 0
            continue
        m = re.match(r"^\t.*;([0-9a-f]{4})(.*)$", ln)
        if not m:
            continue
        n += 1
        if m.group(2).strip():
            c += 1
    if n:
        bloques.append((nombre, n, c))
    tot = sum(b[1] for b in bloques)
    com = sum(b[2] for b in bloques)
    flojas = [b for b in bloques if b[1] >= minimo and 100.0 * b[2] / b[1] < FLOJA]
    return tot, com, len(bloques), flojas


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    src = sys.argv[1]
    minimo = int(sys.argv[2]) if len(sys.argv) > 2 else 6
    T = C = R = 0
    todas_flojas = []
    print(f"  {'listado':14s} {'instr':>7s} {'coment':>7s} {'densidad':>9s} "
          f"{'rutinas':>8s} {'flojas':>7s}")
    print("  " + "-" * 60)
    for fn in sorted(os.listdir(src)):
        if not fn.endswith(".asm"):
            continue
        tot, com, rut, flojas = mide(os.path.join(src, fn), minimo)
        if not tot:
            continue
        T += tot
        C += com
        R += rut
        todas_flojas += [(fn, *f) for f in flojas]
        print(f"  {fn[15:-4]:14s} {tot:7d} {com:7d} "
              f"{100.0*com/tot:8.1f}% {rut:8d} {len(flojas):7d}")
    print("  " + "=" * 60)
    d = 100.0 * C / T if T else 0
    print(f"  {'TOTAL':14s} {T:7d} {C:7d} {d:8.1f}% {R:8d} "
          f"{len(todas_flojas):7d}")
    print()
    print(f"  liston de la serie: densidad >= {LISTON:.0f} % "
          f"Y cero rutinas por debajo del {FLOJA:.0f} %")
    ok = d >= LISTON and not todas_flojas
    if todas_flojas:
        print(f"  {len(todas_flojas)} rutinas flojas (de {minimo} instrucciones "
              f"o mas). Las 25 mas gordas:")
        for fn, nom, n, c in sorted(todas_flojas, key=lambda x: -x[2])[:25]:
            print(f"    {fn[15:-4]:12s} {nom:24s} {n:5d} instr, {c:3d} coment")
    print()
    print("  " + ("OK: se llega al liston" if ok else "NO se llega al liston"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
