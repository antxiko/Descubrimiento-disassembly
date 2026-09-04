# El Descubrimiento de America (Gema / OMK, 1987) — desensamblado comentado

Desensamblado completo y comentado de la cinta de MSX1 **El Descubrimiento de
America** (Gema Software / OMK Software, 1987), reproducible byte a byte.

**Web: <https://antxiko.github.io/Descubrimiento-disassembly/es/>** · [In English](README.md)

|  |  |
|---|---|
| De la cinta explicado | **100 %** — 0 bytes sin asignar, de 66.016 |
| Reensambla | **byte a byte**, al mismo sha256 |
| Listados comentados | **26,7 %** — 1.782 comentarios sobre 6.665 instrucciones |
| Rutinas por debajo del liston del 10 % | **0** de 733 |

## Cinco listados, no uno

La cinta trae **dos programas que ocupan las mismas direcciones** en momentos
distintos, asi que no hay un solo mapa de memoria que desensamblar:

    src/descubrimiento_carga.asm    0xC000-0xD3DF  el cargador
    src/descubrimiento_p1bajo.asm   0x4000-0x63FF  primera parte, el programa
    src/descubrimiento_p1alto.asm   0x8000-0xD2FF  primera parte, los graficos
    src/descubrimiento_p2bajo.asm   0x4000-0x63FF  segunda parte, el programa
    src/descubrimiento_p2alto.asm   0x8000-0xD2FF  segunda parte, los graficos

Cada listado tiene su `.notes` al lado. Lo que come el trazador va por mitades,
porque las dos partes se trazan como dos imagenes de 64 KB distintas:

    src/*.notes              lo entendido: bloques de datos y comentarios
    src/carga.entries        el punto de entrada del cargador, con su razon
    src/p1.entries           los puntos de entrada de la primera parte, siete
    src/p2.entries           los de la segunda parte, cinco
    src/comun.nocode         lo que la cinta no llega a cargar nunca
    src/p1.datos p2.datos    zonas por las que el trazador no debe entrar
    tools/                   el trazador, el generador y las herramientas de dibujo
    docs/                    la web, en castellano y en ingles

## Como se reproduce

La cinta **no** se distribuye aqui. Hay que poner la propia en la raiz como
`descubrimiento.cas` (66.371 bytes, sha256 `ac7b780000c2b92f0cbbd89f9ee36e741beb88a41261920680235e84b1c53077`)
y ejecutar:

    make                # extrae, traza, monta, reensambla, verifica y prueba

Termina con `OK: la cinta entera se reproduce byte a byte`, que es lo que dice
que los cinco listados devuelven la cinta exactamente.

## Algo de lo que aparecio

- **0xD300 no es codigo, es un puntero.** Guarda la direccion del bucle que lee
  un bloque de cinta, y asi la primera parte pide la segunda sin llevar la
  direccion escrita en su codigo. Es tambien la razon de que el fichero `CARGA`
  arranque en 0xD302.
- **La BIOS no lee los dos bloques grandes**: los lee a mano el cargador, byte a
  byte, con TAPION y TAPIN, y reparte cada uno en 0x2400 bytes a 0x4000 y
  0x5300 a 0x8000.
- **La segunda parte transcurre dentro de la carabela** — un corte del barco de
  128 x 52 baldosas, del que se recorta una ventana de 32x24 con scroll en las
  dos direcciones.
- **Lo que compras se ve estibado en la bodega**: un monton por mercancia, con
  tantas piezas como unidades queden.
- **7.564 bytes que no lee nadie** (el 11,5 % de la cinta), porque la cinta
  graba bloques de tamano fijo pase lo que pase. Uno de esos restos es la
  pantalla de carga, todavia puesta en memoria cuando se grabo el bloque.
- **La firma de la casa trae una errata, y esta en la cinta**: OMIKRON
  *Softwarwe*.

La lista entera esta en [Hallazgos](https://antxiko.github.io/Descubrimiento-disassembly/es/HALLAZGOS.html),
y lo que **no** se sabe, en
[Preguntas abiertas](https://antxiko.github.io/Descubrimiento-disassembly/es/PREGUNTAS-ABIERTAS.html).

## Legal

Esto es trabajo de preservacion, estudio y documentacion. El juego y sus
graficos siguen siendo de sus titulares; la imagen de la cinta no se distribuye.
Lee [AVISO-LEGAL.md](AVISO-LEGAL.md) y [LICENSE](LICENSE).
