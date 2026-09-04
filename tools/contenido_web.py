#!/usr/bin/env python3
"""El CONTENIDO de la portada: los hallazgos y los pies de la galeria.

Va aparte de make_web.py a proposito. make_web.py es el generador -la
plantilla, la maquetacion, el HTML- y no cambia de un juego al siguiente; esto
es lo unico que hay que reescribir entero en cada cinta. Teniendolo separado
no hay que ir buscando los textos del juego anterior dentro del generador, que
es justo como se han colado los nombres equivocados otras veces.

Cada hallazgo es (titulo, html) y cada entrada de galeria
(fichero, pie en castellano, pie en ingles).
"""

HALLAZGOS = {
    "es": [
        ('0xD300 no es codigo: es un puntero',
         '<p>El fichero <code>CARGA</code> ocupa de 0xC000 a 0xD3DF, pero su '
         'direccion de ejecucion es <b>0xD302</b>, no 0xD300. La razon esta en '
         'esos dos bytes: valen <code>69 D3</code>, o sea la palabra '
         '<b>0xD369</b>, que es el bucle que lee un bloque de cinta.</p>'
         '<p>La primera parte del juego termina con <code>ld hl,(0xD300) / '
         'push hl / ret</code> en 0x5CC2, y asi vuelve al cargador a pedir la '
         'segunda sin llevar la direccion escrita en su propio codigo. El '
         'cargador <b>sobrevive a los dos programas</b>, porque ningun bloque '
         'de cinta pasa de 0xD2FF.</p>'),
        ('Cinco listados para un juego, porque los dos programas viven en '
         'las mismas direcciones',
         '<p>La cinta trae cuatro ficheros: una linea de BASIC, el BIN '
         '<code>CARGA</code>, y <b>dos bloques sin cabecera</b> de 30.472 y '
         '30.467 bytes. Esos dos no los lee la BIOS: los lee a mano el bucle '
         'de 0xD369 con TAPION y TAPIN, byte a byte, y los reparte en tres '
         'bytes de sincronia, <b>0x2400 bytes a 0x4000</b> y <b>0x5300 bytes a '
         '0x8000</b>.</p>'
         '<p>Las dos mitades del juego ocupan por tanto <b>exactamente las '
         'mismas direcciones</b> en momentos distintos. Por eso el proyecto '
         'son cinco listados y no uno: <code>carga</code>, <code>p1bajo</code>,'
         ' <code>p1alto</code>, <code>p2bajo</code> y <code>p2alto</code>.</p>'),
        ('La segunda parte transcurre dentro de la carabela',
         '<p>Aqui no hay pantallas: hay un <b>corte longitudinal del barco de '
         '128 x 52 baldosas</b> -1024 x 416 pixeles-, con la cubierta, tres '
         'mastiles con sus velas y sus escalas de jarcia, y tres crujias de '
         'camarotes y bodega por debajo.</p>'
         '<p>Los 0x1A00 bytes van de 0x9000 a 0xA9FF, y lo que dice que el '
         'ancho es 128 es el paso de <b>0x80 entre filas</b> del bucle de '
         '0x4285. El juego recorta de ese plano una ventana de 32x24 con '
         'scroll en las dos direcciones.</p>'),
        ('Lo que compras se ve estibado en la bodega',
         '<p>Las cinco mercancias -agua, vino, comida, madera y tela- se '
         'compran en el almacen del muelle gastando una unidad de las '
         'dieciseis de DINERO. Pero el numero no se queda en un contador: la '
         'rutina de <b>0x4F60</b> de la segunda parte <b>estiba la carga en la '
         'bodega</b>, un monton por mercancia y tantas piezas como unidades '
         'queden.</p>'
         '<p>Dibujadas, las baldosas de cada monton son toneles de duelas '
         '(0xBF-0xC4), sacos atados (0xB9-0xBE), tablones apilados '
         '(0xC6-0xC8) y rollos de tela (0xC5, 0xC9 y 0xCA).</p>'),
        ('7.564 bytes que no lee nadie, y uno de ellos es una foto de la '
         'memoria',
         '<p>La cinta graba bloques de <b>tamano fijo</b> -0x2400 y 0x5300 '
         'bytes- pase lo que pase, pero el programa de la primera parte acaba '
         'en 0x5F9F y el de la segunda en 0x5C3F. Detras se grabo lo que '
         'hubiera en memoria. Son <b>7.564 bytes de 66.016 (11,5 %)</b> que '
         'estan identificados y contados, pero que ninguna instruccion toca; '
         '4.534 de ellos son cola de bloque.</p>'
         '<p>Uno de esos restos se puede leer: de 0xCC56 a 0xD2FF, la primera '
         'parte lleva <b>1.706 bytes identicos al fichero <code>CARGA</code> '
         'salvo un byte</b>. Es la pantalla de carga, todavia puesta en '
         'memoria cuando se grabo el bloque.</p>'),
        ('La firma de la casa trae una errata, y esta en la cinta',
         '<p>Descodificada la tabla de nombres de 0xD000, en el margen derecho '
         'de la pantalla de carga se lee en vertical <b>"OMIKRON Softwarwe"</b>'
         ', con dos w. La errata esta en la cinta, no en este desensamblado, y '
         'hay un test que la fija.</p>'
         '<p>Las letras no son ASCII: son indices de baldosa, y van en <b>dos '
         'alfabetos distintos</b> dentro de la misma tabla (0x00-0x19 y '
         '0x20-0x39, dos juegos para las mismas veintiseis letras), mas seis '
         'baldosas (0x3A-0x3F) para las mayusculas grandes de dos baldosas de '
         'alto con las que empiezan "El", "Descubrimiento" y "America".</p>'),
    ],
    "en": [
        ('0xD300 is not code: it is a pointer',
         '<p>The <code>CARGA</code> file runs from 0xC000 to 0xD3DF, but its '
         'execution address is <b>0xD302</b>, not 0xD300. The reason is in '
         'those two bytes: they hold <code>69 D3</code>, the word '
         '<b>0xD369</b>, which is the loop that reads a tape block.</p>'
         '<p>The first half of the game ends with <code>ld hl,(0xD300) / push '
         'hl / ret</code> at 0x5CC2, and that is how it returns to the loader '
         'to ask for the second half without carrying the address in its own '
         'code. The loader <b>survives both programs</b>, because no tape '
         'block reaches past 0xD2FF.</p>'),
        ('Five listings for one game, because both programs live at the same '
         'addresses',
         '<p>The tape holds four files: one line of BASIC, the '
         '<code>CARGA</code> binary, and <b>two headerless blocks</b> of '
         '30,472 and 30,467 bytes. The BIOS never reads those two: the loop at '
         '0xD369 reads them by hand with TAPION and TAPIN, byte by byte, and '
         'splits them into three sync bytes, <b>0x2400 bytes at 0x4000</b> and '
         '<b>0x5300 bytes at 0x8000</b>.</p>'
         '<p>So both halves of the game occupy <b>exactly the same '
         'addresses</b> at different times. That is why this project is five '
         'listings and not one: <code>carga</code>, <code>p1bajo</code>, '
         '<code>p1alto</code>, <code>p2bajo</code> and <code>p2alto</code>.</p>'
         ),
        ('The second half plays out inside the caravel',
         '<p>There are no screens here: there is a <b>longitudinal cutaway of '
         'the ship, 128 x 52 tiles</b> -1024 x 416 pixels- with the deck, '
         'three masts with their sails and rigging ladders, and three runs of '
         'cabins and hold below.</p>'
         '<p>The 0x1A00 bytes run from 0x9000 to 0xA9FF, and what says the '
         'width is 128 is the <b>0x80 step between rows</b> in the loop at '
         '0x4285. The game cuts a 32x24 window out of that plan and scrolls it '
         'both ways.</p>'),
        ('What you buy is drawn stowed in the hold',
         '<p>The five commodities -water, wine, food, timber and cloth- are '
         'bought at the quayside warehouse, each costing one of the sixteen '
         'units of MONEY. But the number does not stay in a counter: the '
         'routine at <b>0x4F60</b> in the second half <b>stows the cargo in '
         'the hold</b>, one pile per commodity and as many pieces as units '
         'remain.</p>'
         '<p>Drawn out, the tiles of each pile are staved barrels '
         '(0xBF-0xC4), tied sacks (0xB9-0xBE), stacked planks (0xC6-0xC8) and '
         'rolls of cloth (0xC5, 0xC9 and 0xCA).</p>'),
        ('7,564 bytes nobody reads, and one stretch of them is a snapshot of '
         'memory',
         '<p>The tape records <b>fixed-size</b> blocks -0x2400 and 0x5300 '
         'bytes- no matter what, but the first half\'s program ends at 0x5F9F '
         'and the second\'s at 0x5C3F. Whatever was in memory got recorded '
         'behind them. That is <b>7,564 bytes out of 66,016 (11.5%)</b> that '
         'are identified and accounted for, but that no instruction ever '
         'touches; 4,534 of them are block tail.</p>'
         '<p>One of those leftovers can be read: from 0xCC56 to 0xD2FF the '
         'first half carries <b>1,706 bytes identical to the <code>CARGA</code>'
         '</b> file but for a single byte. It is the loading screen, still sat '
         'in memory when the block was recorded.</p>'),
        ('The publisher\'s signature carries a typo, and it is on the tape',
         '<p>Decoding the name table at 0xD000, down the right margin of the '
         'loading screen you read <b>"OMIKRON Softwarwe"</b>, with two w\'s. '
         'The typo is on the tape, not in this disassembly, and a test pins '
         'it.</p>'
         '<p>The letters are not ASCII: they are tile indices, and they use '
         '<b>two different alphabets</b> inside the same table (0x00-0x19 and '
         '0x20-0x39, two sets for the same twenty-six letters), plus six tiles '
         '(0x3A-0x3F) for the tall two-tile capitals that start "El", '
         '"Descubrimiento" and "America".</p>'),
    ],
}

GALERIA = [
    ("carga.png",
     "<b>La pantalla de carga</b>, montada desde la tabla de nombres de "
     "0xD000 del fichero <code>CARGA</code>. Es la unica pieza de la cinta que "
     "nombra a la casa, y lo hace con una errata: <b>OMIKRON Softwarwe</b>, en "
     "vertical por el margen derecho",
     "<b>The loading screen</b>, built from the name table at 0xD000 of the "
     "<code>CARGA</code> file. It is the only piece on the tape that names the "
     "publisher, and it does so with a typo: <b>OMIKRON Softwarwe</b>, running "
     "down the right margin"),
    ("p1_fase0.png",
     "<b>Pantalla 0</b>, la calle del puerto de Palos: la taberna con su "
     "rotulo, el ancla, el muelle y el agua. Tabla de nombres en 0x82F5",
     "<b>Screen 0</b>, the street of the port of Palos: the tavern with its "
     "sign, the anchor, the quay and the water. Name table at 0x82F5"),
    ("p1_fase1.png",
     "<b>Pantalla 1</b>: un porton claveteado entre dos casas. Tabla de "
     "nombres en 0x85F5",
     "<b>Screen 1</b>: a studded gate between two houses. Name table at "
     "0x85F5"),
    ("p1_fase2.png",
     "<b>Pantalla 2</b>: un patio con escalera y toneles, con un ave cruzando "
     "por la izquierda. Tabla de nombres en 0x88F5",
     "<b>Screen 2</b>: a courtyard with a staircase and barrels, and a bird "
     "crossing on the left. Name table at 0x88F5"),
    ("p1_fase3.png",
     "<b>Pantalla 3</b>, la iglesia: crucifijo, altar y vidriera. Tabla de "
     "nombres en 0x8BF5",
     "<b>Screen 3</b>, the church: crucifix, altar and stained glass. Name "
     "table at 0x8BF5"),
    ("p1_fase4.png",
     "<b>Pantalla 4</b>, la sala del mapamundi, con el retrato y la mesa. "
     "Tabla de nombres en 0x8EF5",
     "<b>Screen 4</b>, the map room, with the portrait and the table. Name "
     "table at 0x8EF5"),
    ("p1_fase5.png",
     "<b>Pantalla 5</b>, el interior de la taberna: la barra, las banquetas y "
     "un cuadro de un navio. Tabla de nombres en 0x91F5",
     "<b>Screen 5</b>, inside the tavern: the bar, the stools and a painting "
     "of a ship. Name table at 0x91F5"),
    ("p1_fase6.png",
     "<b>Pantalla 6</b>, la cubierta del barco, con las jarcias y los toneles. "
     "Tabla de nombres en 0x94F5",
     "<b>Screen 6</b>, the ship's deck, with the rigging and the barrels. Name "
     "table at 0x94F5"),
    ("p1_fase7.png",
     "<b>Pantalla 7</b>, el almacen del muelle, donde se compra: se leen AGUA, "
     "VINO y COM... Es la unica que <b>no tiene tabla de nombres propia</b>: "
     "se compone recortando 32 columnas de un mapa de 64x24 que vive en 0x97F5",
     "<b>Screen 7</b>, the quayside warehouse, where you buy: AGUA, VINO and "
     "COM... can be read. It is the only one with <b>no name table of its "
     "own</b>: it is cut as 32 columns out of a 64x24 map living at 0x97F5"),
    ("p1_fin.png",
     "<b>El resumen del final de la primera parte</b>, con las siete cifras: "
     "DINERO, COMIDA, AGUA, VINO, MADERA, TELA y MARINERO. Los rotulos son "
     "dibujo, no texto",
     "<b>The summary at the end of the first half</b>, with the seven figures: "
     "money, food, water, wine, timber, cloth and crew. The labels are "
     "artwork, not text"),
    ("p1_fin_marcado.png",
     "La misma pantalla con <b>cada contador de un color</b>. Como los rotulos "
     "son dibujo, cual es cual hay que medirlo: el bucle de 0x5D0C pinta las "
     "catorce cifras en baldosas SEGUIDAS a partir de la 188, y se buscan esas "
     "baldosas en la tabla de nombres de 0xC310. El paso a la segunda mitad "
     "<b>cruza la COMIDA con la MADERA</b>",
     "The same screen with <b>each counter in its own colour</b>. Since the "
     "labels are artwork, which is which has to be measured: the loop at "
     "0x5D0C paints the fourteen digits on CONSECUTIVE tiles from 188 on, and "
     "those tiles are then looked up in the name table at 0xC310. The handover "
     "to the second half <b>crosses food with timber</b>"),
    ("p2_mapa.png",
     "<b>El interior de la carabela entero</b>: 128 x 52 baldosas, 1024 x 416 "
     "pixeles, descomprimido de los 0x1A00 bytes de 0x9000-0xA9FF. Lo que dice "
     "que el ancho es 128 es el paso de 0x80 entre filas del bucle de 0x4285",
     "<b>The whole inside of the caravel</b>: 128 x 52 tiles, 1024 x 416 "
     "pixels, unpacked from the 0x1A00 bytes at 0x9000-0xA9FF. What says the "
     "width is 128 is the 0x80 step between rows in the loop at 0x4285"),
    ("p2_ventana.png",
     "La <b>ventana de 32x24</b> que el juego recorta de ese plano, aqui desde "
     "la columna 50 y la fila 16. Comprobada baldosa a baldosa contra la VRAM "
     "del emulador: 768 baldosas, 0 distintas",
     "The <b>32x24 window</b> the game cuts out of that plan, here from column "
     "50 and row 16. Checked tile by tile against the emulator's VRAM: 768 "
     "tiles, 0 different"),
    ("p2_carta.png",
     "<b>La carta oceanica</b>, con los tres indicadores -DIAS, ESTADO MORAL y "
     "ESTADO FISICO- y la velocidad del viento. La travesia se juega sobre "
     "20x20 casillas de un byte (0xC98C-0xCB1B): 0 es mar abierto, 1 y 2 "
     "corrientes, y de 3 en adelante un contratiempo que se busca en la tabla "
     "de nueve entradas de 0xC968",
     "<b>The ocean chart</b>, with its three gauges -days, morale and physical "
     "state- and the wind speed. The crossing is played on 20x20 one-byte "
     "squares (0xC98C-0xCB1B): 0 is open sea, 1 and 2 are currents, and 3 "
     "upwards is a setback looked up in the nine-entry table at 0xC968"),
    ("p2_carga.png",
     "<b>Las baldosas de la carga</b>, sacadas de la cinta y puestas en fila: "
     "toneles de duelas para el agua y el vino (0xBF-0xC4), sacos atados para "
     "la comida (0xB9-0xBE), tablones apilados (0xC6-0xC8) y rollos de tela "
     "(0xC5, 0xC9 y 0xCA). Con ellas la rutina de 0x4F60 estiba en la bodega "
     "lo que se compro",
     "<b>The cargo tiles</b>, lifted from the tape and laid out in a row: "
     "staved barrels for water and wine (0xBF-0xC4), tied sacks for food "
     "(0xB9-0xBE), stacked planks (0xC6-0xC8) and rolls of cloth (0xC5, 0xC9 "
     "and 0xCA). With these the routine at 0x4F60 stows the purchase in the "
     "hold"),
    ("p2_final.png",
     "<b>FINAL DE LA TRAVESIA</b>: la costa avistada, con el rotulo en un "
     "recuadro sobre el cielo",
     "<b>FINAL DE LA TRAVESIA</b> -end of the crossing-: land sighted, with "
     "the caption boxed over the sky"),
]
