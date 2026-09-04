# En el emulador

Leer el binario no basta. Este juego se ha **cargado de verdad** en openMSX, y
la RAM y la VRAM con el juego en marcha se han comparado byte a byte con lo que
dicen los listados.

## Como se hace

    make emulador

`tools/omsx_carga.tcl` y `tools/omsx_parte2.tcl` cargan la cinta en un **Philips
VG-8020**, que es un MSX1 con ROM real. La maquina real hace falta: el cargador
llama a TAPION y TAPIN de la BIOS, asi que sin ROM no hay carga. Los guiones
dejan en `work/omsx` los volcados de RAM y VRAM, y `tools/coteja.py` los compara
con los listados.

Tarda unos minutos: son 36 y 66 KB de cinta a 1200 baudios, aunque emulados a
toda velocidad.

## Que sale

    OK   0x4000-0x63FF = trozo bajo del bloque    9216 bytes, 0 distintos
    OK   0x8000-0xD2FF = trozo alto (45 bytes que el juego pisa)  21248 bytes
    OK   0xD300-0xD3DF = el cargador (2 bytes de trabajo)    224 bytes
    OK   y los pisados son los que se esperan   45 direcciones

    OK   tabla de nombres, sin la franja del oleaje    704 bytes, 0 distintos
    OK   patrones de las baldosas que se ven    0 distintos
    OK   colores de las baldosas que se ven     0 distintos

    OK   0x4000-0x63FF = trozo bajo del bloque    9216 bytes, 0 distintos
    OK   0x8000-0xD2FF: lo pisado cae en las dos zonas de trabajo 743 bytes
    OK   patrones de la fuente del barco, los tres tercios  6144 bytes, 0 distintos
    OK   la ventana del mapa de 128x52    768 baldosas, 0 distintas

    OK: la maquina dice lo mismo que el desensamblado

## Lo que cada linea demuestra

**El reparto de la cinta sale a cero diferencias** en 0x4000-0x63FF, en las dos
partes. O sea que el troceado del bloque sin cabecera -tres bytes de sincronia,
0x2400 abajo, 0x5300 arriba- es exactamente lo que hace la maquina.

De los 21.248 bytes del trozo alto de la primera parte, la maquina solo pisa
**45**, y son exactamente los que el listado dice que se pisan: 0x915B, una
baldosa que retoca el arranque, y 0x9E05-0x9E53, los sprites que la rutina de
0x4B1E voltea en memoria para dibujar al muneco mirando al otro lado.

En la segunda parte los **743 bytes pisados caen todos** en las dos zonas de
trabajo declaradas: la ficha del barco (0xB000) y la copia de la pantalla
(0xB058-0xB357).

La **pantalla 0 montada a mano** desde la cinta, repitiendo las tres rutinas de
volcado del juego, coincide byte a byte con la VRAM real en todas las baldosas
que se ven. Eso es lo que cierra que las tres rutinas de volcado -y con ellas
los limites de los 103 bloques de datos- estan bien leidas.

Y la **ventana de 32x24 del mapa del barco coincide en las 768 baldosas** con el
recorte del mapa de 128x52 por la columna 50 y la fila 16, que son los dos
primeros bytes de 0xCBC6. Si el ancho de 128 estuviera mal, esto saldria a
cientos de diferencias.

## Las diferencias que aparecen y no son error

Estan enumeradas una a una dentro del propio `coteja.py`, no escondidas:

- **el oleaje de las filas 18 y 19**, que se anima y por tanto no coincide con
  ninguna foto fija;
- **las baldosas 199 en adelante del tercer tercio**, que son la franja de
  texto: se pinta con la fuente de la ROM del BASIC, que no viene en la cinta;
- **los sprites**, que el juego voltea en memoria segun hacia donde mira el
  muneco.

## Como llegar a la segunda parte

La segunda mitad no se alcanza sin jugar la primera entera. Para volcarla,
`omsx_parte2.tcl` fuerza el salto que el propio juego hace al terminar:

    ld hl,(0xD300) / push hl / ret

que es lo que devuelve el control al cargador para que pida el bloque siguiente.

## Lo que esto NO demuestra

Que se haya jugado una partida completa. **No se ha jugado.** Los nombres de las
pantallas salen de mirar los dibujos, y las mecanicas -que hace cada objeto,
como se avanza de pantalla, que cuenta cada contratiempo- salen de leer el
codigo. Una partida de verdad seguramente corregiria alguna. Esta dicho tambien
en [Preguntas abiertas](PREGUNTAS-ABIERTAS.md).
