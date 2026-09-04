# El codigo

15.504 bytes de codigo repartidos en **733 rutinas con nombre**, y ninguna de
ellas por debajo del liston de comentarios. Pero el codigo esta en tres sitios,
no en uno, y los tres son independientes.

| listado | instrucciones | rutinas | comentado |
|---|---|---|---|
| `carga` | 88 | 9 | 26,1 % |
| `p1bajo` | 3.451 | 371 | 27,2 % |
| `p2bajo` | 3.126 | 353 | 26,3 % |
| **total** | **6.665** | **733** | **26,7 %** |

Los dos listados `alto` no aparecen porque no tienen ni una instruccion.

## El cargador: 88 instrucciones que sobreviven a todo

`carga` es el programa mas pequeno y el mas importante. De sus 5.088 bytes solo
**210 son codigo**; el resto son la pantalla de carga y su fuente.

Su trabajo es el bucle de 0xD369: pone el motor en marcha con TAPION, coge la
sincronia, y luego lee **byte a byte con TAPIN**, sin cabecera y sin BIOS de
ficheros, repartiendo lo que llega en 0x4000 y en 0x8000. Al acabar salta al
codigo recien cargado.

Vive en 0xD300-0xD3DF, que es **por encima de donde llega cualquier bloque de
cinta**, y por eso sigue en pie cuando el juego ya esta corriendo. Los dos bytes
de 0xD300 no son codigo sino la direccion de ese bucle, y la primera parte los
usa para volver:

    5CC2  ld hl,(0xD300)
    5CC5  push hl
    5CC6  ret

## Las tres rutinas que suben graficos

Todo lo que se ve pasa por una de estas tres, y cada una consume la cinta a un
ritmo distinto:

| rutina | consume | que hace |
|---|---|---|
| `vuelca_patrones` (0x4497) | BC | sube dibujo, sin tocar el color |
| `vuelca_comprimido` (0x44CB) | BC + BC/8 | sube dibujo y luego **un byte de color por baldosa**, estirado a sus ocho filas con FILVRM |
| `vuelca_con_color` (0x446D) | 2*BC | sube dibujo y la tabla de color completa |

Ese `BC/8` de la del medio es la compresion de color del juego: en vez de ocho
bytes por baldosa, uno. Es tambien lo que permite cerrar los limites de los
datos sin ponerlos a ojo -ver [La cinta](EL-CARTUCHO.md)-.

## La musica va colgada del gancho de teclado, y solo en la primera parte

La primera parte instala un `JP` en H.KEYI (0xFD9F) apuntando a 0x4046: la
musica suena en cada interrupcion de barrido, **antes de que la BIOS lea el
teclado**.

El estado son catorce bytes seguidos, 0xF8CB-0xF8D8, con **tres bytes por
canal** -puntero de partitura y duracion-. Por eso el cursor de 0x4181 avanza de
tres en tres y la misma rutina sirve para los tres canales sin una sola tabla.
Hay dieciseis melodias indexadas en 0xCB95.

La segunda parte **no instala nada**: escribe el PSG directamente desde el bucle
principal, en 0x5213. Comprobado buscando escrituras a 0xFD9A y 0xFD9F en todo
el codigo trazado: no hay ninguna.

## Un marcador dentro de los propios patrones

El arranque de la primera parte hace:

    420A  ld a,(0xC103)
    420D  cp 8
    420F  call nz, voltea_los_patrones

0xC103 **no es una variable**: es un byte de la tabla de patrones, usado como
marca para no voltear dos veces los mismos dibujos. La rutina de 0x561D
invierte el orden de los bits de cada byte entre 0xC102 y 0xC138, que es como el
juego consigue el dibujo espejo sin gastar mas cinta.

El mismo truco esta en los sprites: la rutina de 0x4B1E los voltea **en
memoria** para dibujar al muneco mirando al otro lado. Se ve en la maquina: de
los 21.248 bytes del trozo alto de la primera parte, openMSX solo encuentra 45
pisados, y son exactamente esos sprites (0x9E05-0x9E53) mas una baldosa que
retoca el arranque (0x915B).

## Como se dibuja la pantalla ancha

La pantalla 7 de la primera parte y todo el barco de la segunda salen del mismo
tipo de bucle: un mapa mas ancho que la pantalla, del que se recorta una ventana.

Lo que dice cual es el ancho **no es una constante en ninguna tabla**: es el
paso entre filas del propio bucle. En el mapa del barco, el bucle de 0x4285 suma
**0x80** por fila, y eso es lo que fija las 128 baldosas de ancho. Si estuviera
mal leido, el cotejo de la ventana contra la VRAM del emulador saldria a
cientos de diferencias; sale a **cero** en las 768 baldosas.

## Los textos, con la fuente prestada de la ROM

Hay tres bloques de cadenas, y solo tres:

| donde | que |
|---|---|
| 0x8200 | la presentacion, nueve lineas ya partidas a diecinueve columnas |
| 0xC28A | once rotulos de pantalla |
| 0xCBF2 | cinco desastres de la travesia, de 22 caracteres y sin terminador |

Todos se dibujan con la fuente de la ROM del BASIC (CGTABL, 0x1BBF), copiada
baldosa a baldosa a la tabla de patrones: la cinta no gasta un solo byte en un
alfabeto para el juego.

El unico texto que **no** usa esa fuente es el de la pantalla de carga, que va en
baldosas propias y ni siquiera en ASCII. Eso esta contado en
[Hallazgos](HALLAZGOS.md).
