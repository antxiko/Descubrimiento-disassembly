#!/usr/bin/env python3
"""Reparte los bloques de la cinta en los modulos que se desensamblan.

La cinta trae cuatro ficheros (ver work/cas_parse.log):

  00  ASCII  'DSCRMT'   el cargador BASIC de una linea
  02  BIN    'CARGA '   0xC000-0xD3DF, arranca en 0xD302
  04  sin cabecera      30472 bytes: el programa de la PRIMERA parte
  05  sin cabecera      30467 bytes: el programa de la SEGUNDA parte

Los dos bloques sin cabecera no llevan direccion de carga porque no los lee la
BIOS: los lee el codigo de 0xD369 con TAPION/TAPIN byte a byte. Ese codigo dice
exactamente como se reparten, y de ahi sale este fichero:

  - tres bytes de sincronia 03 02 01, que el cargador consume antes de nada
    (bucle de 0xD36C: espera 3, luego 2, luego 1);
  - 0x2400 bytes a 0x4000-0x63FF  (bucle de 0xD38A, hasta DE=0x6400);
  - 0x5300 bytes a 0x8000-0xD2FF  (bucle de 0xD39D, hasta DE=0xD300).

La suma da 3+9216+21248 = 30467, que es EXACTAMENTE el bloque 05. El bloque 04
mide cinco bytes mas: son relleno de alineacion a 8 del .cas, ceros, y aqui se
anotan como tales.

Ademas monta la imagen de 64 KB de cada parte, que es lo que hace falta para
trazar: el codigo de 0x4000 llama a rutinas de 0x5xxx y lee datos de 0x8000
arriba, asi que el trazador tiene que ver las dos mitades a la vez, y ademas el
cargador de 0xD300 sigue vivo debajo (el segundo bloque se para en 0xD2FF).

Uso: cuerpos.py <dir_extracted> <dir_work>
"""
import hashlib
import json
import os
import sys

SYNC = bytes([3, 2, 1])
TROZOS = [("bajo", 0x4000, 0x2400), ("alto", 0x8000, 0x5300)]
PARTES = [("p1", "04_sincab.bin"), ("p2", "05_sincab.bin")]
CARGA = "02_CARGA.bin"
CARGA_ORG = 0xC000


def main():
    ext, work = sys.argv[1], sys.argv[2]
    os.makedirs(work, exist_ok=True)
    mod = {}

    # --- el fichero BIN con nombre -----------------------------------------
    carga = open(os.path.join(ext, CARGA), "rb").read()
    open(os.path.join(work, "carga.bin"), "wb").write(carga)
    mod["carga"] = dict(org=CARGA_ORG, bytes=len(carga), bloque="02",
                        off=0, fichero="carga.bin")
    print(f"  carga    org {CARGA_ORG:#06x}  {len(carga):6d} B  "
          f"{hashlib.sha256(carga).hexdigest()[:16]}")

    # --- los dos bloques sin cabecera --------------------------------------
    for parte, fn in PARTES:
        raw = open(os.path.join(ext, fn), "rb").read()
        if raw[:3] != SYNC:
            sys.exit(f"{fn}: no empieza por la sincronia 03 02 01")
        pos = 3
        img = bytearray(0x10000)
        for nombre, org, n in TROZOS:
            cuerpo = raw[pos:pos + n]
            if len(cuerpo) != n:
                sys.exit(f"{fn}: faltan bytes para el trozo {nombre}")
            m = f"{parte}{nombre}"
            open(os.path.join(work, m + ".bin"), "wb").write(cuerpo)
            img[org:org + n] = cuerpo
            mod[m] = dict(org=org, bytes=n, bloque=fn[:2], off=pos,
                          fichero=m + ".bin")
            print(f"  {m:8s} org {org:#06x}  {n:6d} B  "
                  f"cinta[{pos:#07x}]  {hashlib.sha256(cuerpo).hexdigest()[:16]}")
            pos += n
        sobra = raw[pos:]
        if sobra and set(sobra) != {0}:
            sys.exit(f"{fn}: los {len(sobra)} bytes de cola no son ceros")
        print(f"           relleno de alineacion: {len(sobra)} bytes")
        # el cargador sigue residente debajo: 0xD300-0xD3DF no se pisa
        img[0xD300:0xD3E0] = carga[0xD300 - CARGA_ORG:]
        open(os.path.join(work, parte + ".img"), "wb").write(bytes(img))
        mod[parte + "_relleno"] = len(sobra)

    json.dump(mod, open(os.path.join(work, "modulos.json"), "w"), indent=1)
    print(f"  -> {os.path.join(work, 'modulos.json')}")


if __name__ == "__main__":
    main()
