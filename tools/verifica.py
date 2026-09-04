#!/usr/bin/env python3
"""Reproducibilidad: ensamblar los listados tiene que devolver la cinta exacta.

Es el criterio que decide si el desensamblado vale. Mientras esto no este en
verde, cualquier cosa que se afirme del juego se afirma a ciegas.

Se hace en dos tiempos:

  1. cada listado ensambla y da exactamente el trozo de cinta que le toca;
  2. envolviendo los trozos como los envuelve el .cas -centinela de ocho bytes
     alineado, cabeceras de fichero, los tres bytes de sincronia de los bloques
     sin cabecera y el relleno de alineacion- sale el fichero .cas ENTERO, con
     su sha256.

El segundo paso es el que cierra el circulo: el primero solo dice que los
listados son consistentes con lo que les hemos dado de comer.

Uso: verifica.py <dir_src> <dir_work> <cinta.cas>
"""
import hashlib
import json
import os
import subprocess
import sys

MARCA = bytes.fromhex("1FA6DEBACC137D74")
PASMO = r"C:/Users/Antxiko/AppData/Local/Programs/pasmo/pasmo.exe"
LISTADOS = ["carga", "p1bajo", "p1alto", "p2bajo", "p2alto"]


def ensambla(asm, out, work):
    exe = PASMO if os.path.exists(PASMO) else "pasmo"
    env = dict(os.environ, TMP=work, TEMP=work)
    r = subprocess.run([exe, "--bin", asm, out], capture_output=True,
                       text=True, env=env)
    return r.returncode, (r.stderr or r.stdout)


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    src, work, cas = sys.argv[1], sys.argv[2], sys.argv[3]
    mod = json.load(open(os.path.join(work, "modulos.json")))
    fallos = 0
    hechos = {}

    print("=" * 70)
    print(" 1) cada listado ensambla y da su trozo de cinta, byte a byte")
    print("=" * 70)
    for L in LISTADOS:
        asm = os.path.join(src, f"descubrimiento_{L}.asm")
        ref = open(os.path.join(work, mod[L]["fichero"]), "rb").read()
        out = os.path.join(work, f"{L}.pasmo.bin")
        rc, err = ensambla(asm, out, work)
        if rc:
            print(f"  {L:8s} FALLO: pasmo no ensambla")
            for ln in err.splitlines()[:8]:
                print(f"      {ln}")
            fallos += 1
            continue
        got = open(out, "rb").read()
        hechos[L] = got
        if got == ref:
            print(f"  {L:8s} OK   {len(got):6d} bytes  "
                  f"{hashlib.sha256(got).hexdigest()[:16]}")
        else:
            prim = next((i for i in range(min(len(got), len(ref)))
                         if got[i] != ref[i]), None)
            print(f"  {L:8s} DIFIERE: {len(got)} bytes contra {len(ref)}")
            if prim is not None:
                print(f"      primera diferencia en el byte {prim} "
                      f"({mod[L]['org'] + prim:#06x}): sale {got[prim]:#04x}, "
                      f"deberia ser {ref[prim]:#04x}")
            fallos += 1

    if fallos:
        print(f"\n{fallos} listados sin reproducir. No sigo.")
        return 1

    print()
    print("=" * 70)
    print(" 2) envolviendo los trozos sale la cinta entera")
    print("=" * 70)
    inv = json.load(open(os.path.join(work, "..", "extracted",
                                      "inventario.json")))
    d = open(cas, "rb").read()

    rehecho = bytearray()
    ipar = 0
    for e in inv:
        if e["clase"] == "ASCII":
            cuerpo = open(os.path.join(work, "..", "extracted",
                                       e["fichero"]), "rb").read()
            rehecho += MARCA + bytes([0xEA] * 10) + e["nombre"].ljust(6).encode()
            for k in range(0, len(cuerpo), 256):
                rehecho += MARCA + cuerpo[k:k + 256]
        elif e["clase"] == "BIN":
            rehecho += MARCA + bytes([0xD0] * 10) + e["nombre"].ljust(6).encode()
            tres = (e["load"].to_bytes(2, "little")
                    + e["end"].to_bytes(2, "little")
                    + e["exec"].to_bytes(2, "little"))
            rehecho += MARCA + tres + hechos["carga"]
            rehecho += bytes(e["relleno"])
        else:                                   # bloque sin cabecera
            ipar += 1
            p = f"p{ipar}"
            rehecho += MARCA + bytes([3, 2, 1]) + hechos[p + "bajo"] \
                + hechos[p + "alto"] + bytes(mod[p + "_relleno"])

    rehecho = bytes(rehecho)
    ha = hashlib.sha256(rehecho).hexdigest()
    hb = hashlib.sha256(d).hexdigest()
    print(f"  .cas rehecho : {len(rehecho):6d} bytes  {ha}")
    print(f"  .cas original: {len(d):6d} bytes  {hb}")
    if rehecho == d:
        print("  OK: la cinta entera se reproduce byte a byte")
    else:
        prim = next((i for i in range(min(len(rehecho), len(d)))
                     if rehecho[i] != d[i]), len(d))
        print(f"  DIFIERE (primera diferencia en el offset {prim:#x})")
        fallos += 1

    return 1 if fallos else 0


if __name__ == "__main__":
    sys.exit(main())
