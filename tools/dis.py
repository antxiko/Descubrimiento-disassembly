#!/usr/bin/env python3
"""Desensambla un trozo de un binario en su direccion real. Herramienta de mano.

    dis.py <bin> <org_del_fichero> <ini> <fin>

Todo en hexadecimal o decimal (0x...). El temporal va al work/ del proyecto:
en Windows z80dasm casca si le toca el temporal del sistema.
"""
import os
import subprocess
import sys

Z80DASM = r"C:/Users/Antxiko/AppData/Local/Programs/pasmo/z80dasm.exe"
WORK = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "work")


def main(binpath, org, ini, fin, symfile=None):
    org, ini, fin = int(org, 0), int(ini, 0), int(fin, 0)
    data = open(binpath, "rb").read()
    blob = data[ini - org:fin - org]
    os.makedirs(WORK, exist_ok=True)
    tmp = os.path.join(WORK, "_dis.bin")
    open(tmp, "wb").write(blob)
    env = dict(os.environ, TMP=WORK, TEMP=WORK)
    cmd = [Z80DASM, "-a", "-l", "-t", "-g", hex(ini), tmp]
    if symfile and os.path.exists(symfile):
        cmd += ["-S", symfile]
    r = subprocess.run(cmd, capture_output=True, text=True, env=env)
    if r.returncode != 0:
        sys.exit(f"z80dasm fallo: {r.stderr}")
    for l in r.stdout.splitlines():
        if l.startswith("; z80dasm") or l.startswith("; command line"):
            continue
        print(l)


if __name__ == "__main__":
    main(*sys.argv[1:6])
