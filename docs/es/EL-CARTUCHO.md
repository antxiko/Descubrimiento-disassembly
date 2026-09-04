# La cinta

66.371 bytes, sha256 `ac7b7800...`. Dentro no hay un programa: hay cuatro
ficheros, y dos de ellos son programas enteros que ocupan las mismas
direcciones.

## Los cuatro ficheros

`tools/cas_parse.py` trocea el `.cas` por el centinela de ocho bytes y encuentra
esto:

| # | tipo | nombre | contenido |
|---|---|---|---|
| 00 | ASCII | `DSCRMT` | 256 bytes: una linea de BASIC |
| 02 | BIN | `CARGA ` | 5.088 bytes, 0xC000-0xD3DF, arranca en 0xD302 |
| 04 | sin cabecera | — | 30.472 bytes: la PRIMERA parte |
| 05 | sin cabecera | — | 30.467 bytes: la SEGUNDA parte |

El fichero ASCII es literalmente una linea:

    1 CLEAR 0,57107!:POKE 65535!,168:BLOAD "CAS:",R

`CLEAR 0,57107` deja HIMEM en 0xDF13, y el `POKE 65535,168` escribe 0xA8 en el
registro de subslot de la pagina 3, cosa que solo tiene efecto en maquinas con
el slot expandido.

## Los dos bloques grandes no los lee la BIOS

Los ficheros 04 y 05 **no tienen cabecera**, asi que `BLOAD` no sabria que hacer
con ellos. Los lee a mano el bucle de 0xD369 del cargador, con TAPION y TAPIN,
byte a byte, y los reparte en tres trozos:

- tres bytes de sincronia, `03 02 01`;
- **0x2400 bytes (9.216) a 0x4000-0x63FF**: el programa;
- **0x5300 bytes (21.248) a 0x8000-0xD2FF**: graficos, pantallas y tablas.

3 + 9.216 + 21.248 = **30.467**, que es exactamente el bloque 05. El 04 mide
cinco bytes mas, y son relleno de alineacion del `.cas`, ceros, comprobado.

## El mapa de memoria, que son tres

    0x0000-0x3FFF   ROM del BASIC (de ella se saca la fuente, CGTABL 0x1BBF)
    0x4000-0x63FF   el programa de la parte que este cargada
    0x6400-0x7FFF   sin usar por la cinta
    0x8000-0xD2FF   los graficos de la parte que este cargada
    0xD300-0xD3DF   el cargador, que sobrevive a las dos partes
    0xD3E0-0xFFFF   variables del juego y del sistema

Que **ningun bloque de cinta pase de 0xD2FF** es lo que hace posible todo el
montaje: el cargador se queda vivo en 0xD300-0xD3DF de principio a fin, y por
encima de el hay sitio para los seis bytes que las dos mitades se pasan.

Como el programa se carga en 0x4000, hace falta una maquina con **RAM en la
pagina 1**, es decir 64 KB.

## Los cinco listados

De ese reparto salen los cinco listados del proyecto:

| listado | org | bytes | codigo | datos |
|---|---|---|---|---|
| `carga` | 0xC000 | 5.088 | 210 | 4.878 |
| `p1bajo` | 0x4000 | 9.216 | 8.079 | 1.137 |
| `p1alto` | 0x8000 | 21.248 | 0 | 21.248 |
| `p2bajo` | 0x4000 | 9.216 | 7.215 | 2.001 |
| `p2alto` | 0x8000 | 21.248 | 0 | 21.248 |
| **total** | | **66.016** | **15.504** | **50.512** |

Tres cuartas partes de la cinta son datos. Los dos listados `alto` no tienen ni
una instruccion.

## Donde caen los limites de los datos

Los 103 rangos de datos declarados **no estan puestos a ojo**. En la primera
parte salen de las tres rutinas de volcado del propio juego, que dicen cuantos
bytes de cinta consume cada bloque:

| rutina | consume |
|---|---|
| `vuelca_patrones` (0x4497) | BC bytes |
| `vuelca_comprimido` (0x44CB) | BC de dibujo + BC/8 de color, un byte por baldosa estirado a sus ocho filas con FILVRM |
| `vuelca_con_color` (0x446D) | 2*BC |

Encadenando esas cuentas, el final de cada bloque cae **exactamente** en el
principio del siguiente, desde 0xAB60 hasta 0xC012, sin un solo hueco. Hay un
test que lo comprueba entero.

## Lo que sobra al final de cada bloque

La cinta graba 0x2400 y 0x5300 bytes **pase lo que pase**, pero el programa de
la primera parte acaba en 0x5F9F y el de la segunda en 0x5C3F. Detras se grabo
lo que hubiera en memoria.

En total son **7.564 bytes de 66.016 (11,5 %)** que estan identificados y
contados pero que ninguna instruccion lee. `make sin_leer` los cuenta desde las
propias notas:

| listado | zona | rango | bytes |
|---|---|---|---|
| `carga` | resto de montaje | D3D8-D3DF | 8 |
| `p1bajo` | restos de montaje | 5F9F-5FF7 | 89 |
| `p1bajo` | relleno de bloque | 5FF8-63FF | 1.032 |
| `p1alto` | hueco de sprites | A66D-AAFC | 1.168 |
| `p1alto` | cola de colores de la pantalla de carga | CC56-CFFF | 938 |
| `p1alto` | copia de la pantalla de carga | D000-D2FF | 768 |
| `p2bajo` | restos de montaje | 5C3F-5C79 | 59 |
| `p2bajo` | relleno de bloque | 5C7A-63FF | 1.926 |
| `p2alto` | relleno de bloque | CCD8-D2FF | 1.576 |
| | | **TOTAL** | **7.564** |

Los tres "restos de montaje" -uno por programa, cargador incluido- son una
**copia truncada del propio codigo**, siempre cortada a media instruccion:

| programa | restos | copia de |
|---|---|---|
| `carga` | 0xD3D8-0xD3DF | 0xD358-0xD35F |
| primera parte | 0x5F9F-0x5FF7 | 0x5F1F-0x5F77, 0x80 mas arriba |
| segunda parte | 0x5C42-0x5C79 | 0x5BC2-0x5BF9 |

Las tres se han comprobado byte a byte. No las ejecuta nadie, y parecen un
desliz de la herramienta con la que se montaron los bloques.

Lo que hay en los rellenos, y lo que no se sabe de ellos, esta en
[Preguntas abiertas](PREGUNTAS-ABIERTAS.md).
