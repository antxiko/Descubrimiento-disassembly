# El juego

*El Descubrimiento de America* es un juego de dos mitades, y cada una es de un
genero distinto. En la primera se prepara la expedicion por el puerto de Palos;
en la segunda se cruza el Atlantico. Entre las dos hay un trasvase de **seis
bytes**, y nada mas.

Todas las imagenes de esta pagina estan dibujadas desde los bytes de la cinta,
no capturadas del emulador.

## La presentacion

El texto de 0x8200 dice, en la caja de nueve lineas que dibuja el juego:

> ...ea el puerto de / Palos donde se ar- / men los navios con / todo lo
> necesario / durante un ano. / Como enviado Real / y Almirante de la /
> expedicion sera : / CRISTOBAL COLON

Los guiones de corte estan en la cinta: el texto se escribio ya partido a
diecinueve columnas.

## La primera parte: ocho pantallas en Palos

Se recorren ocho escenarios fijos. Siete tienen su propia tabla de nombres, una
detras de otra y separadas exactamente 0x300 bytes:

| # | tabla | que hay |
|---|---|---|
| 0 | 0x82F5 | la calle del puerto, con la taberna, el muelle y el agua |
| 1 | 0x85F5 | un porton claveteado entre dos casas |
| 2 | 0x88F5 | un patio con escalera y toneles, y un ave cruzando |
| 3 | 0x8BF5 | una iglesia: crucifijo, altar y vidriera |
| 4 | 0x8EF5 | la sala del mapamundi, con retrato y mesa |
| 5 | 0x91F5 | el interior de la taberna: barra, banquetas y un cuadro de un navio |
| 6 | 0x94F5 | la cubierta del barco, con las jarcias y los toneles |
| 7 | — | el almacen del muelle |

![La calle del puerto de Palos](../imagenes/p1_fase0.png)

La **septima no tiene tabla propia**: se compone recortando 32 columnas de un
mapa de **64x24** que vive en 0x97F5, y el recorrido lateral es de media
pantalla -el contador de 0xF89D va de 0 a 0x20-. Es la unica pantalla de la
primera parte con scroll.

![El almacen del muelle](../imagenes/p1_fase7.png)

Los once rotulos que se leen por las pantallas estan en 0xC28A: PUERTO DE PALOS,
Ano 1492, Fray Juan Perez, Juan de la Cosa, Cartografo, Martin Alonso Pinzon,
Armador, Piloto, Cocinero, Carpintero y Marinero. Todos se dibujan con la fuente
de la ROM del BASIC (CGTABL, 0x1BBF), copiada baldosa a baldosa a la tabla de
patrones.

## Lo que se compra

En el almacen de la pantalla 7 se compran cinco mercancias -**agua, vino,
comida, madera y tela**-, cada una a costa de una de las dieciseis unidades de
DINERO. La rutina de 0x59FB mira por que tramo del mapa ancho va el muneco y
sube el contador que toca.

Al terminar, un resumen con siete cifras:

![El resumen del final de la primera parte](../imagenes/p1_fin.png)

DINERO es el unico que se ensena **restado de 16**, o sea lo que queda; y
MARINERO sale del marcador de reclutamiento menos dos.

## El trasvase: seis bytes y un balanceo

Seis de esos siete contadores se copian a 0xD6D9-0xD6DE, que esta **por encima
de 0xD300** y por tanto sobrevive a la carga del segundo bloque. El arranque de
la segunda parte los recoge y los lleva a 0xF39A-0xF39F.

Cual es cual **no se puede suponer**: los rotulos son dibujo, no texto. La forma
de medirlo es que el bucle de 0x5D0C pinta las catorce cifras en baldosas
**seguidas** a partir de la 188, y basta buscar esas baldosas en la tabla de
nombres para ver bajo que rotulo cae cada una:

![El resumen con cada contador marcado](../imagenes/p1_fin_marcado.png)

| contador | rotulo | pasa a |
|---|---|---|
| 0xF8B4 | AGUA | 0xD6D9 -> 0xF39A |
| 0xF8B5 | VINO | 0xD6DA -> 0xF39B |
| 0xF8B6 | COMIDA | 0xD6DD -> 0xF39E |
| 0xF8B7 | MADERA | 0xD6DB -> 0xF39C |
| 0xF8B8 | TELA | 0xD6DC -> 0xF39D |
| 0xF8B9 | MARINERO | 0xD6DE -> 0xF39F |
| 0xF8BA | DINERO | no se pasa |

Ni el orden de las direcciones ni el de la pantalla, y el paso por 0xD6D9
**cruza la COMIDA con la MADERA**. Hay un test que fija las posiciones.

Y hay un septimo byte que viaja, 0xD6D8, que no es una cifra sino el balanceo
del muneco: las dos partes lo usan igual.

## La segunda parte: dentro de la carabela

Aqui no hay pantallas. Hay un **corte longitudinal del barco de 128 x 52
baldosas**, y el juego recorta de el una ventana de 32x24 con scroll en las dos
direcciones.

![El interior de la carabela](../imagenes/p2_mapa.png)

![La ventana de 32x24](../imagenes/p2_ventana.png)

La carga comprada no se queda en un numero: la rutina de 0x4F60 la **estiba en
la bodega**, un monton por mercancia y tantas piezas como unidades queden.

![Las baldosas de la carga](../imagenes/p2_carga.png)

## La travesia

Se juega sobre una **carta de 20x20 casillas** (0xC98C-0xCB1B), un byte por
casilla. El valor decide lo que pasa ese dia: 0 mar abierto, 1 y 2 corrientes, y
de 3 en adelante un contratiempo que se busca en la tabla de nueve entradas de
0xC968. Un test comprueba que ninguna de las 400 casillas pasa de 11, que es lo
que garantiza que el indice nunca se sale de la tabla.

![La carta oceanica](../imagenes/p2_carta.png)

Los cinco desastres estan en 0xCBF2, cinco cadenas de 22 caracteres sin
terminador: GRAVE DESMORALIZACION, AGOTADAS PROVISIONES, VIA DE AGUA SIN TAPAR,
FUEGO SIN CONTROLAR y VELA PRINCIPAL RASGADA. Contra el agua se usa la MADERA y
contra el fuego la TELA, que es donde se cierra el circulo con lo que se compro
en la primera mitad.

![Final de la travesia](../imagenes/p2_final.png)
