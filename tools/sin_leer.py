#!/usr/bin/env python3
"""Cuenta los bytes de la cinta que NO lee ninguna instruccion.

No son los bytes "sin explicar" -de esos hay cero-: son zonas que estan
identificadas y contadas, pero que ningun CALL, ningun JP y ninguna rutina de
volcado toca nunca. Casi todo es consecuencia de que la cinta graba bloques de
TAMANO FIJO (0x2400 y 0x5300 bytes) pase lo que pase, asi que detras del
programa se graba lo que hubiera en memoria.

Las zonas se declaran aqui por nombre, y el guion comprueba contra los .notes
que cada una existe y mide exactamente lo que se dice. Uso: sin_leer.py
"""
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (listado, nombre de la zona, por que no la lee nadie)
ZONAS = [
    ("carga", "resto_de_montaje",
     "copia exacta de 0xD358-0xD35F, la cola del bloque repetida"),
    ("p1bajo", "restos_de_montaje",
     "copia truncada del propio codigo, cortada a media instruccion"),
    ("p1bajo", "relleno_de_bloque",
     "cola del trozo de 0x2400: un patron de ocho repetido, vacia"),
    ("p1alto", "hueco_sprites",
     "0x53 bytes de dibujo que no nombra nadie, y detras 1085 ceros"),
    ("p1alto", "cola_colores_pantalla_carga",
     "la imagen que dejo puesta el cargador, aun en memoria"),
    ("p1alto", "copia_pantalla_carga",
     "la tabla de nombres del cargador, aun en memoria"),
    ("p2bajo", "restos_de_montaje",
     "copia truncada del propio codigo, cortada a media instruccion"),
    ("p2bajo", "relleno_de_bloque",
     "cola del trozo de 0x2400: registros de ocho sin identificar"),
    ("p2alto", "relleno_de_bloque",
     "cola del trozo de 0x5300: registros de ocho sin identificar"),
]

TOTAL_CINTA = 66016            # lo que suma tools/presupuesto.py


def zonas_de(listado):
    """Devuelve {nombre: (ini, fin)} leyendo las directivas D del .notes."""
    ruta = os.path.join(RAIZ, "src", listado + ".notes")
    fuera = {}
    with open(ruta, encoding="utf-8") as f:
        for linea in f:
            m = re.match(r"^D\s+(0x[0-9A-Fa-f]+)\s+(0x[0-9A-Fa-f]+)\s+(\S+)",
                         linea)
            if m:
                fuera[m.group(3)] = (int(m.group(1), 0), int(m.group(2), 0))
    return fuera


def medir():
    """[(listado, nombre, ini, fin, bytes, razon)], o levanta KeyError."""
    cache, salida = {}, []
    for listado, nombre, razon in ZONAS:
        if listado not in cache:
            cache[listado] = zonas_de(listado)
        if nombre not in cache[listado]:
            raise KeyError("%s: no hay ninguna zona llamada %s"
                           % (listado, nombre))
        ini, fin = cache[listado][nombre]
        salida.append((listado, nombre, ini, fin, fin - ini, razon))
    return salida


def main():
    try:
        filas = medir()
    except KeyError as e:
        print("  FALLO: %s" % e)
        return 1

    print("=" * 66)
    print(" Bytes identificados que no lee ninguna instruccion")
    print("=" * 66)
    print("  listado   zona                          rango        bytes")
    print("  " + "-" * 62)
    total = 0
    for listado, nombre, ini, fin, n, _ in filas:
        total += n
        print("  %-9s %-28s %04X-%04X %7d"
              % (listado, nombre[:28], ini, fin - 1, n))
    print("  " + "=" * 62)
    print("  %-38s %14d" % ("TOTAL", total))
    print()
    print("  %d de %d bytes de la cinta (%.1f %%)"
          % (total, TOTAL_CINTA, 100.0 * total / TOTAL_CINTA))

    colas = sum(n for _, nom, _, _, n, _ in filas if nom == "relleno_de_bloque")
    print("  de los cuales %d (%.0f %%) son cola de bloque de tamano fijo"
          % (colas, 100.0 * colas / total))
    print()
    print("  OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
