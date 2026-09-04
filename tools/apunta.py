#!/usr/bin/env python3
"""Que direcciones de la zona de datos toca el codigo, y desde donde.

Recorre SOLO las instrucciones que el trazador marco como codigo (para no
inventarse operandos leyendo dibujos) y anota cada inmediato de 16 bits y cada
direccion absoluta que caiga en el rango pedido. Es el punto de partida para
saber donde empieza y acaba cada tabla, en vez de adivinar geometrias.

Uso: apunta.py <imagen> <trace.json> <ini> <fin>
"""
import json
import sys

from z80trace import BASE_LEN, ED_LEN4, IDX_DISP

# Inmediatos de 16 bits: LD rr,nn y LD (nn),x / LD x,(nn)
INM16 = {0x01: "ld bc,", 0x11: "ld de,", 0x21: "ld hl,", 0x31: "ld sp,"}
ABS = {0x22: "ld (nn),hl", 0x2A: "ld hl,(nn)",
       0x32: "ld (nn),a", 0x3A: "ld a,(nn)"}
SALTO = {0xC3: "jp", 0xCD: "call"}


def ilen(d, a):
    op = d[a]
    if op == 0xCB:
        return 2
    if op == 0xED:
        return 4 if d[a + 1] in ED_LEN4 else 2
    if op in (0xDD, 0xFD):
        o2 = d[a + 1]
        if o2 == 0xCB:
            return 4
        if o2 in (0xDD, 0xFD, 0xED):
            return 1
        return 1 + BASE_LEN[o2] + (1 if o2 in IDX_DISP else 0)
    return BASE_LEN[op]


def main():
    d = open(sys.argv[1], "rb").read()
    tr = json.load(open(sys.argv[2]))
    lo, hi = int(sys.argv[3], 0), int(sys.argv[4], 0)
    hits = {}
    for k, a, b in tr["blocks"]:
        if k != "c":
            continue
        pc = a
        while pc < b:
            n = ilen(d, pc)
            op = d[pc]
            pref = 0
            if op in (0xDD, 0xFD) and d[pc + 1] in INM16:
                pref, op = 1, d[pc + 1]
            if op in INM16 and n >= 3 + pref:
                w = d[pc + 1 + pref] | d[pc + 2 + pref] << 8
                if lo <= w < hi:
                    hits.setdefault(w, []).append((pc, INM16[op]))
            elif op in ABS:
                w = d[pc + 1] | d[pc + 2] << 8
                if lo <= w < hi:
                    hits.setdefault(w, []).append((pc, ABS[op]))
            elif op in SALTO:
                w = d[pc + 1] | d[pc + 2] << 8
                if lo <= w < hi:
                    hits.setdefault(w, []).append((pc, SALTO[op]))
            pc += n or 1
    for w in sorted(hits):
        quien = ", ".join(f"{a:04x}:{k}" for a, k in hits[w][:6])
        print(f"  {w:04x}  ({len(hits[w])})  {quien}")
    print(f"{len(hits)} direcciones distintas en {lo:#06x}..{hi:#06x}")


if __name__ == "__main__":
    main()
