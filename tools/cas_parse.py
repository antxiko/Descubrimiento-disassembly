#!/usr/bin/env python3
"""Parser de .cas (imagen de cinta MSX en crudo) -> inventario + extraccion de ficheros.

Un .cas no guarda la modulacion: guarda los BYTES que el MSX habria leido, y
marca donde empieza cada bloque con un centinela de ocho bytes,
`1F A6 DE BA CC 13 7D 74`, SIEMPRE alineado a multiplo de 8. Esa alineacion es
la que hace fiable el troceo: la misma secuencia dentro de los datos, si cae
desalineada, no es un separador. (Aqui se comprueba de las dos formas y se
avisa si aparece desalineada, por si algun dia hay que revisarlo.)

Quitado el envoltorio, lo que queda es la MISMA capa de fichero de cinta MSX
que ya usa tools/tsx_parse.py en los proyectos de TSX de la serie, y de ahi
esta copiada -sus offsets estan verificados contra makeTSX (nataliapc)-:

  - cabecera de fichero: 10 bytes iguales (0xD3 = BASIC tokenizado, 0xD0 =
    binario, 0xEA = ASCII) seguidos de 6 bytes de nombre;
  - en un fichero BIN, el bloque de datos empieza con tres words en little
    endian: direccion de carga, direccion final (inclusive) y direccion de
    ejecucion. El cuerpo son (fin - carga + 1) bytes.

Diferencia con el TSX que conviene tener presente: un fichero ASCII no viene
en un bloque, sino en TROZOS DE 256 BYTES, cada uno con su propio centinela, y
termina con 0x1A de relleno. Aqui se reunen en un solo fichero.

Y una advertencia que vale para todos los .cas: despues del ultimo fichero
"con nombre" puede haber bloques SIN cabecera. No son basura: son los trozos
que el propio juego se lee con su cargador, y ese cargador es quien sabe donde
van. Salen como `NN_sincab.bin` y hay que emparejarlos leyendo el codigo.

Ultimo detalle, y no es menor para cuadrar el presupuesto: como el centinela
del bloque siguiente tiene que caer en multiplo de 8, cada bloque lleva de 0 a
7 bytes de RELLENO al final que no forman parte del fichero. Aqui el cuerpo de
un BIN se recorta a los (fin - carga + 1) bytes que declara su cabecera y el
sobrante se anota como relleno en el inventario, para que despues no aparezca
como "bytes sin explicar".

Uso:  cas_parse.py <cinta.cas> [directorio_salida]
"""
import json
import os
import struct
import sys

MARCA = bytes.fromhex("1FA6DEBACC137D74")
MSX_HDR = {0xD3: "BASIC", 0xD0: "BIN", 0xEA: "ASCII"}


def u16(b, o):
    return struct.unpack_from("<H", b, o)[0]


class Blk:
    def __init__(self, idx, off, payload):
        self.idx, self.off, self.payload = idx, off, payload
        self.tipo = None      # "cabecera" / "datos" / None
        self.info = ""


def trocea(d):
    """Corta el .cas por el centinela alineado a 8. Devuelve (offset, bytes)."""
    pos, sueltas = [], 0
    i = 0
    while True:
        i = d.find(MARCA, i)
        if i < 0:
            break
        if i % 8 == 0:
            pos.append(i)
        else:
            sueltas += 1
        i += 1
    if sueltas:
        print(f"# aviso: {sueltas} apariciones del centinela DESALINEADAS "
              f"(ignoradas; son datos, no separadores)")
    if not pos:
        sys.exit("no es un .cas: no aparece el centinela de bloque")
    if pos[0] != 0:
        print(f"# aviso: {pos[0]} bytes antes del primer bloque")

    trozos = []
    for k, p in enumerate(pos):
        fin = pos[k + 1] if k + 1 < len(pos) else len(d)
        trozos.append((p, d[p + 8:fin]))
    return trozos


def parse(path):
    d = open(path, "rb").read()
    print(f"# CAS  fichero={os.path.basename(path)}  {len(d)} bytes\n")
    blocks = []
    for idx, (off, payload) in enumerate(trocea(d)):
        b = Blk(idx, off, payload)
        if (len(payload) >= 16 and payload[0] in MSX_HDR
                and payload[:10] == bytes([payload[0]]) * 10):
            b.tipo = "cabecera"
            b.clase = MSX_HDR[payload[0]]
            b.nombre = payload[10:16].decode("latin-1")
            b.info = f"CABECERA {b.clase} nombre='{b.nombre}'"
            if len(payload) > 16:
                b.info += f" (+{len(payload)-16} bytes pegados)"
        else:
            b.tipo = "datos"
            b.info = f"DATOS [{len(payload)} bytes]"
            if len(payload) >= 6:
                ld, end, exe = u16(payload, 0), u16(payload, 2), u16(payload, 4)
                if end >= ld and (end - ld + 1) == len(payload) - 6:
                    b.info += (f"  BIN load={ld:#06x} end={end:#06x} "
                               f"exec={exe:#06x} ({end - ld + 1} bytes de cuerpo)")
        print(f"[{idx:02d}] @{off:#07x} {b.info}")
        blocks.append(b)
    return blocks


def extract(blocks, outdir):
    """Empareja cabecera + datos y escribe ficheros con su nombre real.

    Un ASCII se reune de sus trozos de 256; un BIN o un BASIC salen del unico
    bloque de datos que sigue a su cabecera. Los bloques de datos que NO van
    detras de una cabecera se guardan aparte, numerados: son la carga que el
    juego se lee por su cuenta.
    """
    os.makedirs(outdir, exist_ok=True)
    inventario, n, i = [], 0, 0
    while i < len(blocks):
        b = blocks[i]
        if b.tipo != "cabecera":
            fn = f"{b.idx:02d}_sincab.bin"
            open(os.path.join(outdir, fn), "wb").write(b.payload)
            inventario.append({"idx": b.idx, "off": b.off, "clase": "SINCAB",
                               "fichero": fn, "bytes": len(b.payload)})
            print(f"  -> {fn}  ({len(b.payload)} bytes, sin cabecera)")
            n += 1
            i += 1
            continue

        nombre = b.nombre.strip() or f"blk{b.idx}"
        safe = "".join(c if c.isalnum() else "_" for c in nombre)
        cuerpo = b""
        usados = [b.idx]
        i += 1
        if b.clase == "ASCII":
            # trozos de 256 hasta el que trae el 0x1A de fin
            while i < len(blocks) and blocks[i].tipo == "datos":
                cuerpo += blocks[i].payload
                usados.append(blocks[i].idx)
                i += 1
                if cuerpo.endswith(b"\x1a" * 4) or b"\x1a" in cuerpo[-256:]:
                    break
        else:
            if i < len(blocks) and blocks[i].tipo == "datos":
                cuerpo = blocks[i].payload
                usados.append(blocks[i].idx)
                i += 1

        ent = {"idx": b.idx, "off": b.off, "clase": b.clase, "nombre": nombre,
               "bloques": usados, "bytes": len(cuerpo), "relleno": 0}
        if b.clase == "BIN" and len(cuerpo) >= 6:
            ld, end, exe = u16(cuerpo, 0), u16(cuerpo, 2), u16(cuerpo, 4)
            largo = end - ld + 1
            ent.update(load=ld, end=end, exec=exe)
            ent["relleno"] = len(cuerpo) - 6 - largo
            fn = f"{b.idx:02d}_{safe}.bin"
            open(os.path.join(outdir, fn), "wb").write(cuerpo[6:6 + largo])
            ent["fichero"] = fn
            ent["bytes"] = largo
            print(f"  -> {fn}  ({largo} bytes, BIN {ld:#06x}-{end:#06x} "
                  f"exec {exe:#06x}, relleno {ent['relleno']})")
        else:
            fn = f"{b.idx:02d}_{safe}.{b.clase.lower()}"
            open(os.path.join(outdir, fn), "wb").write(cuerpo)
            ent["fichero"] = fn
            print(f"  -> {fn}  ({len(cuerpo)} bytes, {b.clase})")
        inventario.append(ent)
        n += 1
    print(f"\n{n} ficheros en {outdir}/")
    return inventario


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    bl = parse(sys.argv[1])
    out = sys.argv[2] if len(sys.argv) > 2 else "extracted"
    print("\n== EXTRACCION ==")
    inv = extract(bl, out)
    json.dump(inv, open(os.path.join(out, "inventario.json"), "w"), indent=1)
    print(f"inventario -> {os.path.join(out, 'inventario.json')}")
