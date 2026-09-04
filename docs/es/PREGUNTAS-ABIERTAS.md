# Preguntas abiertas

Cada byte de la cinta esta asignado y cada rutina tiene nombre, pero eso no
quiere decir que se sepa todo. Lo que queda abierto se dice aqui, con la medida
que hay hecha y la que falta.

## 1. Que son los rellenos de cola

Son tres, **4.534 bytes en total**, y ninguna instruccion los lee:

| listado | rango | bytes |
|---|---|---|
| `p1bajo` | 0x5FF8-0x63FF | 1.032 |
| `p2bajo` | 0x5C7A-0x63FF | 1.926 |
| `p2alto` | 0xCCD8-0xD2FF | 1.576 |

### Lo que si se sabe

**La de la primera parte esta vacia.** Repite `00 FF FF FF FF 00 00 00` desde
0x5FF9 sin una sola excepcion, y la autocorrelacion da el 100 % en todos los
multiplos de 8. No lleva ni un bit de informacion.

**Las dos de la segunda parte no.** Tienen 39 y 13 valores distintos, y una
estructura clara: registros de ocho bytes en los que **cuatro acaban en `F` y
cuatro en `0`**.

### Lo que se ha descartado, y con que medida

**No es una tabla de colores de SCREEN 2**, aunque lo parezca. Dos medidas lo
tumban:

- El nibble bajo es 0 o F en el **100 %** de los bytes; en las tablas de color
  de este mismo juego eso pasa entre el 0 % y el 36,5 % de las veces
  (`colores_comunes` 12,5, `pantalla_1_colores` 0,0, `pantalla_4_colores` 4,4,
  `fuente_barco_colores` 6,3, `pantalla_3_colores` 36,5). La unica tabla de la
  cinta con esta forma es la de la pantalla de carga, que es tinta sobre blanco
  y da el 98,4 %.
- Y sobre todo, **la fase**. Barriendo los ocho desplazamientos posibles, la
  regla de los cuatro y cuatro se cumple al 100 % empezando en 0x5C7A, 0xCCDA y
  0x5FFA, y solo al 50 % en las direcciones 8-alineadas. Los registros caen, en
  las tres colas, en direcciones con **resto 2 al dividir por 8**. Una tabla de
  colores de SCREEN 2 esta alineada a 8 por construccion, base + baldosa*8.

**No es un dibujo**: dibujadas a anchura 32, 40, 48 y 64 solo salen franjas
verticales, que es lo que produce una estructura de ocho sin nada en dos
dimensiones.

**No es copia de nada de la cinta**: buscando ventanas de 24 bytes en los cinco
listados, la cola de `p2bajo` no aparece fuera de si misma.

**No estaba en pantalla**: contra los dos volcados de VRAM de openMSX, 16 KB
cada uno, no hay **una sola coincidencia de 32 bytes**.

**No es la memoria que dejo la primera parte** en esas direcciones: coincide el
27,5 % y el 4,1 % de los bytes, contra un fondo de coincidencia entre los dos
programas del 2,3 %.

### Lo que queda

Que la fase sea **la misma en las tres colas**, viviendo en zonas de memoria sin
relacion entre si, dice que las tres salen del mismo sitio y que no es
casualidad. La pista viva es ese desfase de dos bytes: apunta a registros de
ocho con dos bytes de cabecera delante, o a un buffer que empieza dos bytes
dentro. Que sea exactamente, no se sabe.

## 2. Los sprites que no nombra nadie

De 0xA66D a 0xA6BF de la primera parte hay 0x53 bytes que **siguen siendo dibujo
de sprite** -dos bloques mas de la serie de 0x30 que usa la rutina de 0x59FB, el
segundo cortado a mitad-, pero que no nombra ninguna instruccion. De 0xA6C0 a
0xAAFC son 1.085 ceros seguidos, sin una sola excepcion.

Puede ser una animacion que se quito, o simplemente sitio reservado. No hay
forma de decidirlo desde el binario.

## 3. No se ha jugado una partida completa

El juego se ha cargado y arrancado en openMSX, y se ha llegado a la segunda
parte forzando el salto a (0xD300), pero **no se ha jugado de principio a fin**.

Lo que eso significa: los nombres de las pantallas salen de mirar los dibujos, y
las mecanicas -que hace cada objeto, como se avanza de pantalla, que cuenta cada
contratiempo- salen de leer el codigo. Una partida de verdad seguramente
corregiria alguna.

## 4. Quien lo programo

En las cinco piezas de la cinta **no hay ni un credito ni unas iniciales** en
ASCII. Los unicos textos son la presentacion, once rotulos de pantalla y cinco
mensajes de desastre. El unico nombre que aparece es el de la casa, y va
dibujado en baldosas, no escrito: **OMIKRON Softwarwe**, con la errata.

Si alguien sabe quien firmo este juego, interesa.
